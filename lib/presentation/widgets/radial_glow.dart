import 'package:flutter/material.dart';

class RadialGlow extends StatefulWidget {
  final Widget child;
  final Color color;
  final double size;
  final Duration duration;

  const RadialGlow({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.size = 200,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<RadialGlow> createState() => _RadialGlowState();
}

class _RadialGlowState extends State<RadialGlow> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    widget.color.withOpacity(_animation.value),
                    widget.color.withOpacity(0.0),
                  ],
                ),
              ),
            );
          },
        ),
        widget.child,
      ],
    );
  }
}
