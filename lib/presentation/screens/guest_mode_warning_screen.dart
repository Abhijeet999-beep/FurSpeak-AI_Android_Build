import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../../theme/app_theme.dart';

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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Warning Icon Animation
              Semantics(
                label: 'Friendly reminder animation',
                child: Lottie.asset(
                  'assets/animations/floating_bone.json',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: AppTheme.space32),
              // Title
              Text(
                'Unlock the Full Experience',
                style: context.text.displayMedium?.copyWith(
                  color: context.colors.primary,
                  fontSize: 28,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.space16),
              // Description
              Text(
                'Create an account to save your furry friend\'s emotional journey over time and unlock these features:',
                style: context.text.bodyLarge?.copyWith(
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.space24),
              // Feature List
              _FeatureItem(
                icon: Icons.history_rounded,
                text: 'Track emotional history & trends',
                color: context.colors.primary,
              ),
              const SizedBox(height: 12.0),
              _FeatureItem(
                icon: Icons.cloud_sync_rounded,
                text: 'Sync across all your devices',
                color: context.colors.secondary,
              ),
              const SizedBox(height: 12.0),
              _FeatureItem(
                icon: Icons.pets_rounded,
                text: 'Personalized pet profiles',
                color: context.colors.tertiary,
              ),
              const SizedBox(height: 40.0),
              // Sign In Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: onSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Create Free Account',
                    style: TextStyle(
                      fontFamily: AppTheme.primaryFont,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.space16),
              // Continue as Guest Button
              TextButton(
                onPressed: onContinue,
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                  ),
                ),
                child: Text(
                  'Maybe Later',
                  style: TextStyle(
                    fontFamily: AppTheme.primaryFont,
                    fontSize: 16,
                    color: context.colors.primary,
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: 12.0,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              text,
              style: context.text.bodyMedium?.copyWith(
                color: color.withOpacity(0.8), // Softer text color
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
