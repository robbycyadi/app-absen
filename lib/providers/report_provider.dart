import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:app_absen/services/report_service.dart';

class ReportProvider extends ChangeNotifier {
  final ReportService _reportService = ReportService();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<File?> generateAttendanceReport(
      String employeeId, int month, int year) async {
    _setLoading(true);
    _setError(null);
    try {
      final file =
          await _reportService.generateAttendanceReport(employeeId, month, year);
      return file;
    } catch (e) {
      _setError('Gagal membuat laporan absensi: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<File?> generatePayrollSlip(String payrollId) async {
    _setLoading(true);
    _setError(null);
    try {
      final file = await _reportService.generatePayrollSlip(payrollId);
      return file;
    } catch (e) {
      _setError('Gagal membuat slip gaji: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<File?> generateAllPayrollsReport(int month, int year) async {
    _setLoading(true);
    _setError(null);
    try {
      final file =
          await _reportService.generateAllPayrollsReport(month, year);
      return file;
    } catch (e) {
      _setError('Gagal membuat laporan penggajian: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> shareReport(File file) async {
    _setLoading(true);
    _setError(null);
    try {
      await _reportService.shareFile(file);
      return true;
    } catch (e) {
      _setError('Gagal membagikan laporan: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
