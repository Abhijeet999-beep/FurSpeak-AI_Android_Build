import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:furspeak_ai/config/app_routes.dart';
import 'package:furspeak_ai/config/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:furspeak_ai/providers/auth_provider.dart';
import 'package:furspeak_ai/utils/auth_error_mapper.dart';

/// Welcome / Main entry screen for authentication
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

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
    
    HapticFeedback.mediumImpact();

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

    HapticFeedback.mediumImpact();

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
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      const SizedBox(height: 48),
                      // Title
                      Text(
                        'FurSpeak AI 🐾',
                        style: AppTheme.headingStyle.copyWith(
                          fontSize: 36,
                          color: AppTheme.primaryColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Understand your dog like never before',
                        style: AppTheme.bodyStyle.copyWith(
                          color: AppTheme.textLightColor,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 36),
                      // Dog Illustration
                      Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.12),
                              blurRadius: 40,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Lottie.asset(
                            'assets/animations/splash_dog.json',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 44),
                      // ==== AUTH BUTTONS ====
                      // 1. Continue with Google
                      _AuthButton(
                        label: 'Continue with Google',
                        icon: Icons.g_mobiledata_rounded,
                        color: Colors.white,
                        textColor: AppTheme.textColor,
                        onPressed: _isLoading ? null : _signInWithGoogle,
                        iconWidget: _googleIcon(),
                      ),
                      const SizedBox(height: 14),
                      // 2. Continue with Phone (placeholder)
                      _AuthButton(
                        label: 'Continue with Phone',
                        icon: Icons.phone_rounded,
                        color: AppTheme.successColor,
                        textColor: Colors.white,
                        onPressed: _isLoading
                            ? null
                            : () {
                                _showFriendlySnackBar(
                                    '📱 Phone sign-in coming soon!',
                                    icon: Icons.phone_rounded);
                              },
                      ),
                      const SizedBox(height: 14),
                      // 3. Continue as Guest
                      _AuthButton(
                        label: 'Keep Exploring',
                        icon: Icons.person_outline_rounded,
                        color: AppTheme.accentColor,
                        textColor: Colors.white,
                        onPressed: _isLoading ? null : _continueAsGuest,
                      ),
                      const SizedBox(height: 28),
                      // Divider
                      Row(
                        children: [
                          Expanded(
                              child: Divider(
                                  color: Colors.grey.shade300, thickness: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('or',
                                style: AppTheme.captionStyle
                                    .copyWith(fontSize: 15)),
                          ),
                          Expanded(
                              child: Divider(
                                  color: Colors.grey.shade300, thickness: 1)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // 4. Sign in with Email (text link)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: isLoading
                                ? null
                                : () => context.push(AppRoutes.emailLogin),
                            child: Text(
                              'Sign in with Email',
                              style: AppTheme.bodyStyle.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Don't have an account?
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Don't have an account?",
                              style: AppTheme.captionStyle),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => context.goSignUp(),
                            child: Text(
                              'Sign Up',
                              style: AppTheme.bodyStyle.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              // Loading overlay
              if (isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 24,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Builder(builder: (context) {
                            try {
                              return Lottie.asset(
                                'assets/animations/loading.json',
                                width: 90,
                                height: 90,
                              );
                            } catch (_) {
                              return const CircularProgressIndicator();
                            }
                          }),
                          const SizedBox(height: 16),
                          Text(
                            'Signing you in... 🐶',
                            style: AppTheme.titleStyle.copyWith(fontSize: 16),
                          ),
                        ],
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

  Widget _googleIcon() {
    try {
      return Image.asset('assets/images/google_logo.png', height: 22);
    } catch (_) {
      return const Icon(Icons.g_mobiledata_rounded, size: 26);
    }
  }
}

// =========================================================================
// Reusable Auth Button
// =========================================================================
class _AuthButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback? onPressed;
  final Widget? iconWidget;

  const _AuthButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    this.onPressed,
    this.iconWidget,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 0,
          shadowColor: color.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.borderRadiusPill,
            side: BorderSide.none,
          ),
          textStyle: AppTheme.titleStyle.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconWidget != null)
              iconWidget!
            else
              Icon(icon, size: 24, color: textColor),
            const SizedBox(width: 12),
            Text(label),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// Email Login Screen (pushed from Welcome/Login)
// =========================================================================
class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen();

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
    if (!_formKey.currentState!.validate()) return;
    
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isLoading) return;

    HapticFeedback.mediumImpact();

    await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
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

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showFriendlySnackBar('📧 Enter your email first, then tap Forgot Password.');
      return;
    }

    // reset password might still need authService or provider
    // the provider doesn't have it yet, we can skip reset password logic for now or implement it
    _showFriendlySnackBar('📧 Check your info and try again.');
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    // Header
                    Text(
                      'Welcome Back 👋',
                      style: AppTheme.headingStyle.copyWith(fontSize: 28),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to your account',
                      style: AppTheme.bodyStyle
                          .copyWith(color: AppTheme.textLightColor),
                    ),
                    const SizedBox(height: 36),
                    // Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: AppTheme.inputDecoration(
                        label: 'Email',
                        prefixIcon: Icons.email_rounded,
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
                    const SizedBox(height: 18),
                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: AppTheme.inputDecoration(
                        label: 'Password',
                        prefixIcon: Icons.lock_rounded,
                      ).copyWith(
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
                      child: TextButton(
                        onPressed: isLoading ? null : _resetPassword,
                        child: Text(
                          'Forgot Password?',
                          style: AppTheme.captionStyle.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Sign In Button
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: AppTheme.primaryColor.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppTheme.borderRadiusPill,
                          ),
                        ),
                        child: Text(
                          'Sign In 🐶',
                          style: AppTheme.titleStyle.copyWith(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account?",
                            style: AppTheme.captionStyle),
                        TextButton(
                          onPressed: () {
                            context.go(AppRoutes.signup);
                          },
                          child: Text(
                            'Sign Up',
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
              ),
            ),
            if (isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryColor),
                        ),
                        const SizedBox(height: 16),
                        Text('Signing in...', style: AppTheme.titleStyle),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
