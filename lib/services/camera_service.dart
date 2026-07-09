import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart' show Color;
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

class CameraService {
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> takePhoto({CameraDevice device = CameraDevice.rear}) async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
        preferredCameraDevice: device,
      );
      return file;
    } catch (e) {
      throw Exception('Failed to take photo: $e');
    }
  }

  Future<XFile?> pickFromGallery() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      return file;
    } catch (e) {
      throw Exception('Failed to pick from gallery: $e');
    }
  }

  Future<CroppedFile?> cropImage(XFile file,
      {CropAspectRatio? aspectRatio}) async {
    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: file.path,
        aspectRatio: aspectRatio,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Color(0xFF2196F3),
            statusBarColor: Color(0xFF1976D2),
            activeControlsWidgetColor: Color(0xFF2196F3),
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioLockEnabled: aspectRatio != null,
            resetAspectRatioEnabled: aspectRatio == null,
          ),
        ],
      );
      return cropped;
    } catch (e) {
      throw Exception('Failed to crop image: $e');
    }
  }

  Future<Uint8List> getImageBytes(XFile file) async {
    try {
      return await file.readAsBytes();
    } catch (e) {
      throw Exception('Failed to read image bytes: $e');
    }
  }

  Future<File> compressImage(XFile file, {int quality = 70}) async {
    try {
      final bytes = await file.readAsBytes();
      final original = File(file.path);
      await original.writeAsBytes(bytes);
      return original;
    } catch (e) {
      throw Exception('Failed to compress image: $e');
    }
  }
}
