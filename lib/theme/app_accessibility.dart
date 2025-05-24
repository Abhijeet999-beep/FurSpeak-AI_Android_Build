import 'package:flutter/material.dart';

class AppAccessibility {
  // Minimum touch target size
  static const double minTouchTarget = 48.0;

  // Color contrast ratios for text
  static const double minContrastRatio = 4.5; // WCAG AA standard

  // Helper to ensure minimum touch target size
  static Widget ensureMinTouchTarget({
    required Widget child,
    double? minWidth,
    double? minHeight,
  }) {
    return SizedBox(
      width: minWidth ?? minTouchTarget,
      height: minHeight ?? minTouchTarget,
      child: Center(child: child),
    );
  }

  // Helper to create accessible buttons
  static Widget accessibleButton({
    required Widget child,
    required VoidCallback onPressed,
    String? semanticLabel,
  }) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: ensureMinTouchTarget(
        child: child,
      ),
    );
  }

  // Helper to create accessible icons
  static Widget accessibleIcon({
    required IconData icon,
    required VoidCallback onPressed,
    String? semanticLabel,
  }) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: ensureMinTouchTarget(
        child: IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
        ),
      ),
    );
  }

  // Helper to create accessible text
  static Widget accessibleText({
    required String text,
    required TextStyle style,
    String? semanticLabel,
  }) {
    return Semantics(
      label: semanticLabel ?? text,
      child: Text(
        text,
        style: style,
      ),
    );
  }
}

// Extension for easy access to accessibility helpers
extension AccessibilityExtension on BuildContext {
  Widget makeAccessible({
    required Widget child,
    String? semanticLabel,
  }) {
    return Semantics(
      label: semanticLabel,
      child: child,
    );
  }
}
