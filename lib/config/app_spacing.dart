import 'package:flutter/material.dart';

/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// FurSpeak AI — App Spacing & Tokens
/// 
/// Part of the "Velvet Paw" Design System (V2).
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class AppSpacing {
  AppSpacing._();

  // Spacing Scale (STRICT)
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;

  // Border Radii (STRICT)
  static const double r16 = 16.0;
  static const double r24 = 24.0;
  static const double r32 = 32.0;

  static final BorderRadius radius16 = BorderRadius.circular(r16);
  static final BorderRadius radius24 = BorderRadius.circular(r24);
  static final BorderRadius radius32 = BorderRadius.circular(r32);
  static final BorderRadius radiusPill = BorderRadius.circular(999);

  // Animation Durations (STRICT)
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animMedium = Duration(milliseconds: 400);
  static const Duration animSlow = Duration(milliseconds: 800);
}
