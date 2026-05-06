import 'package:flutter/material.dart';
import 'package:furspeak_ai/config/app_theme.dart';

/// A shimmer loading skeleton following the Velvet Paw V2 design system.
class FurLoadingSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const FurLoadingSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius,
  });

  /// Card-shaped skeleton placeholder.
  const FurLoadingSkeleton.card({
    super.key,
    this.width = double.infinity,
    this.height = 120,
  }) : borderRadius = null;

  /// List-item shaped skeleton placeholder.
  const FurLoadingSkeleton.listItem({
    super.key,
    this.width = double.infinity,
    this.height = 72,
  }) : borderRadius = null;

  @override
  State<FurLoadingSkeleton> createState() => _FurLoadingSkeletonState();
}

class _FurLoadingSkeletonState extends State<FurLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? AppTheme.borderRadiusMedium;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: [
                AppTheme.surfaceActive,
                AppTheme.primaryColor.withOpacity(0.06),
                AppTheme.surfaceActive,
              ],
            ),
          ),
        );
      },
    );
  }
}
