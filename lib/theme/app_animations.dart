import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:furspeak_ai/config/app_theme.dart';
import 'package:furspeak_ai/utils/action_lock.dart';

/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// FurSpeak AI — Animation & Haptics System (V2)
///
/// ANIMATION GOVERNANCE RULES:
///   1. Only ONE primary animation per screen focus.
///   2. CTA pulse STOPS when user interacts (or after 3-5 seconds).
///   3. Particle effects ONLY for rare, high-value events.
///   4. Staggered animations ONLY on first load (not on every rebuild).
///   5. Max 2 simultaneous active animations.
///   6. Use RepaintBoundary for all animated widgets.
///
/// PERFORMANCE CONSTRAINTS:
///   - Maintain 60 FPS minimum.
///   - Lottie files < 300KB.
///   - Disable heavy effects on low-end devices.
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// ─── HAPTIC FEEDBACK SYSTEM (Categorized) ────────────────────────────────

class FurHaptics {
  FurHaptics._();

  /// Light tap — button presses, chip selections.
  static void tap() => HapticFeedback.lightImpact();

  /// Medium impact — result reveals, successful actions.
  static void impact() => HapticFeedback.mediumImpact();

  /// Heavy impact — error states, destructive confirmations.
  static void heavy() => HapticFeedback.heavyImpact();

  /// Soft selection — toggle switches, checkbox taps.
  static void select() => HapticFeedback.selectionClick();

  /// Success — subtle double-tap feel for completions.
  static void success() {
    HapticFeedback.lightImpact();
    Future.delayed(const Duration(milliseconds: 50), () => HapticFeedback.lightImpact());
  }

  /// Warning — distinct vibration for alerts.
  static void warning() => HapticFeedback.vibrate();
}

// ─── SQUASH & STRETCH BUTTON ─────────────────────────────────────────────
//
// A physics-based "squishy" button wrapper that scales down on press
// and springs back with a slight overshoot (easeOutBack).
// Automatically prevents double-taps for async actions using ActionLock.
//
// Usage:
//   SquishButton(
//     onPressed: () async => doSomething(),
//     child: YourButtonContent(),
//   )

class SquishButton extends StatefulWidget {
  final Widget child;
  final FutureOr<void> Function()? onPressed;
  final double pressScale;
  final bool enableHaptic;
  final bool useGlobalLock;

  const SquishButton({
    super.key,
    required this.child,
    this.onPressed,
    this.pressScale = 0.95,
    this.enableHaptic = true,
    this.useGlobalLock = true,
  });

  @override
  State<SquishButton> createState() => _SquishButtonState();
}

class _SquishButtonState extends State<SquishButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  bool _isLocalLocked = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppTheme.animFast,
      reverseDuration: const Duration(milliseconds: 300),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: widget.pressScale).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
        reverseCurve: Curves.easeOutBack, // Spring-back overshoot
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLocked => widget.useGlobalLock ? globalActionLock.isLocked : _isLocalLocked;

  void _onTapDown(TapDownDetails _) {
    debugPrint('SquishButton: _onTapDown - onPressed=${widget.onPressed != null}, _isLocked=$_isLocked');
    if (widget.onPressed == null || _isLocked) {
      return;
    }
    _controller.forward();
    if (widget.enableHaptic) FurHaptics.tap();
  }

  void _onTapUp(TapUpDetails _) async {
    debugPrint('SquishButton: _onTapUp');
    _controller.reverse();
    if (widget.onPressed != null) {
      if (_isLocked) {
        debugPrint('SquishButton: TAP BLOCKED BY LOCK');
        return;
      }

      if (widget.useGlobalLock) {
        await globalActionLock.execute(() async {
          await widget.onPressed!();
        });
      } else {
        setState(() => _isLocalLocked = true);
        try {
          await widget.onPressed!();
        } finally {
          if (mounted) setState(() => _isLocalLocked = false);
        }
      }
    }
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedBuilder(
          animation: _scaleAnim,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnim.value,
              child: child,
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}

// ─── BOUNDED CTA PULSE ──────────────────────────────────────────────────
//
// A subtle pulse that draws the eye to primary actions.
//
// RULES:
//   - Only on first visit OR idle state.
//   - Stops after [maxPulses] cycles (default: 3).
//   - Never loops forever.
//
// Usage:
//   BoundedPulse(
//     child: YourCTAButton(),
//   )

class BoundedPulse extends StatefulWidget {
  final Widget child;
  final int maxPulses;
  final double scaleAmplitude;

  const BoundedPulse({
    super.key,
    required this.child,
    this.maxPulses = 3,
    this.scaleAmplitude = 1.03,
  });

  @override
  State<BoundedPulse> createState() => _BoundedPulseState();
}

class _BoundedPulseState extends State<BoundedPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _pulseCount = 0;
  bool _stopped = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppTheme.animSlow,
    );

    _controller.addStatusListener((status) {
      if (_stopped) return;
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _pulseCount++;
        if (_pulseCount >= widget.maxPulses) {
          _stopped = true;
        } else {
          _controller.forward();
        }
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale =
              1.0 + (_controller.value * (widget.scaleAmplitude - 1.0));
          return Transform.scale(scale: scale, child: child);
        },
        child: widget.child,
      ),
    );
  }
}

// ─── GENTLE FLOAT ANIMATION ──────────────────────────────────────────────
//
// A vertical "breathing" effect for hero elements (like Lottie pets).
//
// Usage:
//   FloatingLottie(
//     child: Lottie.asset(...),
//   )

class FloatingLottie extends StatefulWidget {
  final Widget child;
  final double distance;
  final Duration duration;

