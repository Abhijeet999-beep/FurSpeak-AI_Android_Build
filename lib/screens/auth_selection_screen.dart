import 'package:flutter/material.dart';
import '../config/routes.dart';

class AuthSelectionScreen extends StatelessWidget {
  const AuthSelectionScreen({super.key});

  void _onEmailLogin(BuildContext context) {
    // TODO: Implement email login
    Navigator.pushReplacementNamed(context, AppRoutes.profileSetup);
  }

  void _onPhoneLogin(BuildContext context) {
    // TODO: Implement phone login
    Navigator.pushReplacementNamed(context, AppRoutes.profileSetup);
  }

  void _onGoogleLogin(BuildContext context) {
    // TODO: Implement Google login
    Navigator.pushReplacementNamed(context, AppRoutes.profileSetup);
  }

  void _onGuestMode(BuildContext context) {
    Navigator.pushReplacementNamed(context, AppRoutes.guestModeWarning);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Welcome to FurSpeak AI',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose how you want to sign in',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildAuthButton(
                context,
                icon: Icons.email,
                label: 'Continue with Email',
                onPressed: () => _onEmailLogin(context),
              ),
              const SizedBox(height: 16),
              _buildAuthButton(
                context,
                icon: Icons.phone,
                label: 'Continue with Phone',
                onPressed: () => _onPhoneLogin(context),
              ),
              const SizedBox(height: 16),
              _buildAuthButton(
                context,
                icon: Icons.g_mobiledata,
                label: 'Continue with Google',
                onPressed: () => _onGoogleLogin(context),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _onGuestMode(context),
                child: const Text('Continue as Guest'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}
