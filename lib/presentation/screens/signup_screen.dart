import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:furspeak_ai/config/app_routes.dart';
import 'package:furspeak_ai/config/app_theme.dart';
import 'package:furspeak_ai/config/app_typography.dart';
import 'package:furspeak_ai/config/lottie_registry.dart';
import 'package:furspeak_ai/theme/app_animations.dart';
import 'package:furspeak_ai/widgets/auth_button.dart';
import 'package:provider/provider.dart';
import 'package:furspeak_ai/providers/auth_provider.dart';
import 'package:furspeak_ai/utils/auth_error_mapper.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      FurHaptics.warning();
      return;
    }

    final authProvider = context.read<AuthProvider>();
    if (authProvider.isLoading) return;

    FurHaptics.impact();

    await authProvider.signUp(
      _emailController.text.trim(),
      _passwordController.text,
      _nameController.text.trim(),
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

  InputDecoration _styledInput({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return AppTheme.inputDecoration(
      label: label,
      prefixIcon: icon,
    ).copyWith(
      suffixIcon: suffixIcon,
      fillColor: AppTheme.surfaceActive,
      focusedBorder: OutlineInputBorder(
        borderRadius: AppTheme.borderRadiusMedium,
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppTheme.borderRadiusMedium,
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    
    return PopScope(
      canPop: !isLoading,
      child: Scaffold(
        backgroundColor: AppTheme.bgColor,
        body: Stack(
          children: [
            // Background Gradient
            Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.warmGradient,
              ),
            ),
            
            // Back Button
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 16, top: 8),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textColor),
                  onPressed: isLoading ? null : () => context.pop(),
                ),
              ),
            ),

            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Premium Header with Lottie
                      Center(
                        child: Column(
                          children: [
                            RepaintBoundary(
                              child: Lottie.asset(
                                LottieRegistry.get('corgi_wave'),
                                width: 140,
                                height: 140,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.pets, size: 60, color: AppTheme.primaryColor),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Create Account 🐶',
                              style: AppTheme.headingStyle.copyWith(
                                fontSize: 32,
                                color: AppTheme.primaryColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Join FurSpeak AI and understand your furry friend’s emotions.',
                                style: AppTheme.bodyStyle.copyWith(
                                  color: AppTheme.textLightColor,
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),
                      
                      const SizedBox(height: 40),
                      
                      // Form Fields - Staggered
                      StaggeredEntrance(
                        initialDelay: 200.ms,
                        children: [
                          // Name
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: _styledInput(
                              label: 'Your Name',
                              icon: Icons.person_rounded,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'What should we call you? 😊';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Email
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _styledInput(
                              label: 'Email',
                              icon: Icons.email_rounded,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'We need your email to get started';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email 📧';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: _styledInput(
                              label: 'Password',
                              icon: Icons.lock_rounded,
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
                              if (value == null || value.isEmpty) return 'Please create a password';
                              if (value.length < 6) return 'Make it at least 6 characters 🔐';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Confirm Password
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: _styledInput(
                              label: 'Confirm Password',
                              icon: Icons.lock_outline_rounded,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_rounded
                                      : Icons.visibility_off_rounded,
                                  color: AppTheme.textLightColor,
                                ),
                                onPressed: () {
                                  FurHaptics.tap();
                                  setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Confirm your password';
                              if (value != _passwordController.text) return 'Passwords don\'t match 🤔';
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),
                          
                          // Password Hint
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.security_rounded, color: AppTheme.primaryColor, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Secure your account with 6+ characters.',
                                    style: AppTheme.captionStyle.copyWith(fontSize: 13, color: AppTheme.primaryColor),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Sign Up Button
                          AuthButton(
                            label: 'Create Account 🐾',
                            color: AppTheme.primaryColor,
                            textColor: Colors.white,
                            onPressed: isLoading ? null : _signUp,
                            isLoading: isLoading,
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
                                  const TextSpan(text: 'By creating an account, you agree to our '),
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
                          ),
                          
                          // Already have account
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Already have an account?', style: AppTheme.captionStyle),
                              TextButton(
                                onPressed: isLoading ? null : () {
                                  FurHaptics.tap();
                                  context.goEmailLogin();
                                },
                                child: Text(
                                  'Sign In',
                                  style: AppTheme.bodyStyle.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ],
                  ),
                ),
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
                          Lottie.asset(
                            LottieRegistry.get('loading'),
                            width: 100,
                            height: 100,
                            errorBuilder: (context, error, stackTrace) =>
                                const CircularProgressIndicator(),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Setting up your kennel... 🐾',
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
    );
  }
}

