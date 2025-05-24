import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:furspeak_ai/theme/app_theme.dart';
import 'package:furspeak_ai/theme/app_animations.dart';
import 'package:furspeak_ai/theme/app_accessibility.dart';
import 'package:furspeak_ai/config/app_routes.dart';
import 'package:furspeak_ai/config/supabase_config.dart';
import 'package:furspeak_ai/config/dependency_injection.dart';
import 'package:furspeak_ai/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Try to initialize everything, but never show technical errors
  await SupabaseConfig.initialize();
  await setupDependencies();
  final authService = AuthService();
  await authService.initialize();

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppTheme.background,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FurSpeak AI',
      theme: AppTheme.lightTheme,
      routerConfig: AppRoutes.router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Wrap the entire app with accessibility features
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: 1.0, // Prevent system font scaling
          ),
          child: child!,
        );
      },
    );
  }
}
