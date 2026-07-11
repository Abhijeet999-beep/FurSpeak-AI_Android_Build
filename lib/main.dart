import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';

import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:furspeak_ai/config/app_routes.dart';
import 'package:furspeak_ai/config/app_theme.dart';
import 'package:furspeak_ai/media/services/media_orchestrator.dart';
import 'package:furspeak_ai/config/api_config.dart';
import 'package:provider/provider.dart';
import 'package:furspeak_ai/providers/auth_provider.dart';
import 'package:furspeak_ai/providers/dog_provider.dart';
import 'package:furspeak_ai/providers/home_pipeline_provider.dart';
import 'package:furspeak_ai/core/di/service_locator.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

void _cleanupTempDirectoryAsynchronously() {
  getTemporaryDirectory().then((tempDir) {
    debugPrint('🧹 [CLEANUP] Starting temp directory sweep...');
    int deletedCount = 0;
    try {
      final now = DateTime.now();
      final threshold = const Duration(minutes: 15);
      final files = tempDir.listSync(recursive: false);
      
      for (var entity in files) {
        if (entity is File) {
          final name = p.basename(entity.path).toLowerCase();
          if (name.startsWith('compressed_') || name.startsWith('opt_img_') || name.startsWith('trim_') || name.startsWith('camera_')) {
            try {
              final stat = entity.statSync();
              if (now.difference(stat.modified) > threshold) {
                entity.deleteSync();
                deletedCount++;
              }
            } catch (_) {}
          }
        }
      }
      if (deletedCount > 0) {
        debugPrint('🧹 [CLEANUP] Sweep complete: deleted $deletedCount stale media temp files.');
      }
    } catch (e) {
      debugPrint('🧹 [CLEANUP] Sweep failed: $e');
    }
  }).catchError((_) {});
}

void main() async {
  if (kDebugMode) {
    enableFlutterDriverExtension();
    // Restoring default HttpOverrides to prevent the driver extension from blocking/hijacking
    // normal network connections (e.g. backend api requests) during local debug runs.
    HttpOverrides.global = null;
  }
  WidgetsFlutterBinding.ensureInitialized();


  // Load .env first to get Sentry DSN
  await dotenv.load(fileName: '.env');
  final dsn = dotenv.env['SENTRY_DSN'];

  if (dsn != null && dsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = dsn;
        options.tracesSampleRate = 0.5;
        options.environment = dotenv.env['ENVIRONMENT'] ?? 'production';
      },
      appRunner: () => _runAppWithProviders(),
    );
  } else {
    await _runAppWithProviders();
  }
}

Future<void> _runAppWithProviders() async {
  debugPrint('✅ [INIT] App Startup: ENVIRONMENT=${dotenv.env['ENVIRONMENT']}');
  debugPrint('✅ [API] Base URL: ${ApiConfig.baseUrl}');

  try {
    await Firebase.initializeApp(); // 🔥 Firebase init
    debugPrint('✅ [FIREBASE] Firebase initialized');
  } catch (e) {
    debugPrint('❌ [FIREBASE] Firebase initialization failed: $e');
  }

  // Initialize Firebase App Check for production security
  final bool disableAppCheck = dotenv.env['DISABLE_APP_CHECK'] == 'true';
  if (disableAppCheck) {
    debugPrint('⏩ [INIT] Firebase App Check skipped (disabled in .env)');
  } else {
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: kDebugMode 
            ? AndroidProvider.debug 
            : AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.deviceCheck,
      );
      debugPrint('✅ [INIT] Firebase App Check activated');
    } catch (e) {
      debugPrint('⚠️ [INIT] Firebase App Check failed to activate: $e');
    }
  }

  await setupDependencies(); // 🔥 DI Setup
  debugPrint('✅ [INIT] Dependencies ready');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DogProvider()),
        ChangeNotifierProvider(create: (_) => HomePipelineProvider()),
      ],
      child: const MyApp(),
    ),
  );
}


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final authProvider = context.read<AuthProvider>();
    _router = AppRoutes.createRouter(authProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cleanupTempDirectoryAsynchronously();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      MediaOrchestrator.instance.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'FurSpeak AI',
      theme: AppTheme.theme,
      routerConfig: _router,
    );
  }
}