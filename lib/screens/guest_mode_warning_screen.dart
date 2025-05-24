import 'package:flutter/material.dart';
import '../config/routes.dart';

class GuestModeWarningScreen extends StatelessWidget {
  const GuestModeWarningScreen({super.key});

  void _onContinueAsGuest(BuildContext context) {
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  void _onSignIn(BuildContext context) {
    Navigator.pushReplacementNamed(context, AppRoutes.authSelection);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guest Mode'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 80,
                color: Colors.orange,
              ),
              const SizedBox(height: 24),
              const Text(
                'Continue as Guest?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'In guest mode, you won\'t be able to:\n'
                '• Save detection history\n'
                '• Sync data across devices\n'
                '• Access premium features',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => _onContinueAsGuest(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('Continue as Guest'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _onSignIn(context),
                child: const Text('Sign In for Full Features'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
