import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const String appName = 'FurSpeak AI';
  static const String appVersion = '1.0.0';

  // API Endpoints
  static const String apiBaseUrl =
      'https://f40f-2409-40e3-180-2cd9-ac9a-ae4b-86c1-7254.ngrok-free.app';
  static const String predictEndpoint = '/detect/';
  static const String historyEndpoint = '/history';

  // Theme Colors
  static const Color primaryColor = Color(0xFF5A5BD9); // Sky Indigo
  static const Color secondaryColor = Color(0xFFFFA726); // Citrus Orange
  static const Color tertiaryColor = Color(0xFFFFD85C); // Soft Amber
  static const Color successColor = Color(0xFF43E97B); // Fresh Mint
  static const Color warningColor = Color(0xFFFFCC33); // Honey Yellow
  static const Color errorColor = Color(0xFFF95F62); // Coral Red
  static const Color infoColor = Color(0xFF3EDBF0); // Aqua Blue
  static const Color backgroundColor = Color(0xFFFFFCF5); // Creamy White
  static const Color surfaceColor = Colors.white;
  static const Color textPrimaryColor = Color(0xFF2C2C2C); // Charcoal Gray
  static const Color textSecondaryColor = Color(0xFF777777); // Stone Gray

  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: tertiaryColor,
      error: errorColor,
      background: backgroundColor,
      surface: surfaceColor,
      onPrimary: Colors.white,
      onSecondary: textPrimaryColor,
      onTertiary: textPrimaryColor,
      onError: Colors.white,
    ),
    textTheme: GoogleFonts.poppinsTextTheme().copyWith(
      headlineLarge: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
      headlineMedium: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
      ),
      bodyLarge: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textSecondaryColor,
      ),
      bodyMedium: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textSecondaryColor,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontFamily: 'Poppins',
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(
        color: textSecondaryColor,
        fontSize: 14,
        fontFamily: 'Poppins',
      ),
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: backgroundColor,
      selectedColor: tertiaryColor,
      secondarySelectedColor: successColor,
      disabledColor: textSecondaryColor.withOpacity(0.2),
      labelStyle: const TextStyle(color: textPrimaryColor),
      secondaryLabelStyle: const TextStyle(color: textPrimaryColor),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    switchTheme: SwitchThemeData(
      trackColor: MaterialStateProperty.all(tertiaryColor),
      thumbColor: MaterialStateProperty.all(secondaryColor),
    ),
    dividerColor: textSecondaryColor.withOpacity(0.2),
  );

  // Dark Theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: tertiaryColor,
      error: errorColor,
      background: const Color(0xFF121212),
      surface: const Color(0xFF1E1E1E),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onTertiary: Colors.white,
      onError: Colors.white,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
    ),
  );

  static const String _showOnboardingKey = 'show_onboarding';

  static Future<void> setShowOnboarding(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showOnboardingKey, show);
  }

  static Future<bool> getShowOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showOnboardingKey) ?? true;
  }
}
