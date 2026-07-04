import 'dart:io';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

enum MediaPermissionOutcome {
  granted,
  denied,
  permanentlyDenied,
}

/// 갤러리·카메라 접근 권한
///
/// iOS 14+ / Android 13+는 시스템 사진 피커가 권한 없이 동작할 수 있어
/// 갤러리는 피커 실패 시에만 재요청한다.
class PhotoPermissionService {
  PhotoPermissionService._();

  static bool _isUsable(PermissionStatus status) =>
      status.isGranted || status.isLimited;

  static bool isPermissionError(Object error) {
    if (error is PlatformException) {
      final code = error.code.toLowerCase();
      return code.contains('permission') ||
          code.contains('access_denied') ||
          code.contains('accessdenied') ||
          code == 'photo_access_denied' ||
          code == 'camera_access_denied';
    }
    final message = error.toString().toLowerCase();
    return message.contains('permission') ||
        message.contains('not authorized') ||
        message.contains('access denied');
  }

  /// Android만 사전 확인. iOS는 PHPicker가 권한을 처리한다.
  static Future<MediaPermissionOutcome> ensureGallery({
    bool requestIfNeeded = true,
  }) async {
    if (Platform.isIOS) {
      return MediaPermissionOutcome.granted;
    }
    if (!Platform.isAndroid) {
      return MediaPermissionOutcome.granted;
    }

    final permission = _androidGalleryPermission();
    var status = await permission.status;
    if (_isUsable(status)) {
      return MediaPermissionOutcome.granted;
    }

    if (!requestIfNeeded) {
      return _outcomeFromStatus(status);
    }

    await permission.request();
    status = await permission.status;
    if (_isUsable(status)) {
      return MediaPermissionOutcome.granted;
    }

    return _outcomeFromStatus(status);
  }

  static Future<MediaPermissionOutcome> ensureCamera() async {
    if (!_needsRuntimePermission) {
      return MediaPermissionOutcome.granted;
    }

    var status = await Permission.camera.status;
    if (_isUsable(status)) {
      return MediaPermissionOutcome.granted;
    }

    await Permission.camera.request();
    status = await Permission.camera.status;
    if (_isUsable(status)) {
      return MediaPermissionOutcome.granted;
    }

    return _outcomeFromStatus(status);
  }

  static Future<bool> openSettings() => openAppSettings();

  static Permission _androidGalleryPermission() {
    return Permission.photos;
  }

  static MediaPermissionOutcome _outcomeFromStatus(PermissionStatus status) {
    if (status.isPermanentlyDenied || status.isRestricted) {
      return MediaPermissionOutcome.permanentlyDenied;
    }
    return MediaPermissionOutcome.denied;
  }

  static bool get _needsRuntimePermission => Platform.isIOS || Platform.isAndroid;
}
