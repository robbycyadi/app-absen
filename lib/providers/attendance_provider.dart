import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:app_absen/models/attendance_model.dart';
import 'package:app_absen/services/attendance_service.dart';
import 'package:app_absen/services/upload_service.dart';

class AttendanceProvider extends ChangeNotifier {
  final AttendanceService _attendanceService = AttendanceService();
  final UploadService _uploadService = UploadService();

  List<AttendanceModel> _todayAttendances = [];
  List<AttendanceModel> _history = [];
  AttendanceModel? _todayAttendance;
  bool _isLoading = false;
  String? _error;

  List<AttendanceModel> get todayAttendances => _todayAttendances;
  List<AttendanceModel> get history => _history;
  AttendanceModel? get todayAttendance => _todayAttendance;
  bool get isLoading => _isLoading;
  String? get error => _error;

  static const double _maxRadiusMeters = 200.0;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _error = message;
    notifyListeners();
  }

  Future<void> loadTodayAttendance(String employeeId) async {
    _setLoading(true);
    _setError(null);
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final data =
          await _attendanceService.getTodayAttendance(employeeId, today);
      _todayAttendance = data;
      _todayAttendances = data != null ? [data] : [];
    } catch (e) {
      _error = 'Gagal memuat absensi hari ini: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadHistory(
      String employeeId, int month, int year) async {
    _setLoading(true);
    _setError(null);
    try {
      _history =
          await _attendanceService.getHistory(employeeId, month, year);
    } catch (e) {
      _error = 'Gagal memuat riwayat absensi: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<AttendanceModel?> checkIn({
    required String employeeId,
    required String shiftId,
    required Uint8List photoBytes,
    required double latitude,
    required double longitude,
    required String locationName,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final photoUrl = await _uploadService.uploadFile(
        bucket: 'attendance',
        path: 'checkin/$employeeId/${DateTime.now().millisecondsSinceEpoch}',
        bytes: photoBytes,
      );

      final attendance = await _attendanceService.createAttendance(
        employeeId: employeeId,
        shiftId: shiftId,
        fotoMasukUrl: photoUrl,
        latitudeMasuk: latitude,
        longitudeMasuk: longitude,
        catatan: locationName,
      );

      _todayAttendance = attendance;
      _todayAttendances = attendance != null ? [attendance] : [];
      return attendance;
    } catch (e) {
      _error = 'Gagal melakukan check-in: $e';
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<AttendanceModel?> checkOut({
    required String employeeId,
    required Uint8List photoBytes,
    required double latitude,
    required double longitude,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      if (_todayAttendance == null) {
        _error = 'Belum melakukan check-in hari ini';
        return null;
      }

      final photoUrl = await _uploadService.uploadFile(
        bucket: 'attendance',
        path: 'checkout/$employeeId/${DateTime.now().millisecondsSinceEpoch}',
        bytes: photoBytes,
      );

      final updated = await _attendanceService.updateAttendance(
        id: _todayAttendance!.id,
        jamKeluar: DateTime.now(),
        fotoKeluarUrl: photoUrl,
        latitudeKeluar: latitude,
        longitudeKeluar: longitude,
      );

      if (updated != null) {
        _todayAttendance = updated;
        _todayAttendances = [updated];
      }
      return updated;
    } catch (e) {
      _error = 'Gagal melakukan check-out: $e';
      return null;
    } finally {
      _setLoading(false);
    }
  }

  String getAttendanceStatus() {
    if (_todayAttendance == null) return 'Belum Absen';
    switch (_todayAttendance!.status) {
      case AttendanceStatus.hadir:
        return 'Hadir';
      case AttendanceStatus.izin:
        return 'Izin';
      case AttendanceStatus.cuti:
        return 'Cuti';
      case AttendanceStatus.alpha:
        return 'Alpha';
      case AttendanceStatus.telat:
        return 'Telat';
    }
  }

  bool isWithinRadius(double empLat, double empLon) {
    try {
      const double officeLat = -6.2088;
      const double officeLon = 106.8456;

      final distance = Geolocator.distanceBetween(
        empLat,
        empLon,
        officeLat,
        officeLon,
      );
      return distance <= _maxRadiusMeters;
    } catch (e) {
      _error = 'Gagal memeriksa radius: $e';
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
