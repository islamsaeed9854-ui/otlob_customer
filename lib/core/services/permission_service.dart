import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:injectable/injectable.dart';

class PermissionPermanentlyDeniedException implements Exception {}

@lazySingleton
class PermissionService {
  Future<bool> requestPermission(Permission permission) async {
    final status = await permission.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      throw PermissionPermanentlyDeniedException();
    }

    final result = await permission.request();
    return result.isGranted;
  }

  Future<bool> requestGalleryPermission() async {
    if (Platform.isIOS) {
      return await requestPermission(Permission.photos);
    } else {
      final photoStatus = await Permission.photos.request();
      if (photoStatus.isGranted) return true;

      final storageStatus = await Permission.storage.request();
      if (storageStatus.isGranted) return true;

      if (photoStatus.isPermanentlyDenied ||
          storageStatus.isPermanentlyDenied) {
        throw PermissionPermanentlyDeniedException();
      }

      return false;
    }
  }

  Future<bool> openSettings() async {
    return await openAppSettings();
  }
}
