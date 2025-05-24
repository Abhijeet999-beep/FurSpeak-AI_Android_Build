import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static String get url {
    final envUrl = dotenv.env['SUPABASE_URL'];
    if (envUrl == null || envUrl.isEmpty) {
      throw Exception('SUPABASE_URL not found in .env file');
    }
    return envUrl;
  }

  static String get anonKey {
    final envKey = dotenv.env['SUPABASE_ANON_KEY'];
    if (envKey == null || envKey.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY not found in .env file');
    }
    return envKey;
  }

  static Future<void> initialize() async {
    try {
      await dotenv.load();
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
      );
    } catch (e) {
      throw Exception('Failed to initialize Supabase: $e');
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
}
