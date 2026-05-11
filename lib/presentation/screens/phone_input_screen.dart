import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:furspeak_ai/providers/auth_provider.dart';
import 'package:furspeak_ai/utils/auth_error_mapper.dart';
import 'package:furspeak_ai/config/app_theme.dart';
import 'package:furspeak_ai/config/app_routes.dart';
import 'package:furspeak_ai/config/app_typography.dart';
import 'package:furspeak_ai/config/lottie_registry.dart';
import 'package:furspeak_ai/theme/app_animations.dart';
import 'package:furspeak_ai/widgets/auth_button.dart';

class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
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

  void _handleSendOtp() async {
    if (_formKey.currentState?.validate() ?? false) {
      FurHaptics.impact();
      FocusScope.of(context).unfocus();
      
      final authProvider = context.read<AuthProvider>();
      await authProvider.sendOtp(_phoneController.text.trim());
      
      if (mounted) {
        if (authProvider.errorType != null) {
          final errorMsg = AuthErrorMapper.getErrorMessage(authProvider.errorType!);
          if (errorMsg.isNotEmpty) {
            _showFriendlySnackBar(errorMsg, color: AppTheme.errorColor);
          }
        } else {
          context.goOtpVerify();
        }
      }
    } else {
      FurHaptics.warning();
    }
  }

  InputDecoration _styledInput({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return AppTheme.inputDecoration(
      label: label,
      hint: hint,
      prefixIcon: icon,
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
                      const SizedBox(height: 80),
                      // Header
                      Text(
                        'Phone Number 📱',
                        style: AppTheme.headingStyle.copyWith(fontSize: 32),
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
                      
                      const SizedBox(height: 12),
                      Text(
                        'We\'ll send you a verification code to confirm your number.',
                        style: AppTheme.bodyStyle.copyWith(
                          color: AppTheme.textLightColor,
                          fontSize: 16,
                        ),
                      ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                      
                      const SizedBox(height: 48),
                      
                      // Staggered Content
                      StaggeredEntrance(
                        initialDelay: 200.ms,
                        children: [
                          TextFormField(
                            controller: _phoneController,
                            autofocus: true,
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 18),
                            keyboardType: TextInputType.phone,
                            decoration: _styledInput(
                              label: 'Phone Number',
                              hint: '+1 234 567 8900',
                              icon: Icons.phone_android_rounded,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a valid phone number 🐾';
                              }
                              if (value.length < 8) {
                                return 'Phone number is too short';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 40),
                          
                          // Send OTP Button
                          AuthButton(
                            label: 'Send Verification Code 📨',
                            color: AppTheme.primaryColor,
                            textColor: Colors.white,
                            onPressed: isLoading ? null : _handleSendOtp,
                            isLoading: isLoading,
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Terms & Privacy Disclaimer
                          Text(
                            'By continuing, you agree to our\nTerms of Service and Privacy Policy',
                            textAlign: TextAlign.center,
                            style: AppTheme.captionStyle.copyWith(
                              fontSize: 12,
                              color: AppTheme.textLightColor.withOpacity(0.6),
                              height: 1.5,
                            ),
                          ).animate().fadeIn(delay: 400.ms),
                          
                          const SizedBox(height: 24),
                          
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline_rounded, color: AppTheme.textLightColor, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Standard carrier rates may apply for the SMS.',
                                    style: AppTheme.captionStyle.copyWith(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                            'Sending code... 🐾',
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

