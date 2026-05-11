import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:furspeak_ai/config/app_routes.dart';
import 'package:furspeak_ai/config/app_theme.dart';
import 'package:furspeak_ai/config/app_typography.dart';
import 'package:furspeak_ai/config/app_spacing.dart';
import 'package:furspeak_ai/config/lottie_registry.dart';
import 'package:furspeak_ai/theme/app_animations.dart';
import 'package:furspeak_ai/widgets/auth_button.dart';
import 'package:furspeak_ai/providers/auth_provider.dart';
import 'package:furspeak_ai/utils/auth_error_mapper.dart';

/// Welcome / Main entry screen for authentication (V2 Gold Standard)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  void _showFriendlySnackBar(String message, {IconData? icon}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                    fontFamily: 'Inter', fontSize: 14, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2C2C2C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isLoading) return;
    
    FurHaptics.impact();

    await authProvider.signInWithGoogle();
    
    if (mounted) {
      if (authProvider.errorType != null) {
        final errorMsg = AuthErrorMapper.getErrorMessage(authProvider.errorType!);
        if (errorMsg.isNotEmpty) {
          _showFriendlySnackBar(errorMsg, icon: Icons.error_outline);
        }
      } else if (authProvider.errorMessage != null) {
        _showFriendlySnackBar(authProvider.errorMessage!, icon: Icons.error_outline);
      }
    }
  }

  Future<void> _continueAsGuest() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isLoading) return;

    FurHaptics.tap();

    await authProvider.continueAsGuest();
    
    if (mounted) {
      if (authProvider.errorType != null) {
        final errorMsg = AuthErrorMapper.getErrorMessage(authProvider.errorType!);
        if (errorMsg.isNotEmpty) {
          _showFriendlySnackBar(errorMsg, icon: Icons.error_outline);
        }
      } else if (authProvider.errorMessage != null) {
        _showFriendlySnackBar(authProvider.errorMessage!, icon: Icons.error_outline);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    return PopScope(
      canPop: !isLoading,
      child: Scaffold(
        backgroundColor: AppTheme.bgColor,
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.warmGradient,
          ),
          child: SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      const SizedBox(height: 48),
                      Text(
                        'FurSpeak AI 🐾',
                        style: AppTypography.h1.copyWith(
                          fontSize: 40,
                          color: AppTheme.primaryColor,
                          letterSpacing: -1.0,
                        ),
                      ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                      const SizedBox(height: 8),
                      Text(
                        'Understand your dog like never before',
                        style: AppTheme.bodyStyle.copyWith(
                          color: AppTheme.textLightColor,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      )
                          .animate()
                          .fadeIn(duration: 600.ms, delay: 200.ms),
                      const SizedBox(height: 48),
                      // Dog Illustration
                      Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(48),
                          boxShadow: AppTheme.softShadow,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: RepaintBoundary(
                            child: Lottie.asset(
                              LottieRegistry.get('splash'),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.pets, size: 80, color: AppTheme.primaryColor),
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 800.ms, delay: 200.ms)
                          .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
                      const SizedBox(height: 48),

                      // ==== AUTH BUTTONS ====
                      StaggeredEntrance(
                        initialDelay: 400.ms,
                        children: [
                          // 1. Continue with Google
                          AuthButton(
                            label: 'Continue with Google',
                            color: Colors.white,
                            textColor: AppTheme.textColor,
                            onPressed: isLoading ? null : _signInWithGoogle,
                            iconWidget: _googleIcon(),
                          ),
                          const SizedBox(height: 12),
                          // 2. Continue with Phone
                          AuthButton(
                            label: 'Continue with Phone',
                            icon: Icons.phone_rounded,
                            color: AppTheme.successColor,
                            textColor: Colors.white,
                            onPressed: isLoading
                                ? null
                                : () {
                                    FurHaptics.tap();
                                    context.push(AppRoutes.phoneLogin);
                                  },
                          ),
                          const SizedBox(height: 12),
                          // 3. Continue as Guest (Value-driven label)
                          AuthButton(
                            label: 'Analyze your pet 📸',
                            icon: Icons.camera_alt_rounded,
                            color: AppTheme.accentColor,
                            textColor: Colors.white,
                            onPressed: isLoading ? null : _continueAsGuest,
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      
                      // Terms & Privacy Disclaimer (Play Store Requirement)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'By continuing, you agree to our Terms of Service\nand Privacy Policy',
                          textAlign: TextAlign.center,
                          style: AppTheme.captionStyle.copyWith(
                            fontSize: 12,
                            color: AppTheme.textLightColor.withOpacity(0.6),
                            height: 1.5,
                          ),
                        ).animate().fadeIn(delay: 800.ms),
                      ),
                      const SizedBox(height: 32),
                      // Divider
                      Row(
                        children: [
                          Expanded(
                              child: Divider(
                                  color: AppTheme.primaryColor.withOpacity(0.1), thickness: 1.5)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('or explore more',
                                style: AppTheme.captionStyle
                                    .copyWith(fontSize: 14, fontWeight: FontWeight.w500)),
                          ),
                          Expanded(
                              child: Divider(
                                  color: AppTheme.primaryColor.withOpacity(0.1), thickness: 1.5)),
                        ],
                      ).animate().fadeIn(delay: 800.ms),
                      const SizedBox(height: 20),
                      // 4. Sign in with Email (text link)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    FurHaptics.tap();
                                    context.push(AppRoutes.emailLogin);
                                  },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: Text(
                              'Sign in with Email',
                              style: AppTypography.body1.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 900.ms),
                      const SizedBox(height: 4),
                      // Don't have an account?
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Don't have an account?",
                              style: AppTheme.captionStyle.copyWith(fontSize: 14)),
                          TextButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    FurHaptics.tap();
                                    context.goSignUp();
                                  },
                            child: Text(
                              'Sign Up',
                              style: AppTypography.body1.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 1000.ms),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                // Loading overlay
                if (isLoading)
                  Positioned.fill(
                    child: PetMoodGlass(
                      opacity: 0.8,
                      borderRadius: BorderRadius.zero,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppTheme.borderRadiusExtraLarge,
                            boxShadow: AppTheme.softShadow,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              RepaintBoundary(
                                child: Lottie.asset(
                                  LottieRegistry.get('loading'),
                                  width: 90,
                                  height: 90,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const CircularProgressIndicator(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Signing you in... 🐶',
                                style: AppTypography.h3.copyWith(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(duration: 300.ms),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _googleIcon() {
    try {
      return Image.asset('assets/images/google_logo.png', height: 22);
    } catch (_) {
      return const Icon(Icons.g_mobiledata_rounded, size: 26);
    }
  }
}
