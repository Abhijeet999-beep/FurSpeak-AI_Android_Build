import 'package:flutter/material.dart';
import 'package:furspeak_ai/config/app_theme.dart';
import 'package:furspeak_ai/config/app_typography.dart';
import 'package:furspeak_ai/theme/app_animations.dart';

class AuthButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final Color textColor;
  final VoidCallback? onPressed;
  final Widget? iconWidget;
  final bool isLoading;

  const AuthButton({
    super.key,
    required this.label,
    this.icon,
    required this.color,
    required this.textColor,
    this.onPressed,
    this.iconWidget,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SquishButton(
        onPressed: isLoading ? null : onPressed,
        child: Container(
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            color: color,
            borderRadius: AppTheme.borderRadiusPill,
            border: color == Colors.white 
                ? Border.all(color: AppTheme.primaryColor.withOpacity(0.1), width: 1.5)
                : null,
            boxShadow: (color != Colors.white && !isLoading) ? [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(textColor),
                  ),
                )
              else ...[
                if (iconWidget != null)
                  iconWidget!
                else if (icon != null)
                  Icon(icon, size: 24, color: textColor),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: AppTypography.buttonLabel.copyWith(
                    color: textColor,
                    fontSize: 16,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