  const FloatingLottie({
    super.key,
    required this.child,
    this.distance = 12.0,
    this.duration = const Duration(milliseconds: 2500),
  });

  @override
  State<FloatingLottie> createState() => _FloatingLottieState();
}

class _FloatingLottieState extends State<FloatingLottie>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0,
      end: widget.distance,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutQuart, // Smoother "breathing" feel
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ─── GLOW PULSE (Progress Bar) ──────────────────────────────────────────
//
// Adds a pulsing glow effect to emphasize specific UI components.
//
// Usage:
//   GlowPulse(
//     color: Colors.blue,
//     child: LinearProgressIndicator(...),
//   )

class GlowPulse extends StatefulWidget {
  final Widget child;
  final Color color;
  final bool isActive;
  final Duration duration;

  const GlowPulse({
    super.key,
    required this.child,
    required this.color,
    this.isActive = true,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<GlowPulse> createState() => _GlowPulseState();
}

class _GlowPulseState extends State<GlowPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _glowAnim = Tween<double>(begin: 4.0, end: 12.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isActive) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(GlowPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.repeat(reverse: true);
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.3),
                blurRadius: _glowAnim.value,
                spreadRadius: _glowAnim.value / 4,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ─── STAGGERED LIST ENTRANCE ─────────────────────────────────────────────
//
// Wraps a list of children to animate them in with a cascading
// fade + slide-up effect. ONLY runs on first build.
//
// Usage:
//   StaggeredEntrance(
//     children: [Widget1(), Widget2(), Widget3()],
//   )

class StaggeredEntrance extends StatelessWidget {
  final List<Widget> children;
  final Duration staggerDelay;
  final Duration itemDuration;
  final Duration initialDelay;
  final double slideOffset;

  const StaggeredEntrance({
    super.key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 100),
    this.itemDuration = const Duration(milliseconds: 500),
    this.initialDelay = Duration.zero,
    this.slideOffset = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(children.length, (index) {
          return children[index]
              .animate()
              .fadeIn(
                duration: itemDuration,
                delay: initialDelay + (staggerDelay * index),
                curve: Curves.easeOut,
              )
              .slideY(
                begin: slideOffset / 100,
                end: 0,
                duration: itemDuration + const Duration(milliseconds: 400), // Slightly longer
                delay: initialDelay + (staggerDelay * index),
                curve: const Cubic(0.05, 0.9, 0.1, 1.0), // More expressive quintic curve
              );
        }),
      ),
    );
  }
}

// ─── PROCESSING MESSAGE ROTATOR ──────────────────────────────────────────
//
// Rotates through playful processing messages to build anticipation
// and improve perceived speed. Leverages the Variable Reward loop.
//
// Usage:
//   ProcessingMessageRotator(isActive: true)

class ProcessingMessageRotator extends StatefulWidget {
  final bool isActive;
  final TextStyle? textStyle;
  final List<String>? customMessages;

  const ProcessingMessageRotator({
    super.key,
    required this.isActive,
    this.textStyle,
    this.customMessages,
  });

  static const List<String> _defaultMessages = [
    'Preparing video…',
    'Detecting your pet…',
    'Understanding behavior…',
    'Finalizing results…',
  ];

  @override
  State<ProcessingMessageRotator> createState() =>
      _ProcessingMessageRotatorState();
}

class _ProcessingMessageRotatorState extends State<ProcessingMessageRotator> {
  int _currentIndex = 0;
  Timer? _timer;

  List<String> get _messages =>
      widget.customMessages ?? ProcessingMessageRotator._defaultMessages;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) _startRotation();
  }

  @override
  void didUpdateWidget(ProcessingMessageRotator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _startRotation();
    } else if (!widget.isActive && oldWidget.isActive) {
      _stopRotation();
    }
  }

  void _startRotation() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 2200), (_) {
      if (!mounted) return;
      setState(() {
        _currentIndex = (_currentIndex + 1) % _messages.length;
      });
    });
  }

  void _stopRotation() {
    _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return const SizedBox.shrink();

    final style = widget.textStyle ??
        AppTheme.titleStyle.copyWith(fontSize: 16);

    return RepaintBoundary(
      child: AnimatedSwitcher(
        duration: AppTheme.animMedium,
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: Text(
          _messages[_currentIndex],
          key: ValueKey<int>(_currentIndex),
          style: style,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ─── LEGACY COMPAT: AppAnimations (thin wrapper) ─────────────────────────
//
// Maintained for backward-compatibility. New code should use the
// widgets above directly.

class AppAnimations {
  AppAnimations._();

  /// Standard fade transition (use flutter_animate for new code).
  static Widget fadeTransition({
    required Widget child,
    required bool isVisible,
  }) {
    return AnimatedOpacity(
      duration: AppTheme.animFast,
      opacity: isVisible ? 1.0 : 0.0,
      child: child,
    );
  }

  /// Slide transition.
  static Widget slideTransition({
    required Widget child,
    required bool isVisible,
    Offset offset = const Offset(0, 0.1),
  }) {
    return AnimatedSlide(
      duration: AppTheme.animFast,
      offset: isVisible ? Offset.zero : offset,
      child: child,
    );
  }

  /// Scale transition.
  static Widget scaleTransition({
    required Widget child,
    required bool isVisible,
  }) {
    return AnimatedScale(
      duration: AppTheme.animFast,
      scale: isVisible ? 1.0 : 0.95,
      child: child,
    );
  }
}

// ─── CONTEXT EXTENSION ──────────────────────────────────────────────────

extension AnimationExtension on BuildContext {
  void playHaptic() => FurHaptics.tap();
}
