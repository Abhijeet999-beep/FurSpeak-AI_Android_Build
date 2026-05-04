import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:furspeak_ai/config/app_theme.dart';
import 'package:furspeak_ai/theme/app_animations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeAnimation = AnimationController(
      vsync: this,
      duration: AppTheme.animSlow,
    )..forward();

    // Signature haptic on splash
    FurHaptics.impact();

    // The splash screen is now a passive view.
    // Navigation is handled entirely by GoRouter's redirect logic
    // when AuthProvider.isAppReady becomes true.
  }

  @override
  void dispose() {
    _fadeAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.bgColor,       // Vanilla Cream
              AppTheme.primaryColor,   // Soft Periwinkle
              AppTheme.accentColor,    // Gentle Orange
            ],
            stops: [0.0, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Brand name — bold entrance with scale + fade
              Text(
                'FurSpeak AI',
                style: AppTheme.headingStyle.copyWith(
                  fontSize: 36,
                  color: AppTheme.primaryColor,
                ),
              )
                  .animate()
                  .fadeIn(duration: AppTheme.animSlow, curve: Curves.easeOut)
                  .scale(
                    begin: const Offset(0.7, 0.7),
                    end: const Offset(1.0, 1.0),
                    duration: AppTheme.animSlow,
                    curve: Curves.easeOutBack,
                  ),
              const SizedBox(height: 32),

              // Dog animation — delayed entrance for stagger effect
              Semantics(
                label: 'Corgi waving animation',
                child: Lottie.asset(
                  'assets/animations/splash_dog.json',
                  width: 220,
                  height: 220,
                  fit: BoxFit.contain,
                ),
              )
                  .animate()
                  .fadeIn(
                    duration: AppTheme.animMedium,
                    delay: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  )
                  .slideY(
                    begin: 0.15,
                    end: 0,
                    duration: AppTheme.animMedium,
                    delay: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                  ),
              const SizedBox(height: AppTheme.space24),

              // Tagline — gentle fade-in last
              Text(
                'Understanding your furry friend',
                style: AppTheme.bodyStyle.copyWith(
                  color: AppTheme.textLightColor,
                  fontWeight: FontWeight.w500,
                ),
              )
                  .animate()
                  .fadeIn(
                    duration: AppTheme.animMedium,
                    delay: const Duration(milliseconds: 600),
                    curve: Curves.easeOut,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
