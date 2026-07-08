import 'package:app_absen/config/supabase_config.dart';
import 'package:app_absen/models/leave_model.dart';

class LeaveService {
  final _client = SupabaseConfig.getSupabaseClient();

  Future<List<LeaveRequestModel>> getMyLeaves(String employeeId) async {
    final response = await _client
        .from('leave_requests')
        .select('*')
        .eq('employee_id', employeeId)
        .order('created_at', ascending: false)
        .execute();

    if (response.data != null) {
      final list = response.data as List;
      return list
          .map((e) => LeaveRequestModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<LeaveRequestModel>> getPendingApprovals() async {
    final response = await _client
        .from('leave_requests')
        .select('*, profiles(nama_lengkap, nip)')
        .eq('status', 'pending')
        .order('created_at', ascending: false)
        .execute();

    if (response.data != null) {
      final list = response.data as List;
      return list
          .map((e) => LeaveRequestModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<void> submitLeave(Map<String, dynamic> data) async {
    await _client.from('leave_requests').insert(data).execute();
  }

  Future<void> approveLeave(String id, String catatan) async {
    await _client
        .from('leave_requests')
        .update({
          'status': 'approved',
          'catatan_approval': catatan,
        })
        .eq('id', id)
        .execute();
  }

  Future<void> rejectLeave(String id, String catatan) async {
    await _client
        .from('leave_requests')
        .update({
          'status': 'rejected',
          'catatan_approval': catatan,
        })
        .eq('id', id)
        .execute();
  }

  Future<int> getSisaCutiTahunan(String employeeId) async {
    final tahun = DateTime.now().year;
    final response = await _client
        .from('leave_requests')
        .select('total_hari')
        .eq('employee_id', employeeId)
        .eq('tipe_izin', 'cuti_tahunan')
        .eq('status', 'approved')
        .gte('tanggal_mulai', '$tahun-01-01')
        .lte('tanggal_mulai', '$tahun-12-31')
        .execute();

    if (response.data != null) {
      final list = response.data as List;
      int totalDigunakan = 0;
      for (var item in list) {
        totalDigunakan += item['total_hari'] as int;
      }
      return 12 - totalDigunakan;
    }
    return 12;
  }
}
