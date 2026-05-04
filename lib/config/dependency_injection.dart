import 'package:get_it/get_it.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:furspeak_ai/data/models/dog_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:furspeak_ai/services/auth_service.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [DogProfileSchema],
    directory: dir.path,
  );
  getIt.registerSingleton<Isar>(isar);
  getIt.registerSingleton<FirebaseAuth>(FirebaseAuth.instance);
  getIt.registerSingleton<FirebaseFirestore>(FirebaseFirestore.instance);
  getIt.registerSingleton<AuthService>(AuthService());
}
