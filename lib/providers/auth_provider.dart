import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import 'dart:developer';
import '../core/di/service_locator.dart';
import '../data/models/dog_profile.dart';
import '../models/app_session_state.dart';
import '../config/app_routes.dart';

enum AuthErrorType {
  network,
  invalidOtp,
  userCancelled,
  invalidCredentials,
  emailInUse,
  unknown
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  User? _user;
  UserModel? _userModel;
  bool _isLoading = false; // UI-only loading (buttons/spinners)
  bool _isInit = false;    // True only after auth listener fully resolves
  bool _isProfileComplete = false;
  bool _hasCompletedOnboarding = false;
  bool _hasCameraPermission = false;
  bool _hasSeenPermissions = false;
  String? _errorMessage;
  String? _verificationId;
  AuthErrorType? _errorType;
  int _guestScanCount = 0;
  bool _guestConversionDismissed = false;

  User? get user => _user;
  String? get userId => _user?.uid;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  bool get isInit => _isInit;

  // Router gate: ONLY true once auth listener finishes ALL async checks
  bool get isAppReady => _isInit;

  bool get isProfileComplete => _isProfileComplete;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get hasCameraPermission => _hasCameraPermission;
  bool get hasSeenPermissions => _hasSeenPermissions;
  String? get errorMessage => _errorMessage;
  AuthErrorType? get errorType => _errorType;
  int get guestScanCount => _guestScanCount;
  bool get guestConversionDismissed => _guestConversionDismissed;

  bool get isAuthenticated => _user != null || (!AppRoutes.isProd && _debugBypass);
  bool _debugBypass = false;

  void enableDebugBypass() {
    if (!AppRoutes.isProd) {
      _debugBypass = true;
      notifyListeners();
    }
  }
  bool get isGuest => (_user?.isAnonymous ?? false) || (!AppRoutes.isProd && _debugBypass);
  bool get hasVerificationId => _verificationId != null;

  /// Immutable snapshot of session state for GoRouter redirect.
  /// This is the SINGLE source of truth the router reads.
  AppSessionState get sessionState => AppSessionState(
        isReady: _isInit,
        isAuthenticated: isAuthenticated,
        isGuest: isGuest,
        hasCompletedOnboarding: _hasCompletedOnboarding,
        isProfileComplete: _isProfileComplete,
      );

  AuthProvider() {
    _initAuthListener();
  }

  void _clearError() {
    _errorMessage = null;
    _errorType = null;
    notifyListeners();
  }

  Future<void> checkPermissions() async {
    _hasCameraPermission = await Permission.camera.isGranted;
    final prefs = await SharedPreferences.getInstance();
    _hasSeenPermissions = prefs.getBool('hasSeenPermissions') ?? false;
    _hasCompletedOnboarding = prefs.getBool('hasCompletedOnboarding') ?? false;
    notifyListeners();
  }

