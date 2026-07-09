import 'package:app_absen/config/supabase_config.dart';
import 'package:app_absen/models/overtime_model.dart';

class OvertimeService {
  final _client = SupabaseConfig.getSupabaseClient();

  Future<List<OvertimeModel>> getMyOvertimes(String employeeId) async {
    final data = await _client
        .from('overtimes')
        .select('*')
        .eq('employee_id', employeeId)
        .order('created_at', ascending: false);

    if (data != null) {
      final list = data as List;
      return list
          .map((e) => OvertimeModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<OvertimeModel>> getPendingApprovals() async {
    final data = await _client
        .from('overtimes')
        .select('*, profiles(nama_lengkap, nip)')
        .eq('is_approved', false)
        .order('created_at', ascending: false);

    if (data != null) {
      final list = data as List;
      return list
          .map((e) => OvertimeModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<void> submitOvertime(Map<String, dynamic> data) async {
    await _client.from('overtimes').insert(data);
  }

  Future<void> approveOvertime(String id) async {
    await _client
        .from('overtimes')
        .update({'is_approved': true})
        .eq('id', id);
  }

  Future<void> rejectOvertime(String id) async {
    await _client.from('overtimes').delete().eq('id', id);
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
