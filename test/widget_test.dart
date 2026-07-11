import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core_platform_interface/src/pigeon/mocks.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:furspeak_ai/main.dart';
import 'package:furspeak_ai/providers/auth_provider.dart';
import 'package:furspeak_ai/providers/dog_provider.dart';
import 'package:furspeak_ai/providers/home_pipeline_provider.dart';

class FontHttpOverrides extends HttpOverrides {
  final List<int> fontBytes;
  FontHttpOverrides(this.fontBytes);

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return MockHttpClient(fontBytes);
  }
}

class MockHttpClient implements HttpClient {
  final List<int> fontBytes;
  MockHttpClient(this.fontBytes);

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return MockHttpClientRequest(fontBytes);
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return MockHttpClientRequest(fontBytes);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockHttpClientRequest implements HttpClientRequest {
  final List<int> fontBytes;
  MockHttpClientRequest(this.fontBytes);

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  bool persistentConnection = true;

  @override
  int contentLength = 0;

  @override
  Encoding encoding = utf8;

  @override
  final headers = MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async {
    return MockHttpClientResponse(fontBytes);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockHttpHeaders implements HttpHeaders {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockHttpClientResponse implements HttpClientResponse {
  final List<int> fontBytes;
  MockHttpClientResponse(this.fontBytes);

  @override
  int get statusCode => 200;

  @override
  int get contentLength => fontBytes.length;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([fontBytes]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
    SharedPreferences.setMockInitialValues({});
    
    // Set up HttpOverrides to serve local font bytes for GoogleFonts fetching
    final fontBytes = File('assets/fonts/Poppins-Regular.ttf').readAsBytesSync();
    HttpOverrides.global = FontHttpOverrides(fontBytes);

    // Mock permission_handler MethodChannel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'checkPermissionStatus') {
          return 1; // PermissionStatus.granted
        }
        return null;
      },
    );

    // Mock FirebaseAuth Pigeon channels
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockDecodedMessageHandler(
      const BasicMessageChannel(
        'dev.flutter.pigeon.firebase_auth_platform_interface.FirebaseAuthHostApi.registerIdTokenListener',
        StandardMessageCodec(),
      ),
      (message) async => null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockDecodedMessageHandler(
      const BasicMessageChannel(
        'dev.flutter.pigeon.firebase_auth_platform_interface.FirebaseAuthHostApi.registerAuthStateListener',
        StandardMessageCodec(),
      ),
      (message) async => null,
    );
  });

  testWidgets('FurSpeak AI smoke test', (WidgetTester tester) async {
    await tester.runAsync(() async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => DogProvider()),
            ChangeNotifierProvider(create: (_) => HomePipelineProvider()),
          ],
          child: const MyApp(),
        ),
      );

      // Let the initial frame build
      await tester.pump();

      // Verify that the app title is displayed
      expect(find.text('FurSpeak AI'), findsOneWidget);
    });
  });
}
