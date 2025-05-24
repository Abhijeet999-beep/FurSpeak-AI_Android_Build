import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

const String apiBaseUrl =
    'https://f40f-2409-40e3-180-2cd9-ac9a-ae4b-86c1-7254.ngrok-free.app';

class EmotionService {
  static Future<Map<String, dynamic>> analyzeEmotion(File imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${apiBaseUrl}/detect/'),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = json.decode(responseBody);
      debugPrint('EmotionService.analyzeEmotion returning: ' + data.toString());
      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception('Failed to analyze emotion: \\${data['error']}');
      }
    } catch (e) {
      throw Exception('Error analyzing emotion: $e');
    }
  }
}
