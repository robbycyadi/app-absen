import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_absen/config/supabase_config.dart';
import 'package:app_absen/models/user_model.dart';

class AuthService {
  final SupabaseClient _client = SupabaseConfig.getSupabaseClient();

  Future<Session?> getSession() async {
    return _client.auth.currentSession;
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp(String email, String password) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<UserModel?> getCurrentUser(String userId) async {
    final response = await _client
        .from('profiles')
        .select('*, positions(*)')
        .eq('id', userId)
        .single()
        .execute();

    if (response.data != null) {
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> createProfile({
    required String userId,
    required String email,
    required String namaLengkap,
    required String nip,
    required String positionId,
  }) async {
    await _client.from('profiles').insert({
      'id': userId,
      'email': email,
      'nama_lengkap': namaLengkap,
      'nip': nip,
      'position_id': positionId,
      'role': 'karyawan',
    }).execute();
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    await _client
        .from('profiles')
        .update(data)
        .eq('id', userId)
        .execute();
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }
}
