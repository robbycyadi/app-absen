import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app_absen/config/constants.dart';
import 'package:app_absen/config/platform_helper.dart';

class SelfieScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String address;

  const SelfieScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  @override
  State<SelfieScreen> createState() => _SelfieScreenState();
}

class _SelfieScreenState extends State<SelfieScreen>
    with WidgetsBindingObserver {
  bool _isPreviewMode = false;
  XFile? _capturedImage;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (PlatformHelper.isWeb) {
      _pickFromGalleryWeb();
    } else {
      _initCameraMobile();
    }
  }

  Future<void> _pickFromGalleryWeb() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _capturedImage = file;
          _imageBytes = bytes;
          _isPreviewMode = true;
        });
      } else {
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _initCameraMobile() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: AppConstants.selfieMaxWidth.toDouble(),
        maxHeight: AppConstants.selfieMaxHeight.toDouble(),
        imageQuality: AppConstants.selfieImageQuality.toInt(),
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _capturedImage = file;
          _imageBytes = bytes;
          _isPreviewMode = true;
        });
      } else {
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  void _retakePhoto() {
    setState(() {
      _capturedImage = null;
      _imageBytes = null;
      _isPreviewMode = false;
    });
    if (PlatformHelper.isWeb) {
      _pickFromGalleryWeb();
    } else {
      _initCameraMobile();
    }
  }

  void _usePhoto() {
    if (PlatformHelper.isWeb) {
      Navigator.of(context).pop(_capturedImage);
    } else {
      Navigator.of(context).pop(_capturedImage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(PlatformHelper.isWeb ? 'Pilih Foto' : 'Ambil Selfie'),
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isPreviewMode && _capturedImage != null) {
      return _buildPreview();
    }
    return _buildLoadingView();
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Memuat foto...',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Stack(
      children: [
        Positioned.fill(
          child: _imageBytes != null
              ? Image.memory(
                  _imageBytes!,
                  fit: BoxFit.contain,
                )
              : const SizedBox.shrink(),
        ),
        Positioned(
          top: 8,
          left: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.gps_fixed, color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.latitude.toStringAsFixed(6)}, ${widget.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  widget.address,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('dd MMM yyyy HH:mm:ss').format(DateTime.now()),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 48,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  'Ulang',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: _retakePhoto,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle),
                label: const Text(
                  'Gunakan',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onPressed: _usePhoto,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
