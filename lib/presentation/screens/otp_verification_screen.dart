import 'dart:async';
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

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _otpController.dispose();
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

  void _handleVerifyOtp() async {
    if (_formKey.currentState?.validate() ?? false) {
      FurHaptics.impact();
      FocusScope.of(context).unfocus();
      
      final authProvider = context.read<AuthProvider>();
      await authProvider.verifyOtp(_otpController.text.trim());
      
      if (mounted) {
        if (authProvider.errorType != null) {
          final errorMsg = AuthErrorMapper.getErrorMessage(authProvider.errorType!);
          if (errorMsg.isNotEmpty) {
            _showFriendlySnackBar(errorMsg, color: AppTheme.errorColor);
          }
        }
      }
    } else {
      FurHaptics.warning();
    }
  }

  void _handleResend() {
    FurHaptics.tap();
    context.pop(); // Go back to phone to resend properly
  }

  InputDecoration _styledInput({
    required String hint,
  }) {
    return AppTheme.inputDecoration(
      hint: hint,
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
    final authProvider = context.watch<AuthProvider>();
    final isLoading = authProvider.isLoading;
    
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
                        'Verify Number ✅',
                        style: AppTheme.headingStyle.copyWith(fontSize: 32),
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
                      
                      const SizedBox(height: 12),
                      Text(
                        'Enter the 6-digit code we sent to your phone.',
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
                            controller: _otpController,
                            autofocus: true,
                            onChanged: (value) {
                              if (_debounce?.isActive ?? false) _debounce!.cancel();
                              _debounce = Timer(const Duration(milliseconds: 400), () {
                                if (!mounted) return;
                                if (value.length == 6 && _formKey.currentState?.validate() == true && !_otpController.text.isEmpty) {
                                  _handleVerifyOtp();
                                }
                              });
                            },
                            style: const TextStyle(
                              fontFamily: 'Inter', 
                              fontSize: 28, 
                              letterSpacing: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            decoration: _styledInput(hint: '000000').copyWith(
                              counterText: "",
                            ),
                            validator: (value) {
                              if (value == null || value.trim().length != 6) {
                                return 'Please enter the 6-digit code';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 40),
                          
                          // Verify Button
                          AuthButton(
                            label: 'Verify & Continue 🐾',
                            color: AppTheme.primaryColor,
                            textColor: Colors.white,
                            onPressed: (isLoading || !authProvider.hasVerificationId) ? null : _handleVerifyOtp,
                            isLoading: isLoading,
                          ),
                          
                          const SizedBox(height: 32),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Didn\'t receive the code?',
                                style: AppTheme.bodyStyle.copyWith(
                                  color: AppTheme.textLightColor,
                                ),
                              ),
                              TextButton(
                                onPressed: isLoading ? null : _handleResend,
                                child: Text(
                                  'Edit Number',
                                  style: AppTheme.bodyStyle.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
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
                            'Verifying your code... 🐾',
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

