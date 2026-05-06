import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

/// Centralized permission utility for FurSpeak AI.
///
/// Extracts the duplicated `checkAllMediaPermissions()` logic from
/// HomeScreen and CameraScreen into a single shared utility.
class PermissionUtils {
  PermissionUtils._();

  /// Checks whether all required media permissions (camera, microphone,
  /// and storage/media access) are granted.
  static Future<bool> checkAllMediaPermissions() async {
    final camera = await Permission.camera.status;
    final mic = await Permission.microphone.status;
    bool storage = false;

    if (Platform.isAndroid) {
      if (await Permission.storage.isGranted) {
        storage = true;
      } else if (await Permission.photos.isGranted) {
        storage = true;
      } else if (await Permission.mediaLibrary.isGranted) {
        storage = true;
      } else if (await Permission.manageExternalStorage.isGranted) {
        storage = true;
      } else if (await Permission.videos.isGranted) {
        storage = true;
      } else if (await Permission.audio.isGranted) {
        storage = true;
      } else if (await Permission.accessMediaLocation.isGranted) {
        storage = true;
      }
    } else {
      storage = await Permission.photos.isGranted;
    }

    return camera.isGranted && mic.isGranted && storage;
  }

  /// Requests all media-related permissions at once.
  static Future<void> requestMediaPermissions() async {
    final permissions = [
      Permission.camera,
      Permission.microphone,
      Permission.storage,
      Permission.photos,
      Permission.videos,
    ];
    await permissions.request();
  }

  /// Convenience: request + check in one call.
  static Future<bool> requestAndCheckMediaPermissions() async {
    await requestMediaPermissions();
    return checkAllMediaPermissions();
  }
}
