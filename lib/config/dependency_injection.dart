import 'package:get_it/get_it.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:furspeak_ai/data/models/emotion_history.dart';
import 'package:furspeak_ai/data/models/dog_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:furspeak_ai/services/auth_service.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [EmotionHistorySchema, DogProfileSchema],
    directory: dir.path,
  );
  getIt.registerSingleton<Isar>(isar);
  getIt.registerSingleton<SupabaseClient>(Supabase.instance.client);
  getIt.registerSingleton<AuthService>(AuthService());
}
