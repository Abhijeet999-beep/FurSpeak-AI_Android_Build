import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:furspeak_ai/config/app_routes.dart';
import 'package:furspeak_ai/config/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:furspeak_ai/providers/auth_provider.dart';
import 'package:furspeak_ai/providers/dog_provider.dart';

import 'package:furspeak_ai/providers/home_pipeline_provider.dart';
import 'package:furspeak_ai/core/di/service_locator.dart';

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:furspeak_ai/media/services/media_orchestrator.dart';

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
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ MUST be first — ApiConfig.baseUrl reads dotenv synchronously
  await dotenv.load(fileName: '.env');
  debugPrint('✅ [INIT] .env loaded. ENVIRONMENT=${dotenv.env['ENVIRONMENT']} URL=${dotenv.env['LOCAL_API_URL']}');

  await Firebase.initializeApp(); // 🔥 Firebase init
  debugPrint('✅ [INIT] Firebase initialized');

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
      mediaOrchestrator.reset();
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