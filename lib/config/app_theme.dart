import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color bgColor = Color(0xFFFFFAF2); // Vanilla Cream
  static const Color primaryColor = Color(0xFF7E8CE0); // Soft Periwinkle
  static const Color accentColor = Color(0xFFFFB347); // Gentle Orange
  static const Color tertiaryColor = Color(0xFFFFE084); // Pastel Yellow
  static const Color successColor = Color(0xFF43E97B); // Mint Green
  static const Color errorColor = Color(0xFFF95F62); // Coral Red
  static const Color textColor = Color(0xFF2C2C2C); // Dark Gray
  static const Color textLightColor = Color(0xFF777777); // Stone Gray

  // Text Styles
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

  // Button Styles
  static final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    elevation: 4,
    shadowColor: primaryColor.withOpacity(0.3),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    ),
    textStyle: GoogleFonts.poppins(
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  );

  static final ButtonStyle accentButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: accentColor,
    foregroundColor: Colors.white,
    elevation: 4,
    shadowColor: accentColor.withOpacity(0.3),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    ),
    textStyle: GoogleFonts.poppins(
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  );

  static final ButtonStyle successButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: successColor,
    foregroundColor: Colors.white,
    elevation: 4,
    shadowColor: successColor.withOpacity(0.3),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    ),
    textStyle: GoogleFonts.poppins(
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  );

  // Card Styles
  static final BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // Input Decoration
  static InputDecoration inputDecoration({
    required String label,
    String? hint,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      labelStyle: GoogleFonts.inter(
        color: textLightColor,
        fontSize: 16,
      ),
      hintStyle: GoogleFonts.inter(
        color: textLightColor.withOpacity(0.5),
        fontSize: 16,
      ),
    );
  }

  // AppBar Theme
  static AppBarTheme appBarTheme = AppBarTheme(
    backgroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
    iconTheme: const IconThemeData(color: primaryColor),
    titleTextStyle: GoogleFonts.poppins(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: textColor,
    ),
  );

  // Theme Data
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
          background: bgColor,
        ),
        useMaterial3: true,
      );
}
