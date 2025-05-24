import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:go_router/go_router.dart';
import 'package:furspeak_ai/config/app_theme.dart';

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
      duration: const Duration(milliseconds: 1500),
    )..forward();

    // Add haptic feedback on splash
    HapticFeedback.mediumImpact();

    // Redirect to onboarding after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      HapticFeedback.lightImpact();
      context.go('/onboarding');
    });
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
              AppTheme.bgColor, // Vanilla Cream
              AppTheme.primaryColor, // Soft Periwinkle
              AppTheme.accentColor, // Gentle Orange
            ],
            stops: [0.0, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'FurSpeak AI',
                  style: AppTheme.headingStyle.copyWith(
                    fontSize: 36,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Semantics(
                  label: 'Corgi waving animation',
                  child: Lottie.asset(
                    'assets/animations/splash_dog.json',
                    width: 220,
                    height: 220,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'Understanding your furry friend',
                  style: AppTheme.bodyStyle.copyWith(
                    color: AppTheme.textLightColor,
                    fontWeight: FontWeight.w500,
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
