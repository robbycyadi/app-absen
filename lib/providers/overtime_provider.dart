import 'package:flutter/foundation.dart';
import 'package:app_absen/models/overtime_model.dart';
import 'package:app_absen/services/overtime_service.dart';

class OvertimeProvider extends ChangeNotifier {
  final OvertimeService _overtimeService = OvertimeService();

  List<OvertimeModel> _myOvertimes = [];
  List<OvertimeModel> _pendingApprovals = [];
  bool _isLoading = false;

  List<OvertimeModel> get myOvertimes => _myOvertimes;
  List<OvertimeModel> get pendingApprovals => _pendingApprovals;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> loadMyOvertimes(String employeeId) async {
    _setLoading(true);
    try {
      _myOvertimes = await _overtimeService.getMyOvertimes(employeeId);
    } catch (e) {
      debugPrint('Error loading my overtimes: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadPendingOvertimeApprovals() async {
    _setLoading(true);
    try {
      _pendingApprovals =
          await _overtimeService.getPendingApprovals();
    } catch (e) {
      debugPrint('Error loading pending overtime approvals: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> submitOvertime(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      await _overtimeService.create(data);
      return true;
    } catch (e) {
      debugPrint('Error submitting overtime: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> approveOvertime(String id) async {
    _setLoading(true);
    try {
      await _overtimeService.approve(id);
      await loadPendingOvertimeApprovals();
      return true;
    } catch (e) {
      debugPrint('Error approving overtime: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> rejectOvertime(String id) async {
    _setLoading(true);
    try {
      await _overtimeService.reject(id);
      await loadPendingOvertimeApprovals();
      return true;
    } catch (e) {
      debugPrint('Error rejecting overtime: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  double calculateOvertimePay(double totalJam, double gajiPokok) {
    const double jamKerjaPerBulan = 173.0;
    final double upahPerJam = gajiPokok / jamKerjaPerBulan;

    double total = 0.0;
    double sisaJam = totalJam;

    if (sisaJam >= 1) {
      total += 1.5 * upahPerJam;
      sisaJam -= 1;
    }

    if (sisaJam > 0) {
      total += sisaJam * 2.0 * upahPerJam;
    }

    return total;
  }
}
