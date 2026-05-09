import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// FurSpeak AI — App Typography
/// 
/// Part of the "Velvet Paw" Design System (V2).
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class AppTypography {
  AppTypography._();

  // Headings (Poppins)
  static final TextStyle h1 = GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  );

  static final TextStyle h2 = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );

  static final TextStyle h3 = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  );

  // Body (Inter)
  static final TextStyle body = GoogleFonts.inter(
    fontSize: 16,
    color: AppColors.text,
    height: 1.5,
  );

  static final TextStyle caption = GoogleFonts.inter(
    fontSize: 14,
    color: AppColors.textLight,
  );

  static final TextStyle buttonLabel = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );
}
