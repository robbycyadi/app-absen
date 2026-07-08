import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_absen/models/user_model.dart';
import 'package:app_absen/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isLoggedIn = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _isLoggedIn;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> checkAuthState() async {
    _setLoading(true);
    _setError(null);
    try {
      final session = _authService.getSession();
      if (session != null && session.user != null) {
        final userData = await _authService.getCurrentUser(session.user!.id);
        if (userData != null) {
          _currentUser = userData;
          _isLoggedIn = true;
        }
      } else {
        _currentUser = null;
        _isLoggedIn = false;
      }
    } catch (e) {
      _isLoggedIn = false;
      _currentUser = null;
      _errorMessage = 'Gagal memeriksa status login: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await _authService.signIn(email, password);
      final user = response.user;
      if (user == null) {
        _errorMessage = 'Email atau password salah';
        return false;
      }
      final userData = await _authService.getCurrentUser(user.id);
      if (userData != null) {
        _currentUser = userData;
        _isLoggedIn = true;
        return true;
      } else {
        _errorMessage = 'Profil pengguna tidak ditemukan';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Login gagal: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String namaLengkap,
    required String nip,
    required String positionId,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await _authService.signUp(email, password);
      final user = response.user;
      if (user == null) {
        _errorMessage = 'Gagal mendaftarkan akun';
        return false;
      }
      await _authService.createProfile(
        userId: user.id,
        email: email,
        namaLengkap: namaLengkap,
        nip: nip,
        positionId: positionId,
      );
      final userData = await _authService.getCurrentUser(user.id);
      if (userData != null) {
        _currentUser = userData;
        _isLoggedIn = true;
        return true;
      }
      return true;
    } catch (e) {
      _errorMessage = 'Pendaftaran gagal: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _currentUser = null;
      _isLoggedIn = false;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Logout gagal: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _setLoading(true);
    _setError(null);
    try {
      if (_currentUser == null) {
        _errorMessage = 'Tidak ada pengguna yang login';
        return false;
      }
      await _authService.updateProfile(_currentUser!.id, data);
      final updated = await _authService.getCurrentUser(_currentUser!.id);
      if (updated != null) {
        _currentUser = updated;
      }
      return true;
    } catch (e) {
      _errorMessage = 'Gagal memperbarui profil: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  String getUserRole() {
    if (_currentUser == null) return '';
    return _currentUser!.role.toString();
  }

  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _setError(null);
    try {
      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      _errorMessage = 'Gagal mengirim email reset password: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
