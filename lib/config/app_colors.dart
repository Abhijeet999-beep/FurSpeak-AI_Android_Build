import 'package:flutter/material.dart';

/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// FurSpeak AI — App Colors
/// 
/// Part of the "Velvet Paw" Design System (V2).
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class AppColors {
  AppColors._();

  // Core Palette
  static const Color vanillaCream = Color(0xFFFFFAF2);
  static const Color softPeriwinkle = Color(0xFF7E8CE0);
  static const Color primaryDark = Color(0xFF4A58A8);
  static const Color gentleOrange = Color(0xFFFFB347);
  static const Color pastelYellow = Color(0xFFFFE084);
  static const Color mintGreen = Color(0xFF43E97B);
  static const Color coralRed = Color(0xFFF95F62);
  static const Color darkGray = Color(0xFF181C22);
  static const Color stoneGray = Color(0xFF454651);

  // Semantic Aliases
  static const Color bg = vanillaCream;
  static const Color primary = softPeriwinkle;
  static const Color accent = gentleOrange;
  static const Color tertiary = pastelYellow;
  static const Color success = mintGreen;
  static const Color error = coralRed;
  static const Color text = darkGray;
  static const Color textLight = stoneGray;

  // Surface Hierarchy (Tonal Layering — "No-Line" Rule)
  static const Color surfaceBase = Color(0xFFF8F9FF);
  static const Color surfaceLow = Color(0xFFF0F3FD);
  static const Color surfaceActive = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFE5E8F1);
  static const Color surfaceBright = Color(0xFFFFFFFF);
  
  // New Tonal Layers for Depth
  static const Color surfaceContainerLow = Color(0xFFF0F3FD);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerHigh = Color(0xFFE5E8F1);

  // Glows & Accents
  static Color primaryGlow = softPeriwinkle.withOpacity(0.3);
  static Color accentGlow = gentleOrange.withOpacity(0.3);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, softPeriwinkle],
  );

  static const LinearGradient warmGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [vanillaCream, Color(0xFFFFF5E6)],
  );

  // Mesh Gradient Colors (Organic depth)
  static const List<Color> meshColors = [
    Color(0xFFFFFAF2),
    Color(0xFFF0F3FD),
    Color(0xFFE8EAF6),
  ];
}
