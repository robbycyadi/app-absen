import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_absen/config/supabase_config.dart';

class UploadService {
  final SupabaseClient _client = SupabaseConfig.getSupabaseClient();

  Future<String> uploadFile({
    required File file,
    required String bucket,
    required String path,
  }) async {
    final response = await _client.storage
        .from(bucket)
        .upload(path, file);

    if (response.error != null) {
      throw Exception('Upload gagal: ${response.error!.message}');
    }

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
