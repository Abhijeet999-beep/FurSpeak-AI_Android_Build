import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/emotion_response.dart';
import 'dart:io';

part 'furspeak_api.g.dart';

const String apiBaseUrl =
    "http://127.0.0.1:8000/";

@RestApi(
    baseUrl:
        "http://192.168.31.195:8000/")
abstract class FurSpeakApi {
  factory FurSpeakApi(Dio dio, {String baseUrl}) = _FurSpeakApi;

  @POST("detect/")
  @MultiPart()
  Future<EmotionResponse> detectEmotion(
    @Part(name: 'file') File file,
  );

  @POST("api/v1/auth/token")
  Future<TokenResponse> getAccessToken();
}

class TokenResponse {
  final String accessToken;
  final String tokenType;

  TokenResponse({
    required this.accessToken,
    required this.tokenType,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) => TokenResponse(
        accessToken: json['access_token'] as String,
        tokenType: json['token_type'] as String,
      );
}
