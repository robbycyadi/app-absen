import 'package:app_absen/config/supabase_config.dart';
import 'package:app_absen/models/overtime_model.dart';

class OvertimeService {
  final _client = SupabaseConfig.getSupabaseClient();

  Future<List<OvertimeModel>> getMyOvertimes(String employeeId) async {
    final response = await _client
        .from('overtimes')
        .select('*')
        .eq('employee_id', employeeId)
        .order('created_at', ascending: false)
        .execute();

    if (response.data != null) {
      final list = response.data as List;
      return list
          .map((e) => OvertimeModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<OvertimeModel>> getPendingApprovals() async {
    final response = await _client
        .from('overtimes')
        .select('*, profiles(nama_lengkap, nip)')
        .eq('is_approved', false)
        .order('created_at', ascending: false)
        .execute();

    if (response.data != null) {
      final list = response.data as List;
      return list
          .map((e) => OvertimeModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<void> submitOvertime(Map<String, dynamic> data) async {
    await _client.from('overtimes').insert(data).execute();
  }

  Future<void> approveOvertime(String id) async {
    await _client
        .from('overtimes')
        .update({'is_approved': true})
        .eq('id', id)
        .execute();
  }

  Future<void> rejectOvertime(String id) async {
    await _client.from('overtimes').delete().eq('id', id).execute();
  }

  double calculateOvertimePay(double totalJam, double gajiPokok) {
    final upahPerJam = gajiPokok / 173;
    double total = 0;

    if (totalJam <= 1) {
      total = totalJam * upahPerJam * 1.5;
    } else {
      total = (1 * upahPerJam * 1.5) + ((totalJam - 1) * upahPerJam * 2);
    }

    return total;
  }
}
