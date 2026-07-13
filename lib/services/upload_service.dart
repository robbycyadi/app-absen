import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_absen/config/supabase_config.dart';

class UploadService {
  final SupabaseClient _client = SupabaseConfig.getSupabaseClient();

  Future<String> uploadFile({
    required String bucket,
    required String path,
    required Uint8List bytes,
  }) async {
    await _client.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );

    final url = _client.storage.from(bucket).getPublicUrl(path);
    return url;
  }

  Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    await _client.storage.from(bucket).remove([path]);
  }
}
