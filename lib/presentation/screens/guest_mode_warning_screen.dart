import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

class GuestModeWarningScreen extends StatelessWidget {
  final VoidCallback onContinue;
  final VoidCallback onSignIn;

  const GuestModeWarningScreen({
    super.key,
    required this.onContinue,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFCF5), // Creamy White
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Warning Icon Animation
              Semantics(
                label: 'Warning animation',
                child: Lottie.asset(
                  'assets/animations/floating_bone.json',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 32),
              // Title
              const Text(
                'Guest Mode',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5A5BD9), // Sky Indigo
                ),
              ),
              const SizedBox(height: 16),
              // Description
              const Text(
                'This feature is not available in guest mode. Sign in to access:',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  color: Color(0xFF777777), // Stone Gray
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Feature List
              _FeatureItem(
                icon: Icons.history,
                text: 'Emotion history tracking',
                color: const Color(0xFFF95F62), // Coral Red
              ),
              const SizedBox(height: 12),
              _FeatureItem(
                icon: Icons.cloud_sync,
                text: 'Cloud sync across devices',
                color: const Color(0xFFFFA726), // Citrus Orange
              ),
              const SizedBox(height: 12),
              _FeatureItem(
                icon: Icons.settings,
                text: 'Advanced settings and preferences',
                color: const Color(0xFF3EDBF0), // Aqua Blue
              ),
              const SizedBox(height: 40),
              // Sign In Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: onSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A5BD9), // Sky Indigo
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    elevation: 4,
                  ),
                  child: const Text('Sign in to Access'),
                ),
              ),
              const SizedBox(height: 16),
              // Continue as Guest Button
              TextButton(
                onPressed: onContinue,
                child: const Text(
                  'Continue as Guest',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    color: Color(0xFF5A5BD9), // Sky Indigo
                    fontWeight: FontWeight.w600,
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

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _FeatureItem({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
