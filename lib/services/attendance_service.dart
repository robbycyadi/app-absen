import 'package:intl/intl.dart';
import 'package:app_absen/config/supabase_config.dart';
import 'package:app_absen/models/attendance_model.dart';

class AttendanceService {
  final _client = SupabaseConfig.getSupabaseClient();

  Future<AttendanceModel?> getTodayAttendance(
      String employeeId, String today) async {
    final response = await _client
        .from('attendances')
        .select('*')
        .eq('employee_id', employeeId)
        .eq('tanggal', today)
        .maybeSingle()
        .execute();

    if (response.data != null) {
      return AttendanceModel.fromJson(response.data as Map<String, dynamic>);
    }
    return null;
  }

  Future<List<AttendanceModel>> getHistory(
      String employeeId, int month, int year) async {
    final startDate = DateFormat('yyyy-MM-dd')
        .format(DateTime(year, month, 1));
    final endDate = DateFormat('yyyy-MM-dd')
        .format(DateTime(year, month + 1, 0));

    final response = await _client
        .from('attendances')
        .select('*')
        .eq('employee_id', employeeId)
        .gte('tanggal', startDate)
        .lte('tanggal', endDate)
        .order('tanggal', ascending: false)
        .execute();

    if (response.data != null) {
      final list = response.data as List;
      return list
          .map((e) => AttendanceModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<AttendanceModel?> createAttendance({
    required String employeeId,
    required String shiftId,
    required String fotoMasukUrl,
    required double latitudeMasuk,
    required double longitudeMasuk,
    String catatan = '',
  }) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final now = DateTime.now().toUtc().toIso8601String();

    final response = await _client.from('attendances').insert({
      'employee_id': employeeId,
      'tanggal': today,
      'shift_id': shiftId,
      'jam_masuk': now,
      'foto_masuk_url': fotoMasukUrl,
      'latitude_masuk': latitudeMasuk,
      'longitude_masuk': longitudeMasuk,
      'status': 'hadir',
      'catatan': catatan,
    }).select().single().execute();

    if (response.data != null) {
      return AttendanceModel.fromJson(response.data as Map<String, dynamic>);
    }
    return null;
  }

  Future<AttendanceModel?> updateAttendance({
    required String id,
    DateTime? jamKeluar,
    String? fotoKeluarUrl,
    double? latitudeKeluar,
    double? longitudeKeluar,
  }) async {
    final data = <String, dynamic>{};
    if (jamKeluar != null) {
      data['jam_keluar'] = jamKeluar.toUtc().toIso8601String();
    }
    if (fotoKeluarUrl != null) data['foto_keluar_url'] = fotoKeluarUrl;
    if (latitudeKeluar != null) data['latitude_keluar'] = latitudeKeluar;
    if (longitudeKeluar != null) data['longitude_keluar'] = longitudeKeluar;

    final response = await _client
        .from('attendances')
        .update(data)
        .eq('id', id)
        .select()
        .single()
        .execute();

    if (response.data != null) {
      return AttendanceModel.fromJson(response.data as Map<String, dynamic>);
    }
    return null;
  }
}
