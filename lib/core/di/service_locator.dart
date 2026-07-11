import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

// Import your schemas and services
import 'package:furspeak_ai/data/models/dog_profile.dart';
import 'package:furspeak_ai/data/models/detection_result.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:furspeak_ai/services/auth_service.dart';
import 'package:furspeak_ai/services/api_service.dart';
import 'package:furspeak_ai/services/result_storage_service.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  debugPrint("🟢 DI: Initializing Isar...");

  if (!getIt.isRegistered<Isar>()) {
    final dir = await getApplicationDocumentsDirectory();

    final isarInstance = await Isar.open(
      [DogProfileSchema, DetectionResultSchema],
      directory: dir.path,
    );

    getIt.registerSingleton<Isar>(isarInstance);
    debugPrint("🟢 DI: Isar initialized successfully");
  } else {
    debugPrint("🟢 DI: Isar already initialized");
  }

  // Register other services if they are not already registered
  if (!getIt.isRegistered<FirebaseAuth>()) {
    getIt.registerSingleton<FirebaseAuth>(FirebaseAuth.instance);
  }
  
  if (!getIt.isRegistered<FirebaseFirestore>()) {
    getIt.registerSingleton<FirebaseFirestore>(FirebaseFirestore.instance);
  }

  if (!getIt.isRegistered<AuthService>()) {
    getIt.registerSingleton<AuthService>(AuthService());
  }

  if (!getIt.isRegistered<ApiService>()) {
    final apiService = ApiService();
    await apiService.discoverAndValidateBackend();
    getIt.registerSingleton<ApiService>(apiService);
  }

  if (!getIt.isRegistered<ResultStorageService>()) {
    getIt.registerSingleton<ResultStorageService>(
      ResultStorageService(getIt<Isar>()),
    );
  }
}

Isar get isar => getIt<Isar>();

// Extension to make it easier to access services if desired
extension GetItExtension on GetIt {
  ApiService get api => get<ApiService>();
}
