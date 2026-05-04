import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:furspeak_ai/providers/auth_provider.dart';
import 'package:furspeak_ai/utils/auth_error_mapper.dart';
import 'package:furspeak_ai/config/app_theme.dart';
import 'package:furspeak_ai/config/app_routes.dart';

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

  void _handleVerifyOtp() async {
    if (_formKey.currentState?.validate() ?? false) {
      HapticFeedback.mediumImpact();
      FocusScope.of(context).unfocus();
      
      final authProvider = context.read<AuthProvider>();
      await authProvider.verifyOtp(_otpController.text.trim());
      
      if (mounted) {
        if (authProvider.errorType != null) {
          final errorMsg = AuthErrorMapper.getErrorMessage(authProvider.errorType!);
          if (errorMsg.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMsg),
                backgroundColor: Colors.red.shade800,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
        }
        // Success -> router automatically redirects since isAuthenticated = true
      }
    }
  }

  void _handleResend() {
    HapticFeedback.lightImpact();
    context.pop(); // Go back to phone to resend properly
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 1),
                Text(
                  'Verify Your Number',
                  style: AppTheme.headingStyle.copyWith(
                    color: AppTheme.primaryColor,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Enter the 6-digit code we sent to your phone.',
                  style: AppTheme.bodyStyle.copyWith(
                    color: AppTheme.textLightColor,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),
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
                    fontSize: 24, 
                    letterSpacing: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: AppTheme.inputDecoration(
                    hint: '000000',
                  ).copyWith(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length != 6) {
                      return 'Please enter the 6-digit code';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (authProvider.isLoading || !authProvider.hasVerificationId) ? null : _handleVerifyOtp,
                    style: AppTheme.primaryButtonStyle.copyWith(
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                    ),
                    child: authProvider.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Verify & Continue',
                            style: AppTheme.titleStyle.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
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
                      onPressed: authProvider.isLoading ? null : _handleResend,
                      child: Text(
                        'Edit Number',
                        style: AppTheme.bodyStyle.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
