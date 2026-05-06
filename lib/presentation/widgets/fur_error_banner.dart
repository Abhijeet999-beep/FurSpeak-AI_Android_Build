import 'package:flutter/material.dart';
import 'package:furspeak_ai/config/app_theme.dart';

/// Reusable error banner widget for the Velvet Paw V2 design system.
class FurErrorBanner extends StatelessWidget {
  final String message;
  final String? retryLabel;
  final VoidCallback? onRetry;
  final IconData icon;
  final bool isFullPage;

  const FurErrorBanner({
    super.key,
    required this.message,
    this.retryLabel,
    this.onRetry,
    this.icon = Icons.warning_amber_rounded,
    this.isFullPage = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      margin: isFullPage
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: AppTheme.space16),
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.06),
        borderRadius: AppTheme.borderRadiusMedium,
        border: Border.all(
          color: AppTheme.errorColor.withOpacity(0.15),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isFullPage ? 48 : 28, color: AppTheme.errorColor.withOpacity(0.7)),
          const SizedBox(height: AppTheme.space12),
          Text(message, style: AppTheme.bodyStyle.copyWith(color: AppTheme.textColor, fontSize: 14), textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: AppTheme.space16),
            SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(retryLabel ?? 'Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusMedium),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return isFullPage ? Center(child: Padding(padding: const EdgeInsets.all(AppTheme.space24), child: content)) : content;
  }
}
