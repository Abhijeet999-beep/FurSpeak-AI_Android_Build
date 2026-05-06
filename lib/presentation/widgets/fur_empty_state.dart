import 'package:flutter/material.dart';
import 'package:furspeak_ai/config/app_theme.dart';

/// A reusable empty state widget that follows the Velvet Paw V2 design system.
///
/// Displays an icon, title, subtitle, and an optional CTA button.
/// Used across Home, History, and Settings screens.
class FurEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double iconSize;

  const FurEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconSize = 64,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: AppTheme.primaryColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: AppTheme.space24),
            Text(
              title,
              style: AppTheme.titleStyle.copyWith(
                color: AppTheme.textColor,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space8),
            Text(
              subtitle,
              style: AppTheme.bodyStyle.copyWith(
                color: AppTheme.textLightColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppTheme.space24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: onAction,
                  style: AppTheme.primaryButtonStyle,
                  child: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
