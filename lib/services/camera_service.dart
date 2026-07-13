import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:app_absen/config/platform_helper.dart';

class CameraService {
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> takePhoto({bool frontCamera = true}) async {
    if (PlatformHelper.isWeb) {
      return pickFromGallery();
    }
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
        preferredCameraDevice:
            frontCamera ? CameraDevice.front : CameraDevice.rear,
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

  Future<Uint8List> getImageBytes(XFile file) async {
    try {
      return await file.readAsBytes();
    } catch (e) {
      throw Exception('Failed to read image bytes: $e');
    }
  }
}
