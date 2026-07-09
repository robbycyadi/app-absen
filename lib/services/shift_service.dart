import 'package:app_absen/config/supabase_config.dart';

class ShiftService {
  final _client = SupabaseConfig.getSupabaseClient();

  Future<List<Map<String, dynamic>>> getAll() async {
    final data = await _client
        .from('shifts')
        .select('*')
        .order('jam_masuk', ascending: true);
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<void> create(Map<String, dynamic> data) async {
    await _client.from('shifts').insert(data);
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    await _client.from('shifts').update(data).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _client.from('shifts').delete().eq('id', id);
  }
}
