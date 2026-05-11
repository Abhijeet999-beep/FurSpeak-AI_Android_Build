import 'package:flutter/material.dart';
import 'dart:ui';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// FurSpeak AI — "Velvet Paw" Design System (V2)
///
/// This class now acts as a central registry for the design system,
/// delegating to specialized files for Colors, Spacing, and Typography.
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class AppTheme {
  AppTheme._();

  // Re-export core tokens for backward compatibility
  static const Color bgColor = AppColors.bg;
  static const Color primaryColor = AppColors.primary;
  static const Color accentColor = AppColors.accent;
  static const Color tertiaryColor = AppColors.tertiary;
  static const Color successColor = AppColors.success;
  static const Color errorColor = AppColors.error;
  static const Color textColor = AppColors.text;
  static const Color textLightColor = AppColors.textLight;

  static const Color surfaceBase = AppColors.surfaceBase;
  static const Color surfaceLow = AppColors.surfaceLow;
  static const Color surfaceActive = AppColors.surfaceActive;
  static const Color surfaceElevated = AppColors.surfaceElevated;

  static const Color surfaceContainerLow = AppColors.surfaceContainerLow;
  static const Color surfaceContainerLowest = AppColors.surfaceContainerLowest;
  static const Color surfaceContainerHigh = AppColors.surfaceContainerHigh;

  static const double space4 = 4.0;
  static const double space8 = AppSpacing.s8;
  static const double space10 = 10.0;
  static const double space12 = AppSpacing.s12;
  static const double space16 = AppSpacing.s16;
  static const double space20 = AppSpacing.s20;
  static const double space24 = AppSpacing.s24;
  static const double space32 = AppSpacing.s32;

  static const double radiusSmall = 8.0;
  static const double radiusMedium = AppSpacing.r16;
  static const double radiusLarge = AppSpacing.r24;
  static const double radiusExtraLarge = AppSpacing.r32;

  static final BorderRadius borderRadiusSmall = BorderRadius.circular(radiusSmall);
  static final BorderRadius borderRadiusMedium = AppSpacing.radius16;
  static final BorderRadius borderRadiusLarge = AppSpacing.radius24;
  static final BorderRadius borderRadiusExtraLarge = AppSpacing.radius32;
  static final BorderRadius borderRadiusPill = AppSpacing.radiusPill;

  static const Duration animFast = AppSpacing.animFast;
  static const Duration animMedium = AppSpacing.animMedium;
  static const Duration animSlow = AppSpacing.animSlow;

  // Shadows (Refined Periwinkle — Softer, Atmospheric, Premium)
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: const Color(0xFF7E8CE0).withOpacity(0.04), // Softer
          blurRadius: 60, // Increased blur
          offset: const Offset(0, 20),
          spreadRadius: -8,
        ),
        BoxShadow(
          color: const Color(0xFF7E8CE0).withOpacity(0.015),
          blurRadius: 25,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get floatShadow => [
        BoxShadow(
          color: const Color(0xFF7E8CE0).withOpacity(0.06), // Softer
          blurRadius: 80, // Increased blur
          offset: const Offset(0, 32),
          spreadRadius: -12,
        ),
        BoxShadow(
          color: const Color(0xFF7E8CE0).withOpacity(0.02),
          blurRadius: 40,
          offset: const Offset(0, 12),
        ),
      ];

  // Gradients
  static const LinearGradient primaryGradient = AppColors.primaryGradient;
  static const LinearGradient warmGradient = AppColors.warmGradient;

  // Typography (aliases)
  static final TextStyle headingStyle = AppTypography.h1;
  static final TextStyle subheadingStyle = AppTypography.h2;
  static final TextStyle titleStyle = AppTypography.h3;
  static final TextStyle bodyStyle = AppTypography.body;
  static final TextStyle captionStyle = AppTypography.caption;

  // Button Styles
  static final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    elevation: 0,
    shadowColor: AppColors.primary.withOpacity(0.3),
    shape: RoundedRectangleBorder(borderRadius: borderRadiusPill),
    textStyle: AppTypography.buttonLabel,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  );

  static final ButtonStyle accentButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.accent,
    foregroundColor: Colors.white,
    elevation: 0,
    shadowColor: AppColors.accent.withOpacity(0.3),
    shape: RoundedRectangleBorder(borderRadius: borderRadiusPill),
    textStyle: AppTypography.buttonLabel,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  );

  static final ButtonStyle successButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.success,
    foregroundColor: Colors.white,
    elevation: 0,
    shadowColor: AppColors.success.withOpacity(0.3),
    shape: RoundedRectangleBorder(borderRadius: borderRadiusPill),
    textStyle: AppTypography.buttonLabel,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  );

  // Decorations
  static final BoxDecoration cardDecoration = BoxDecoration(
    color: AppColors.surfaceContainerLowest,
    borderRadius: borderRadiusLarge,
    boxShadow: softShadow,
  );

  static InputDecoration inputDecoration({
    String? label,
    String? hint,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      border: OutlineInputBorder(
        borderRadius: borderRadiusMedium,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadiusMedium,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadiusMedium,
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: AppColors.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s24,
        vertical: AppSpacing.s16,
      ),
      labelStyle: AppTypography.body.copyWith(color: AppColors.textLight),
      hintStyle: AppTypography.body.copyWith(
        color: AppColors.textLight.withOpacity(0.5),
      ),
    );
  }

  static AppBarTheme appBarTheme = AppBarTheme(
    backgroundColor: AppColors.surfaceActive,
    elevation: 0,
    centerTitle: true,
    iconTheme: const IconThemeData(color: AppColors.primary),
    titleTextStyle: AppTypography.h3.copyWith(fontSize: 20),
  );

  static ThemeData get theme => ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.bg,
        appBarTheme: appBarTheme,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: primaryButtonStyle,
        ),
        textTheme: TextTheme(
          displayLarge: AppTypography.h1,
          displayMedium: AppTypography.h2,
          titleLarge: AppTypography.h3,
          bodyLarge: AppTypography.body,
          bodyMedium: AppTypography.caption,
        ),
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          tertiary: AppColors.tertiary,
          error: AppColors.error,
          surface: AppColors.surfaceBase,
        ),
        useMaterial3: true,
      );
}


// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// EMOTION → UI MAPPING (Psychological)
//
// Maps AI-detected emotions to visual properties for the result screen.
// This creates "emotional immersion" — the UI itself feels the emotion.
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class EmotionStyle {
  final Color color;
  final Color glowColor;
  final Duration entranceDuration;
  final Curve entranceCurve;
  final IconData icon;
  final String emoji;
  final String label;
  final Color actionCardColor;  // For suggested action cards

  const EmotionStyle({
    required this.color,
    required this.glowColor,
    required this.entranceDuration,
    required this.entranceCurve,
    required this.icon,
    required this.emoji,
    required this.label,
    required this.actionCardColor,
  });

  /// Factory to resolve an emotion string into its full visual style.
  factory EmotionStyle.fromEmotion(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return EmotionStyle(
          color: AppTheme.successColor,
          glowColor: AppTheme.tertiaryColor.withOpacity(0.3),
          entranceDuration: AppTheme.animMedium,
          entranceCurve: Curves.easeOutBack,
          icon: Icons.emoji_emotions_rounded,
          emoji: '😊',
          label: 'Happy',
          actionCardColor: const Color(0xFFE8FFF0),
        );
      case 'playful':
        return EmotionStyle(
          color: const Color(0xFF26C6DA),
          glowColor: const Color(0xFF26C6DA).withOpacity(0.2),
          entranceDuration: AppTheme.animMedium,
          entranceCurve: Curves.easeOutBack,
          icon: Icons.pets_rounded,
          emoji: '🐾',
          label: 'Playful',
          actionCardColor: const Color(0xFFE0F7FA),
        );
      case 'alert':
        return EmotionStyle(
          color: AppTheme.accentColor,
          glowColor: AppTheme.accentColor.withOpacity(0.2),
          entranceDuration: AppTheme.animFast,
          entranceCurve: Curves.easeOut,
          icon: Icons.visibility_rounded,
          emoji: '👀',
          label: 'Alert',
          actionCardColor: const Color(0xFFFFF8E1),
        );
      case 'angry':
        return EmotionStyle(
          color: AppTheme.errorColor,
          glowColor: AppTheme.errorColor.withOpacity(0.15),
          entranceDuration: AppTheme.animFast,
          entranceCurve: Curves.easeOut,
          icon: Icons.warning_amber_rounded,
          emoji: '😠',
          label: 'Angry',
          actionCardColor: const Color(0xFFFFEBEE),
        );
      case 'sad':
        return EmotionStyle(
          color: const Color(0xFF4A90E2),
          glowColor: const Color(0xFF4A90E2).withOpacity(0.15),
          entranceDuration: AppTheme.animSlow,
          entranceCurve: Curves.easeInOut,
          icon: Icons.sentiment_dissatisfied_rounded,
          emoji: '😢',
          label: 'Sad',
          actionCardColor: const Color(0xFFE3F2FD),
        );
      case 'fearful':
        return EmotionStyle(
          color: const Color(0xFF7B61FF),
          glowColor: const Color(0xFF7B61FF).withOpacity(0.15),
          entranceDuration: AppTheme.animSlow,
          entranceCurve: Curves.easeInOut,
          icon: Icons.shield_rounded,
          emoji: '😨',
          label: 'Fearful',
          actionCardColor: const Color(0xFFEDE7F6),
        );
      case 'surprised':
        return EmotionStyle(
          color: const Color(0xFFFF6B6B),
          glowColor: const Color(0xFFFF6B6B).withOpacity(0.15),
          entranceDuration: AppTheme.animFast,
          entranceCurve: Curves.easeOutBack,
          icon: Icons.flash_on_rounded,
          emoji: '😲',
          label: 'Surprised',
          actionCardColor: const Color(0xFFFFF3E0),
        );
      case 'disgusted':
        return EmotionStyle(
          color: const Color(0xFF66BB6A),
          glowColor: const Color(0xFF66BB6A).withOpacity(0.15),
          entranceDuration: AppTheme.animMedium,
          entranceCurve: Curves.easeOut,
          icon: Icons.sick_rounded,
          emoji: '🤢',
          label: 'Disgusted',
          actionCardColor: const Color(0xFFE8F5E9),
        );
      case 'frown':
        return EmotionStyle(
          color: const Color(0xFF607D8B),
          glowColor: const Color(0xFF607D8B).withValues(alpha: 0.15),
          entranceDuration: AppTheme.animSlow,
          entranceCurve: Curves.easeInOut,
          icon: Icons.sentiment_very_dissatisfied_rounded,
          emoji: '☹️',
          label: 'Frowning',
          actionCardColor: const Color(0xFFECEFF1),
        );
      case 'neutral':
        return EmotionStyle(
          color: const Color(0xFF90A4AE),
          glowColor: const Color(0xFF90A4AE).withOpacity(0.15),
          entranceDuration: AppTheme.animMedium,
          entranceCurve: Curves.easeOut,
          icon: Icons.sentiment_neutral_rounded,
          emoji: '😐',
          label: 'Neutral',
          actionCardColor: const Color(0xFFECEFF1),
        );
      case 'relaxed':
      case 'relax':
        return EmotionStyle(
          color: const Color(0xFF26A69A),
          glowColor: const Color(0xFF26A69A).withOpacity(0.15),
          entranceDuration: AppTheme.animSlow,
          entranceCurve: Curves.easeInOut,
          icon: Icons.nightlight_round,
          emoji: '😌',
          label: 'Relaxed',
          actionCardColor: const Color(0xFFE0F2F1),
        );
      default:
        return EmotionStyle(
          color: AppTheme.primaryColor,
          glowColor: AppTheme.primaryColor.withOpacity(0.1),
          entranceDuration: AppTheme.animMedium,
          entranceCurve: Curves.easeOut,
          icon: Icons.pets_rounded,
          emoji: '🐕',
          label: emotion.isNotEmpty
              ? '${emotion[0].toUpperCase()}${emotion.substring(1)}'
              : 'Unknown',
          actionCardColor: AppTheme.surfaceLow,
        );
    }
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// GLASSMORPHISM — "Pet Mood Glass"
//
// Use ONLY for:
//   - Result cards
//   - Emotion highlight panels
//
// NEVER use:
//   - Full-screen glass layers
//   - Nested BackdropFilters
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class PetMoodGlass extends StatelessWidget {
  final Widget child;
  final double opacity;
  final BorderRadius? borderRadius;
  final Color? color;

  const PetMoodGlass({
    super.key,
    required this.child,
    this.opacity = 0.6,
    this.borderRadius,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppTheme.borderRadiusLarge;
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: AppTheme.softShadow,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
          child: Container(
            decoration: BoxDecoration(
              color: (color ?? AppTheme.surfaceActive).withOpacity(opacity),
              borderRadius: radius,
              border: Border.all(
                color: Colors.white.withOpacity(0.25), // Cleaner, more visible edge
                width: 1.5,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0.05),
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.02),
                ],
                stops: const [0.0, 0.4, 0.6, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Top Shine Highlight (Inner Depth)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 100, // Slightly taller
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft, // Angle the shine
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.4), // Brighter shine
                          Colors.white.withOpacity(0.0),
                        ],
                        stops: const [0.0, 0.7],
                      ),
                    ),
                  ),
                ),
                // Inner Glow / Depth Ring (The "Velvet" feel)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                        width: 2.5, // Slightly thicker for depth
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3), // More pronounced inner glow
                          blurRadius: 30,
                          spreadRadius: -15,
                          offset: const Offset(0, 0),
                        ),
                        // Inner inset-like shadow for tactile feel
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                // Bottom Subtle Emotion Glow
                Positioned(
                  bottom: -25,
                  left: 40,
                  right: 40,
                  height: 70,
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: (color ?? AppTheme.primaryColor).withOpacity(0.2),
                          blurRadius: 50,
                          spreadRadius: 15,
                        ),
                      ],
                    ),
                  ),
                ),
                // The actual content
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
