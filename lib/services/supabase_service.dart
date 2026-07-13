import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await SupabaseConfig.initialize();
    _initialized = true;
  }

  User? getCurrentUser() {
    return client.auth.currentUser;
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  Future<Map<String, dynamic>> getProfile(String userId) async {
    final data = await client
        .from('profiles')
        .select('*, positions(*)')
        .eq('id', userId)
        .single();
    return data;
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    await client
        .from('profiles')
        .update(data)
        .eq('id', userId);
  }

  Future<List<Map<String, dynamic>>> getAttendances({
    String? employeeId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    int? limit,
    int? offset,
  }) async {
    try {
      var query = client.from('attendances').select('*, shifts(*)') as dynamic;

      if (employeeId != null) {
        query = query.eq('employee_id', employeeId);
      }
      if (status != null) {
        query = query.eq('status', status);
      }
      if (startDate != null) {
        query = query.gte('tanggal', startDate.toIso8601String().split('T')[0]);
      }
      if (endDate != null) {
        query = query.lte('tanggal', endDate.toIso8601String().split('T')[0]);
      }
      if (limit != null) {
        query = query.limit(limit);
      }
      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 20) - 1);
      }

      query = query.order('tanggal', ascending: false);

      final data = await query;
      return (data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to fetch attendances: $e');
    }
  }

  Future<Map<String, dynamic>> insertAttendance(
      Map<String, dynamic> data) async {
    final result = await client.from('attendances').insert(data).select().single();
    return result;
  }

  Future<void> updateAttendance(String id, Map<String, dynamic> data) async {
    await client
        .from('attendances')
        .update(data)
        .eq('id', id);
  }

  Future<List<Map<String, dynamic>>> getShifts() async {
    final data = await client.from('shifts').select('*').order('jam_masuk');
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getPayrolls({
    required String employeeId,
    required int month,
    required int year,
  }) async {
    final data = await client
        .from('payrolls')
        .select('*')
        .eq('employee_id', employeeId)
        .eq('periode_bulan', month)
        .eq('periode_tahun', year);
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> calculatePayroll({
    required String employeeId,
    required int month,
    required int year,
  }) async {
    final data = await client.rpc('calculate_payroll', params: {
      'p_employee_id': employeeId,
      'p_bulan': month,
      'p_tahun': year,
    });
    return data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getLeaveRequests({
    String? employeeId,
    String? status,
    String? tipeIzin,
    int? limit,
    int? offset,
  }) async {
    try {
      var query = client.from('leave_requests').select('*, profiles!inner(*)') as dynamic;

      if (employeeId != null) {
        query = query.eq('employee_id', employeeId);
      }
      if (status != null) {
        query = query.eq('status', status);
      }
      if (tipeIzin != null) {
        query = query.eq('tipe_izin', tipeIzin);
      }
      if (limit != null) {
        query = query.limit(limit);
      }
      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 20) - 1);
      }

      query = query.order('created_at', ascending: false);

      final data = await query;
      return (data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to fetch leave requests: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getOvertimes({
    String? employeeId,
    DateTime? startDate,
    DateTime? endDate,
    bool? isApproved,
    int? limit,
    int? offset,
  }) async {
    try {
      var query = client.from('overtimes').select('*, profiles!inner(*)') as dynamic;

      if (employeeId != null) {
        query = query.eq('employee_id', employeeId);
      }
      if (isApproved != null) {
        query = query.eq('is_approved', isApproved);
      }
      if (startDate != null) {
        query = query.gte('tanggal', startDate.toIso8601String().split('T')[0]);
      }
      if (endDate != null) {
        query = query.lte('tanggal', endDate.toIso8601String().split('T')[0]);
      }
      if (limit != null) {
        query = query.limit(limit);
      }
      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 20) - 1);
      }

      query = query.order('created_at', ascending: false);

      final data = await query;
      return (data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to fetch overtimes: $e');
    }
  }

  Future<String> uploadFile({
    String? bucket,
    String? path,
    required Uint8List bytes,
  }) async {
    try {
      final storageBucket = bucket ?? 'attendance';
      final storagePath = path ?? 'uploads/${DateTime.now().millisecondsSinceEpoch}';

      await client.storage.from(storageBucket).uploadBinary(
            storagePath,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final url = client.storage.from(storageBucket).getPublicUrl(storagePath);
      return url;
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getGpsLocations() async {
    final data = await client
        .from('gps_locations')
        .select('*')
        .eq('is_active', true);
    return (data as List).cast<Map<String, dynamic>>();
  }
}
