import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:furspeak_ai/config/app_routes.dart';
import 'package:furspeak_ai/config/app_theme.dart';
import 'package:furspeak_ai/config/app_typography.dart';
import 'package:furspeak_ai/config/lottie_registry.dart';
import 'package:provider/provider.dart';
import 'package:furspeak_ai/providers/auth_provider.dart';
import 'package:furspeak_ai/utils/auth_error_mapper.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fadeController.dispose();
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
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    if (authProvider.isLoading) return;

    HapticFeedback.mediumImpact();

    await authProvider.signUp(
      _emailController.text.trim(),
      _passwordController.text,
      _nameController.text.trim(),
    );
    
    if (mounted) {
      if (authProvider.errorType != null) {
        final errorMsg = AuthErrorMapper.getErrorMessage(authProvider.errorType!);
        if (errorMsg.isNotEmpty) {
          _showFriendlySnackBar(errorMsg);
        }
      } else if (authProvider.errorMessage != null) {
        _showFriendlySnackBar(authProvider.errorMessage!);
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
      // We keep these specific overrides only if they differ from the global theme
      // but here we should ideally move them to AppTheme if they are standard.
      // For now, let's use the standardized radius.
      fillColor: AppTheme.surfaceActive, // Use surfaceActive for a cleaner white/off-white look
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
    final isCurrentlyLoading = context.read<AuthProvider>().isLoading;
    return PopScope(
      canPop: !isCurrentlyLoading,
      child: Scaffold(
        backgroundColor: AppTheme.bgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon:
                const Icon(Icons.arrow_back_rounded, color: AppTheme.textColor),
            onPressed: isLoading ? null : () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        // Header
                        Text(
                          'Create Account 🐶',
                          style: AppTheme.headingStyle.copyWith(fontSize: 28),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Join FurSpeak AI and understand your furry friend',
                          style: AppTheme.bodyStyle
                              .copyWith(color: AppTheme.textLightColor),
                        ),
                        const SizedBox(height: 32),
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
                            if (value.trim().length < 2) {
                              return 'Name should be at least 2 characters';
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
                            if (!value.contains('@') || !value.contains('.')) {
                              return 'Hmm, that email doesn\'t look right 📧';
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
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please create a password';
                            }
                            if (value.length < 6) {
                              return 'Make it at least 6 characters 🔐';
                            }
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
                              onPressed: () => setState(() =>
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords don\'t match 🤔';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),
                        // Password strength hint
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded,
                                  color: AppTheme.primaryColor, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Use 6+ characters with letters and numbers for a strong password.',
                                  style: AppTheme.captionStyle
                                      .copyWith(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        // Create Account Button
                        SizedBox(
                          height: 58,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _signUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shadowColor:
                                  AppTheme.primaryColor.withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppTheme.borderRadiusPill,
                              ),
                            ),
                            child: Text(
                              'Create Account 🐶',
                              style: AppTheme.titleStyle.copyWith(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Already have account
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Already have an account?',
                                style: AppTheme.captionStyle),
                            TextButton(
                              onPressed:
                                  isLoading ? null : () => context.goEmailLogin(),
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
                        const SizedBox(height: 32),
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
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: AppTheme.borderRadiusExtraLarge,
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Builder(builder: (context) {
                              return RepaintBoundary(
                                child: Lottie.asset(
                                  LottieRegistry.get('loading'),
                                  width: 90,
                                  height: 90,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const CircularProgressIndicator(),
                                ),
                              );
                            }),
                            const SizedBox(height: 16),
                            Text(
                              'Creating your account... 🐾',
                              style: AppTypography.h3.copyWith(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
