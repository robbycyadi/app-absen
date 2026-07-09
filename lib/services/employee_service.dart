import 'package:app_absen/config/supabase_config.dart';
import 'package:app_absen/models/user_model.dart';
import 'package:app_absen/models/position_model.dart';

class EmployeeService {
  final _client = SupabaseConfig.getSupabaseClient();

  Future<List<UserModel>> getAllEmployees() async {
    final data = await _client
        .from('profiles')
        .select('*, positions(*)')
        .order('created_at', ascending: false);

    if (data != null) {
      final list = data as List;
      return list
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<UserModel?> getEmployeeById(String id) async {
    try {
      final data = await _client
          .from('profiles')
          .select('*, positions(*)')
          .eq('id', id)
          .single();
      return UserModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<void> createEmployee(Map<String, dynamic> data) async {
    await _client.from('profiles').insert(data);
  }

  Future<void> updateEmployee(String id, Map<String, dynamic> data) async {
    await _client.from('profiles').update(data).eq('id', id);
  }

  Future<void> toggleActive(String id, bool isActive) async {
    await _client
        .from('profiles')
        .update({'is_active': isActive})
        .eq('id', id);
  }

  Future<List<PositionModel>> getAllPositions() async {
    final data = await _client
        .from('positions')
        .select('*')
        .order('nama_jabatan', ascending: true);

    if (data != null) {
      final list = data as List;
      return list
          .map((e) => PositionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
