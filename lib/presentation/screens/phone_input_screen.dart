import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:furspeak_ai/providers/auth_provider.dart';
import 'package:furspeak_ai/utils/auth_error_mapper.dart';
import 'package:furspeak_ai/config/app_theme.dart';
import 'package:furspeak_ai/config/app_routes.dart';

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

  void _handleSendOtp() async {
    if (_formKey.currentState?.validate() ?? false) {
      HapticFeedback.mediumImpact();
      FocusScope.of(context).unfocus();
      
      final authProvider = context.read<AuthProvider>();
      await authProvider.sendOtp(_phoneController.text.trim());
      
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
        } else {
          // Success, wait router handles navigation or we manually push OTP screen
          // Actually, GoRouter handles isAuthenticated, but here we just sent an OTP.
          // The user is NOT authenticated yet. We must manually navigate to OTP screen.
          context.goOtpVerify();
        }
      }
    }
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
                  'Enter your phone number',
                  style: AppTheme.headingStyle.copyWith(
                    color: AppTheme.primaryColor,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'We\'ll send you a verification code to confirm your number.',
                  style: AppTheme.bodyStyle.copyWith(
                    color: AppTheme.textLightColor,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _phoneController,
                  autofocus: true,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 18),
                  keyboardType: TextInputType.phone,
                  decoration: AppTheme.inputDecoration(
                    label: 'Phone Number',
                    hint: '+1 234 567 8900',
                    prefixIcon: Icons.phone,
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
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a valid phone number';
                    }
                    if (value.length < 8) {
                      return 'Phone number is too short';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _handleSendOtp,
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
                            'Send Code',
                            style: AppTheme.titleStyle.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                  ),
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
