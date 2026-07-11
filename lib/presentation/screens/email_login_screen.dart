import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:furspeak_ai/config/app_routes.dart';
import 'package:furspeak_ai/config/app_theme.dart';
import 'package:furspeak_ai/config/app_typography.dart';
import 'package:furspeak_ai/config/lottie_registry.dart';
import 'package:furspeak_ai/theme/app_animations.dart';
import 'package:furspeak_ai/widgets/auth_button.dart';
import 'package:furspeak_ai/providers/auth_provider.dart';
import 'package:furspeak_ai/utils/auth_error_mapper.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showFriendlySnackBar(String message, {Color? color}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(fontFamily: 'Inter', color: Colors.white)),
        backgroundColor: color ?? const Color(0xFF2C2C2C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      FurHaptics.warning();
      return;
    }
    
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isLoading) return;

    FurHaptics.impact();

    await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
    
    if (mounted) {
      if (authProvider.errorType != null) {
        final errorMsg = AuthErrorMapper.getErrorMessage(authProvider.errorType!);
        if (errorMsg.isNotEmpty) {
          _showFriendlySnackBar(errorMsg, color: AppTheme.errorColor);
        }
      } else if (authProvider.errorMessage != null) {
        _showFriendlySnackBar(authProvider.errorMessage!, color: AppTheme.errorColor);
      }
    }
  }

  Future<void> _resetPassword() async {
    FurHaptics.tap();
    _showFriendlySnackBar('📧 Password reset link sent if account exists!');
  }

  @override
  Widget build(BuildContext context) {
    return Selector<AuthProvider, bool>(
      selector: (_, provider) => provider.isLoading,
      builder: (context, isLoading, child) {
        return PopScope(
          canPop: !isLoading,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            // Optionally show a "Please wait" toast/snack if blocked
          },
          child: child!,
        );
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: AppTheme.bgColor,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Selector<AuthProvider, bool>(
              selector: (_, provider) => provider.isLoading,
              builder: (context, isLoading, child) {
                return IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textColor),
                  onPressed: isLoading ? null : () => Navigator.of(context).maybePop(),
                );
              },
            ),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.warmGradient,
          ),
          child: SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 56),
                        // Premium Header with Lottie
                        Center(
                          child: Column(
                            children: [
                              RepaintBoundary(
                                child: Lottie.asset(
                                  LottieRegistry.get('dog_happy'),
                                  width: 140,
                                  height: 140,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.pets, size: 60, color: AppTheme.primaryColor),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Welcome Back 👋',
                                style: AppTypography.h1.copyWith(
                                  fontSize: 32,
                                  color: AppTheme.primaryColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'Sign in to your account to see your pet\'s progress.',
                                  style: AppTypography.body1.copyWith(
                                    color: AppTheme.textLightColor,
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),
                        
                        const SizedBox(height: 40),
                        
                        // Staggered Content
                        StaggeredEntrance(
                          initialDelay: 200.ms,
                          children: [
                            // Email
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: AppTypography.body1,
                              decoration: AppTheme.inputDecoration(
                                label: 'Email',
                                prefixIcon: Icons.email_rounded,
                              ).copyWith(
                                fillColor: AppTheme.surfaceActive,
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: AppTheme.borderRadiusMedium,
                                  borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: AppTheme.borderRadiusMedium,
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!value.contains('@') || !value.contains('.')) {
                                  return 'Hmm, that doesn\'t look like a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            // Password
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: AppTypography.body1,
                              decoration: AppTheme.inputDecoration(
                                label: 'Password',
                                prefixIcon: Icons.lock_rounded,
                              ).copyWith(
                                fillColor: AppTheme.surfaceActive,
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: AppTheme.borderRadiusMedium,
                                  borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: AppTheme.borderRadiusMedium,
                                  borderSide: BorderSide.none,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_rounded
                                        : Icons.visibility_off_rounded,
                                    color: AppTheme.textLightColor,
                                  ),
                                  onPressed: () {
                                    FurHaptics.tap();
                                    setState(() => _obscurePassword = !_obscurePassword);
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Selector<AuthProvider, bool>(
                                selector: (_, provider) => provider.isLoading,
                                builder: (context, isLoading, child) {
                                  return TextButton(
                                    onPressed: isLoading ? null : _resetPassword,
                                    child: Text(
                                      'Forgot Password?',
                                      style: AppTypography.caption.copyWith(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 32),
                            // Sign In Button
                            Selector<AuthProvider, bool>(
                              selector: (_, provider) => provider.isLoading,
                              builder: (context, isLoading, child) {
                                return AuthButton(
                                  label: 'Sign In 🐶',
                                  color: AppTheme.primaryColor,
                                  textColor: Colors.white,
                                  onPressed: isLoading ? null : _login,
                                  isLoading: isLoading,
                                );
                              },
                            ),
                            const SizedBox(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Don't have an account?",
                                    style: AppTypography.caption),
                                TextButton(
                                  onPressed: () {
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
                            ),
                            const SizedBox(height: 24),
                            // Interactive Terms & Privacy Disclaimer
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: AppTheme.captionStyle.copyWith(
                                    fontSize: 12,
                                    color: AppTheme.textLightColor.withOpacity(0.6),
                                    height: 1.6,
                                  ),
                                  children: [
                                    const TextSpan(text: 'By signing in, you agree to our '),
                                    TextSpan(
                                      text: 'Terms of Service',
                                      style: const TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          FurHaptics.tap();
                                          _showFriendlySnackBar('📜 Terms of Service coming soon!');
                                        },
                                    ),
                                    const TextSpan(text: ' and '),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: const TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          FurHaptics.tap();
                                          _showFriendlySnackBar('🔒 Privacy Policy coming soon!');
                                        },
                                    ),
                                  ],
                                ),
                              ),
                            ).animate().fadeIn(delay: 400.ms),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                Selector<AuthProvider, bool>(
                  selector: (_, provider) => provider.isLoading,
                  builder: (context, isLoading, child) {
                    if (!isLoading) return const SizedBox.shrink();
                    return Positioned.fill(
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
                                    width: 80,
                                    height: 80,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          AppTheme.primaryColor),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text('Signing you in...', style: AppTypography.h3.copyWith(fontSize: 16)),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(duration: 300.ms),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
