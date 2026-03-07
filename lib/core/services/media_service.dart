import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class MediaService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickImage({required ImageSource source}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      return pickedFile != null ? File(pickedFile.path) : null;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  Future<List<File>> pickMultipleImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 80,
      );

      return pickedFiles.map((file) => File(file.path)).toList();
    } catch (e) {
      throw Exception('Failed to pick multiple images: $e');
    }
  }

  Future<File?> pickVideo({required ImageSource source}) async {
    try {
      final XFile? pickedFile = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 60),
      );

      return pickedFile != null ? File(pickedFile.path) : null;
    } catch (e) {
      throw Exception('Failed to pick video: $e');
    }
  }

  Future<List<File>> pickMultipleMedia() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultipleMedia(
        imageQuality: 80,
      );

      return pickedFiles.map((file) => File(file.path)).toList();
    } catch (e) {
      throw Exception('Failed to pick multiple media: $e');
    }
  }

  Future<File?> cropImage({required File imageFile}) async {
    try {
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: const Color(0xFFFF5A00),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(title: 'Crop Image', aspectRatioLockEnabled: true),
        ],
      );

      return croppedFile != null ? File(croppedFile.path) : null;
    } catch (e) {
      throw Exception('Failed to crop image: $e');
    }
  }
}
