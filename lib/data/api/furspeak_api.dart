import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/emotion_response.dart';
import 'dart:io';

part 'furspeak_api.g.dart';

const String apiBaseUrl =
    "https://f40f-2409-40e3-180-2cd9-ac9a-ae4b-86c1-7254.ngrok-free.app/";

@RestApi(
    baseUrl:
        "https://f40f-2409-40e3-180-2cd9-ac9a-ae4b-86c1-7254.ngrok-free.app/")
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
