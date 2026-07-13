import 'dart:typed_data';
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

  Future<Uint8List?> generateAttendanceReport(
      String employeeId, int month, int year) async {
    _setLoading(true);
    _setError(null);
    try {
      final bytes = await _reportService.generateAttendanceReportPdf({}, [], month, year);
      return bytes;
    } catch (e) {
      _setError('Gagal membuat laporan absensi: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<Uint8List?> generatePayrollSlip(String payrollId) async {
    _setLoading(true);
    _setError(null);
    try {
      final bytes = await _reportService.generatePayrollSlipPdf({}, {});
      return bytes;
    } catch (e) {
      _setError('Gagal membuat slip gaji: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<Uint8List?> generateAllPayrollsReport(int month, int year) async {
    _setLoading(true);
    _setError(null);
    try {
      final bytes = await _reportService.generatePayrollSummaryExcel([], month, year);
      return bytes;
    } catch (e) {
      _setError('Gagal membuat laporan penggajian: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> shareReport(Uint8List bytes, String fileName) async {
    _setLoading(true);
    _setError(null);
    try {
      await _reportService.downloadOrShareReport(bytes, fileName);
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
