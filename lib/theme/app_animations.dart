import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppAnimations {
  // Button press animation
  static Widget buttonPressAnimation({
    required Widget child,
    required VoidCallback onPressed,
    bool enableHaptic = true,
  }) {
    return GestureDetector(
      onTapDown: (_) {
        if (enableHaptic) {
          HapticFeedback.lightImpact();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        child: child,
      ),
    );
  }

  // Icon hover animation
  static Widget iconHoverAnimation({
    required Widget icon,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 1.0, end: 1.0),
          duration: const Duration(milliseconds: 200),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: child,
            );
          },
          child: icon,
        ),
      ),
    );
  }

  // Fade transition
  static Widget fadeTransition({
    required Widget child,
    required bool isVisible,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isVisible ? 1.0 : 0.0,
      child: child,
    );
  }

  // Slide transition
  static Widget slideTransition({
    required Widget child,
    required bool isVisible,
    Offset offset = const Offset(0, 0.1),
  }) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 200),
      offset: isVisible ? Offset.zero : offset,
      child: child,
    );
  }

  // Scale transition
  static Widget scaleTransition({
    required Widget child,
    required bool isVisible,
  }) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 200),
      scale: isVisible ? 1.0 : 0.95,
      child: child,
    );
  }
}

// Extension for easy access to animations
extension AnimationExtension on BuildContext {
  void playHaptic() {
    HapticFeedback.lightImpact();
  }
}