  Future<void> setSeenPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenPermissions', true);
    _hasSeenPermissions = true;
    _hasCameraPermission = await Permission.camera.isGranted;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasCompletedOnboarding', true);
    _hasCompletedOnboarding = true;
    notifyListeners();
  }

  void markProfileAsComplete() {
    _isProfileComplete = true;
    notifyListeners();
  }

  void setError(String message, [AuthErrorType type = AuthErrorType.unknown]) {
    _errorMessage = message;
    _errorType = type;
    notifyListeners();
  }

  /// AUTH LISTENER — Single source of truth for all router state.
  /// The router will NOT evaluate until this method calls notifyListeners()
  /// at the very end with _isInit = true.
  void _initAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      debugPrint("═══ AUTH LISTENER TRIGGERED ═══");

      // Reset router gate on every auth state change
      _isInit = false;
      _user = user;
      _isProfileComplete = false;

      // Load persisted prefs
      final prefs = await SharedPreferences.getInstance();
      _hasSeenPermissions = prefs.getBool('hasSeenPermissions') ?? false;
      _hasCompletedOnboarding = prefs.getBool('hasCompletedOnboarding') ?? false;
      _hasCameraPermission = await Permission.camera.isGranted;
      _guestScanCount = prefs.getInt('guestScanCount') ?? 0;
      _guestConversionDismissed = prefs.getBool('guestConversionDismissed') ?? false;

      if (user != null) {
        // Fetch Firestore user model (non-blocking if it fails)
        try {
          _userModel = await _firestoreService.getUser(user.uid);
          debugPrint("✅ getUser COMPLETED");
        } catch (e) {
          debugPrint("⚠️ getUser ERROR: $e");
          _userModel = null;
        }

        // Check profile — local Isar first for speed, fallback to Firestore
        try {
          final isarInstance = isar;
          final localProfile = await isarInstance.dogProfiles.getByUserId(user.uid);
          if (localProfile != null) {
            _isProfileComplete = true;
            debugPrint("✅ Local Isar profile found → profile complete");
          } else {
            _isProfileComplete = await _firestoreService.hasAnyDogs(user.uid);
            debugPrint("✅ Firestore hasAnyDogs → $_isProfileComplete");
          }
        } catch (e) {
          debugPrint("⚠️ Profile check ERROR: $e");
          _isProfileComplete = false;
        }
      } else {
        _userModel = null;
        _isProfileComplete = false;
      }

      // Mark fully initialized — router will now evaluate
      _isInit = true;

      debugPrint(
        "ROUTER STATE → "
        "ready:$isAppReady | "
        "auth:$isAuthenticated | "
        "guest:$isGuest | "
        "onboarding:$_hasCompletedOnboarding | "
        "profile:$_isProfileComplete | "
        "perm:$_hasSeenPermissions"
      );

      notifyListeners();
    });
  }

  Future<void> reloadProfileStatus() async {
    if (_user != null) {
      _isProfileComplete = await _firestoreService.hasAnyDogs(_user!.uid);
      notifyListeners();
    }
  }

  Future<String?> getToken() async {
    if (_user == null) return null;
    try {
      return await _user!.getIdToken();
    } catch (e) {
      debugPrint("⚠️ getIdToken() failed: $e");
      return null;
    }
  }

  // ─── AUTH ACTIONS ────────────────────────────────────────────────────────
  // NOTE: These methods ONLY set UI loading state (for button spinners).
  // They do NOT set _isInit or call notifyListeners() with router state.
  // The auth listener above is the ONLY place that drives router navigation.

  Future<void> signUp(String email, String password, String name) async {
    _clearError();
    _setUiLoading(true);
    try {
      final response = await _authService.signUp(email: email, password: password);
      if (response.user != null) {
        final user = response.user!;
        await user.updateDisplayName(name);
        final newUser = UserModel(id: user.uid, email: email, name: name);
        await _firestoreService.createUser(newUser);
      }
    } on FirebaseAuthException catch (e) {
      _handleFirebaseError(e);
    } catch (e) {
      setError('😕 Something went wrong. Please try again.');
    } finally {
      _setUiLoading(false);
    }
  }

  Future<void> login(String email, String password) async {
    _clearError();
    _setUiLoading(true);
    try {
      await _authService.signIn(email: email, password: password);
      // Auth listener will fire → update _user → router navigates
    } on FirebaseAuthException catch (e) {
      _handleFirebaseError(e);
    } catch (e) {
      setError('😕 Something went wrong. Please try again.');
    } finally {
      _setUiLoading(false);
    }
  }

  Future<void> signInWithGoogle() async {
    debugPrint("GOOGLE SIGN-IN START");
    _clearError();
    _setUiLoading(true);
    try {
      final response = await _authService.signInWithGoogle();
      if (response == null) {
        setError('Google sign in was cancelled.', AuthErrorType.userCancelled);
        return;
      }
      debugPrint("GOOGLE SIGN-IN SUCCESS → Firebase user received");
      if (response.user != null) {
        final user = response.user!;
        final newUser = UserModel(
          id: user.uid,
          email: user.email ?? "",
          name: user.displayName ?? "User",
        );
        await _firestoreService.createUser(newUser);
      }
      // Auth listener will fire → drive navigation
    } on FirebaseAuthException catch (e) {
      _handleFirebaseError(e);
    } catch (e) {
      if (e.toString().contains('cancelled')) {
        setError('Google sign in was cancelled.', AuthErrorType.userCancelled);
      } else {
        log("Google Sign In Error: $e");
        setError('😕 Couldn\'t connect to Google. Try again later.');
      }
    } finally {
      _setUiLoading(false);
    }
  }

  Future<void> sendOtp(String phoneNumber) async {
    _clearError();
    _setUiLoading(true);
    _verificationId = null;
    notifyListeners();
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          _setUiLoading(false);
        },
        verificationFailed: (FirebaseAuthException e) {
          _setUiLoading(false);
          _handleFirebaseError(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _setUiLoading(false);
          notifyListeners();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          notifyListeners();
        },
      );
    } catch (e) {
      _setUiLoading(false);
      setError('😕 Failed to send OTP. Please check your number.');
    }
  }

  Future<void> verifyOtp(String otp) async {
    if (_verificationId == null) {
      setError('Session expired. Please request a new OTP.', AuthErrorType.invalidOtp);
      return;
    }
    _clearError();
    _setUiLoading(true);
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      final response = await _authService.signInWithCredential(credential);
      if (response.user != null) {
        final user = response.user!;
        final newUser = UserModel(
          id: user.uid,
          email: user.phoneNumber ?? "",
          name: "Phone User",
        );
        await _firestoreService.createUser(newUser);
      }
    } on FirebaseAuthException catch (e) {
      _handleFirebaseError(e);
    } catch (e) {
      setError('😕 Invalid OTP. Please try again.', AuthErrorType.invalidOtp);
    } finally {
      _setUiLoading(false);
    }
  }

  Future<void> continueAsGuest() async {
    _clearError();
    _setUiLoading(true);
    try {
      await _authService.continueAsGuest();
      // Auth listener will fire → drive navigation
    } catch (e) {
      debugPrint("Guest Mode Error: $e");
      setError('🐾 Couldn\'t start guest mode. Try again!');
    } finally {
      _setUiLoading(false);
    }
  }

  Future<void> incrementGuestScanCount() async {
    if (!isGuest) return;
    _guestScanCount++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('guestScanCount', _guestScanCount);
    notifyListeners();
  }

  Future<void> dismissGuestConversion() async {
    _guestConversionDismissed = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('guestConversionDismissed', true);
    notifyListeners();
  }

  Future<void> logout() async {
    _setUiLoading(true);
    try {
      await _authService.signOut();
    } finally {
      _setUiLoading(false);
    }
  }

  // UI-only loading — does NOT trigger router re-evaluation
  void _setUiLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }

  void _handleFirebaseError(FirebaseAuthException e) {
    final code = e.code.toLowerCase();
    debugPrint("Firebase Auth Error Code: $code, Message: ${e.message}");
    switch (code) {
      case 'user-not-found':
      case 'invalid-credential':
      case 'wrong-password':
        setError('🔐 Invalid credentials. Please try again.', AuthErrorType.invalidCredentials);
        break;
      case 'invalid-verification-code':
        setError('❌ Invalid or expired OTP.', AuthErrorType.invalidOtp);
        break;
      case 'email-already-in-use':
        setError('📧 That email is already taken. Try signing in instead!', AuthErrorType.emailInUse);
        break;
      case 'invalid-email':
      case 'invalid-phone-number':
        setError('Hmm, that doesn\'t look right.');
        break;
      case 'weak-password':
        setError('🔐 That password is too weak. Try making it stronger!');
        break;
      case 'too-many-requests':
        setError('⏳ Too many attempts. Please wait a moment.', AuthErrorType.network);
        break;
      case 'network-request-failed':
        setError('📡 No internet connection. Check your WiFi.', AuthErrorType.network);
        break;
      default:
        setError('😕 Something went wrong. Please try again.');
    }
  }
}
