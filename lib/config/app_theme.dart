import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';

/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// FurSpeak AI — "Velvet Paw" Design System (V2)
///
/// Design Tokens are STRICTLY enforced:
///   Spacing: 8 / 12 / 16 / 24 (ONLY these values)
///   Border Radius: 16 / 24 (ONLY these values)
///   Animation Durations: 200ms / 400ms / 800ms (ONLY these values)
///
/// Rules:
///   - NO 1px solid borders for sectioning. Use background color shifts.
///   - Shadows use tinted periwinkle, NOT grey.
///   - Glassmorphism ONLY for Result cards & Emotion highlight panels.
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class AppTheme {
  AppTheme._(); // Non-instantiable

  // ─── 1. COLOR PALETTE ─────────────────────────────────────────────────
  static const Color bgColor = Color(0xFFFFFAF2); // Vanilla Cream
  static const Color primaryColor = Color(0xFF7E8CE0); // Soft Periwinkle
  static const Color accentColor = Color(0xFFFFB347); // Gentle Orange
  static const Color tertiaryColor = Color(0xFFFFE084); // Pastel Yellow
  static const Color successColor = Color(0xFF43E97B); // Mint Green
  static const Color errorColor = Color(0xFFF95F62); // Coral Red
  static const Color textColor = Color(0xFF2C2C2C); // Dark Gray (NOT pure black)
  static const Color textLightColor = Color(0xFF777777); // Stone Gray

  // Surface Hierarchy (Tonal Layering — "No-Line" Rule)
  static const Color surfaceBase = Color(0xFFF8F9FF);
  static const Color surfaceLow = Color(0xFFF0F3FD);
  static const Color surfaceActive = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFE5E8F1);

  // ─── 2. SPACING SCALE (STRICT — only these values allowed) ────────────
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space24 = 24.0;

  // ─── 3. BORDER RADII (STRICT — only these values allowed) ─────────────
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;

  static final BorderRadius borderRadiusMedium =
      BorderRadius.circular(radiusMedium);
  static final BorderRadius borderRadiusLarge =
      BorderRadius.circular(radiusLarge);
  static final BorderRadius borderRadiusPill =
      BorderRadius.circular(999);

  // ─── 4. ANIMATION DURATIONS (STRICT — only these values allowed) ──────
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animMedium = Duration(milliseconds: 400);
  static const Duration animSlow = Duration(milliseconds: 800);

  // ─── 5. SHADOWS (Periwinkle-tinted, NOT grey) ─────────────────────────
  /// Standard soft shadow for cards sitting on a surface.
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: primaryColor.withOpacity(0.06),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  /// Elevated floating shadow for modals and pet profile cards.
  static List<BoxShadow> get floatShadow => [
        BoxShadow(
          color: primaryColor.withOpacity(0.08),
          blurRadius: 40,
          offset: const Offset(0, 20),
        ),
      ];

  // ─── 6. GRADIENTS ─────────────────────────────────────────────────────
  /// Primary periwinkle gradient for CTAs (135° angle).
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4A58A8), Color(0xFF7E8CE0)],
  );

  /// Warm vanilla background gradient for hero sections.
  static const LinearGradient warmGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgColor, Color(0xFFFFF5E6)],
  );

  // ─── 7. TYPOGRAPHY (Poppins = Headings, Inter = Body) ─────────────────
  static final TextStyle headingStyle = GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textColor,
  );

  static final TextStyle subheadingStyle = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: textColor,
  );

  static final TextStyle titleStyle = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: textColor,
  );

  static final TextStyle bodyStyle = GoogleFonts.inter(
    fontSize: 16,
    color: textColor,
    height: 1.5,
  );

  static final TextStyle captionStyle = GoogleFonts.inter(
    fontSize: 14,
    color: textLightColor,
  );

  // ─── 8. BUTTON STYLES ─────────────────────────────────────────────────
  static final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    elevation: 0,
    shadowColor: primaryColor.withOpacity(0.3),
    shape: RoundedRectangleBorder(borderRadius: borderRadiusPill),
    textStyle: GoogleFonts.poppins(
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  );

  static final ButtonStyle accentButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: accentColor,
    foregroundColor: Colors.white,
    elevation: 0,
    shadowColor: accentColor.withOpacity(0.3),
    shape: RoundedRectangleBorder(borderRadius: borderRadiusPill),
    textStyle: GoogleFonts.poppins(
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  );

  static final ButtonStyle successButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: successColor,
    foregroundColor: Colors.white,
    elevation: 0,
    shadowColor: successColor.withOpacity(0.3),
    shape: RoundedRectangleBorder(borderRadius: borderRadiusPill),
    textStyle: GoogleFonts.poppins(
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  );

  // ─── 9. CARD DECORATION ───────────────────────────────────────────────
  static final BoxDecoration cardDecoration = BoxDecoration(
    color: surfaceActive,
    borderRadius: borderRadiusLarge,
    boxShadow: softShadow,
  );

  // ─── 10. INPUT DECORATION ─────────────────────────────────────────────
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
      fillColor: surfaceLow,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: space24,
        vertical: space16,
      ),
      labelStyle: GoogleFonts.inter(color: textLightColor, fontSize: 16),
      hintStyle: GoogleFonts.inter(
        color: textLightColor.withOpacity(0.5),
        fontSize: 16,
      ),
    );
  }

  // ─── 11. APPBAR THEME ─────────────────────────────────────────────────
  static AppBarTheme appBarTheme = AppBarTheme(
    backgroundColor: surfaceActive,
    elevation: 0,
    centerTitle: true,
    iconTheme: const IconThemeData(color: primaryColor),
    titleTextStyle: GoogleFonts.poppins(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: textColor,
    ),
  );

  // ─── 12. FULL THEME DATA ──────────────────────────────────────────────
  static ThemeData get theme => ThemeData(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: bgColor,
        appBarTheme: appBarTheme,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: primaryButtonStyle,
        ),
        textTheme: TextTheme(
          displayLarge: headingStyle,
          displayMedium: subheadingStyle,
          titleLarge: titleStyle,
          bodyLarge: bodyStyle,
          bodyMedium: captionStyle,
        ),
        colorScheme: const ColorScheme.light(
          primary: primaryColor,
          secondary: accentColor,
          tertiary: tertiaryColor,
          error: errorColor,
          surface: surfaceBase,
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

  const PetMoodGlass({
    super.key,
    required this.child,
    this.opacity = 0.6,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppTheme.borderRadiusLarge;
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceActive.withOpacity(opacity),
            borderRadius: radius,
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.08),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
