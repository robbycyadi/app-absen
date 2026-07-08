import 'package:app_absen/config/supabase_config.dart';
import 'package:app_absen/models/user_model.dart';
import 'package:app_absen/models/position_model.dart';

class EmployeeService {
  final _client = SupabaseConfig.getSupabaseClient();

  Future<List<UserModel>> getAllEmployees() async {
    final response = await _client
        .from('profiles')
        .select('*, positions(*)')
        .order('created_at', ascending: false)
        .execute();

    if (response.data != null) {
      final list = response.data as List;
      return list
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<UserModel?> getEmployeeById(String id) async {
    final response = await _client
        .from('profiles')
        .select('*, positions(*)')
        .eq('id', id)
        .single()
        .execute();

    if (response.data != null) {
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> createEmployee(Map<String, dynamic> data) async {
    await _client.from('profiles').insert(data).execute();
  }

  Future<void> updateEmployee(String id, Map<String, dynamic> data) async {
    await _client.from('profiles').update(data).eq('id', id).execute();
  }

  Future<void> toggleActive(String id, bool isActive) async {
    await _client
        .from('profiles')
        .update({'is_active': isActive})
        .eq('id', id)
        .execute();
  }

  Future<List<PositionModel>> getAllPositions() async {
    final response = await _client
        .from('positions')
        .select('*')
        .order('nama_jabatan', ascending: true)
        .execute();

    if (response.data != null) {
      final list = response.data as List;
      return list
          .map((e) => PositionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
