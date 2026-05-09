import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:furspeak_ai/providers/auth_provider.dart';
import 'package:furspeak_ai/utils/auth_error_mapper.dart';
import 'package:furspeak_ai/config/app_theme.dart';
import 'package:furspeak_ai/config/app_typography.dart';
import 'package:furspeak_ai/config/app_routes.dart';
import 'package:furspeak_ai/config/app_spacing.dart';
import 'package:furspeak_ai/theme/app_animations.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String? _loadingProvider;

  void _handleGoogleSignIn() async {
    FurHaptics.impact(); // Medium impact — significant action
    setState(() => _loadingProvider = 'google');
    
    final authProvider = context.read<AuthProvider>();
    await authProvider.signInWithGoogle();
    
    if (mounted) {
      setState(() => _loadingProvider = null);
      if (authProvider.errorType != null) {
        final errorMsg = AuthErrorMapper.getErrorMessage(authProvider.errorType!);
        if (errorMsg.isNotEmpty) {
          _showErrorSnackBar(errorMsg);
        }
      }
    }
  }

  void _handleGuestSignIn() async {
    FurHaptics.tap(); // Light tap — lower-commitment action
    setState(() => _loadingProvider = 'guest');
    
    final authProvider = context.read<AuthProvider>();
    await authProvider.continueAsGuest();
    
    if (mounted) {
      setState(() => _loadingProvider = null);
      if (authProvider.errorType != null) {
        if (!AppRoutes.isProd) {
          debugPrint("🛠️ [DEV] Guest Auth failed. Enabling debug bypass for validation.");
          authProvider.enableDebugBypass();
          return;
        }
        final errorMsg = AuthErrorMapper.getErrorMessage(authProvider.errorType!);
        if (errorMsg.isNotEmpty) {
          _showErrorSnackBar(errorMsg);
        }
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            const SizedBox(width: AppTheme.space8),
            Expanded(
              child: Text(
                message,
                style: AppTheme.bodyStyle.copyWith(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusMedium),
        margin: const EdgeInsets.all(AppTheme.space16),
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required bool isLoading,
    bool isPrimary = false,
    bool isGoogle = false,
  }) {
    final bool anyLoading = _loadingProvider != null;

    // Use AppTheme styles as base
    final ButtonStyle baseStyle = isPrimary 
        ? AppTheme.primaryButtonStyle 
        : AppTheme.accentButtonStyle.copyWith(
            backgroundColor: WidgetStateProperty.all(AppTheme.surfaceActive),
            foregroundColor: WidgetStateProperty.all(isGoogle ? AppTheme.textColor : AppTheme.primaryColor),
            side: WidgetStateProperty.all(BorderSide(
              color: isGoogle ? Colors.grey.shade300 : AppTheme.primaryColor.withOpacity(0.15),
            )),
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
      child: SquishButton(
        onPressed: anyLoading ? null : onPressed,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: anyLoading ? null : onPressed,
            style: baseStyle,
            icon: isLoading
                ? const SizedBox.shrink()
                : Icon(icon, size: 24),
            label: isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isPrimary ? Colors.white : AppTheme.primaryColor,
                      ),
                    ),
                  )
                : Text(
                    label,
                    style: AppTypography.buttonLabel.copyWith(
                      color: isPrimary ? Colors.white : (isGoogle ? AppTheme.textColor : AppTheme.primaryColor),
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 1),
              
              // App Logo — staggered entrance
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pets,
                  size: 50,
                  color: AppTheme.primaryColor,
                ),
              )
                  .animate()
                  .fadeIn(duration: AppTheme.animMedium, curve: Curves.easeOut)
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.0, 1.0),
                    duration: AppTheme.animMedium,
                    curve: Curves.easeOutBack,
                  ),
              const SizedBox(height: AppTheme.space24),
              
              Text(
                'FurSpeak AI',
                style: AppTheme.headingStyle.copyWith(
                  color: AppTheme.primaryColor,
                  fontSize: 32,
                ),
              )
                  .animate()
                  .fadeIn(
                    duration: AppTheme.animMedium,
                    delay: const Duration(milliseconds: 150),
                  )
                  .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
              const SizedBox(height: AppTheme.space12),
              
              Text(
                'Understand your pet’s emotions in seconds',
                textAlign: TextAlign.center,
                style: AppTheme.bodyStyle.copyWith(
                  color: AppTheme.textLightColor,
                  fontSize: 16,
                ),
              )
                  .animate()
                  .fadeIn(
                    duration: AppTheme.animMedium,
                    delay: const Duration(milliseconds: 300),
                  ),
              
              const Spacer(flex: 2),
              
              // Buttons — staggered entrance from bottom
              BoundedPulse(
                child: _buildButton(
                  label: 'Analyze your pet',
                  icon: Icons.camera_alt_rounded,
                  onPressed: _handleGuestSignIn,
                  isLoading: _loadingProvider == 'guest',
                  isPrimary: true,
                ),
              )
                  .animate()
                  .fadeIn(
                    duration: AppTheme.animMedium,
                    delay: const Duration(milliseconds: 400),
                  )
                  .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),
              
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.space16),
                child: Row(
                  children: [
                    Expanded(child: Divider(color: AppTheme.textLightColor.withOpacity(0.2))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space8),
                      child: Text(
                        'or sign in to save',
                        style: AppTheme.bodyStyle.copyWith(
                          fontSize: 12,
                          color: AppTheme.textLightColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: AppTheme.textLightColor.withOpacity(0.2))),
                  ],
                ),
              ).animate().fadeIn(delay: const Duration(milliseconds: 480)),

              _buildButton(
                label: 'Continue with Google',
                icon: Icons.g_mobiledata,
                onPressed: _handleGoogleSignIn,
                isLoading: _loadingProvider == 'google',
                isGoogle: true,
              )
                  .animate()
                  .fadeIn(
                    duration: AppTheme.animMedium,
                    delay: const Duration(milliseconds: 560),
                  )
                  .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),
              
              _buildButton(
                label: 'Continue with Phone',
                icon: Icons.phone,
                onPressed: () {
                  FurHaptics.tap();
                  context.goPhoneLogin();
                },
                isLoading: false,
              )
                  .animate()
                  .fadeIn(
                    duration: AppTheme.animMedium,
                    delay: const Duration(milliseconds: 640),
                  )
                  .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),
              
              _buildButton(
                label: 'Sign in with Email',
                icon: Icons.email_outlined,
                onPressed: () {
                  FurHaptics.tap();
                  context.goEmailLogin();
                },
                isLoading: false,
              )
                  .animate()
                  .fadeIn(
                    duration: AppTheme.animMedium,
                    delay: const Duration(milliseconds: 720),
                  )
                  .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),

              const SizedBox(height: AppTheme.space12),

              // ─── Terms & Privacy (Play Store requirement) ───
              Text(
                'By continuing, you agree to our Terms of Service\nand Privacy Policy',
                textAlign: TextAlign.center,
                style: AppTheme.captionStyle.copyWith(
                  fontSize: 12,
                  color: AppTheme.textLightColor.withOpacity(0.6),
                  height: 1.5,
                ),
              ).animate().fadeIn(delay: const Duration(milliseconds: 800)),

              const SizedBox(height: AppTheme.space16),
            ],
          ),
        ),
      ),
    );
  }
}
