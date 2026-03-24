import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'media_service.g.dart';

@Riverpod(keepAlive: true)
MediaService mediaService(Ref ref) => MediaService();

class MediaService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickImage({required ImageSource source}) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    return picked != null ? File(picked.path) : null;
  }

  Future<List<File>> pickMultipleImages() async {
    final List<XFile> picked = await _picker.pickMultiImage(imageQuality: 80);
    return picked.map((f) => File(f.path)).toList();
  }

  Future<File?> pickVideo({required ImageSource source}) async {
    final XFile? picked = await _picker.pickVideo(
      source: source,
      maxDuration: const Duration(seconds: 60),
    );
    return picked != null ? File(picked.path) : null;
  }

  Future<List<File>> pickMultipleMedia() async {
    final List<XFile> picked = await _picker.pickMultipleMedia(imageQuality: 80);
    return picked.map((f) => File(f.path)).toList();
  }

  Future<File?> cropImage({required File imageFile}) async {
    final CroppedFile? cropped = await ImageCropper().cropImage(
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
    return cropped != null ? File(cropped.path) : null;
  }
}