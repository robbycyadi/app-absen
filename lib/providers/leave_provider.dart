import 'package:flutter/foundation.dart';
import 'package:app_absen/models/leave_model.dart';
import 'package:app_absen/services/leave_service.dart';
import 'package:app_absen/services/attendance_service.dart';

class LeaveProvider extends ChangeNotifier {
  final LeaveService _leaveService = LeaveService();
  final AttendanceService _attendanceService = AttendanceService();

  List<LeaveRequestModel> _myLeaves = [];
  List<LeaveRequestModel> _pendingApprovals = [];
  bool _isLoading = false;

  List<LeaveRequestModel> get myLeaves => _myLeaves;
  List<LeaveRequestModel> get pendingApprovals => _pendingApprovals;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> loadMyLeaves(String employeeId) async {
    _setLoading(true);
    try {
      _myLeaves = await _leaveService.getMyLeaves(employeeId);
    } catch (e) {
      debugPrint('Error loading my leaves: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadPendingApprovals() async {
    _setLoading(true);
    try {
      _pendingApprovals =
          await _leaveService.getPendingApprovals();
    } catch (e) {
      debugPrint('Error loading pending approvals: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> submitLeave(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      await _leaveService.create(data);
      return true;
    } catch (e) {
      debugPrint('Error submitting leave: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> approveLeave(String id, String? catatan) async {
    _setLoading(true);
    try {
      await _leaveService.approve(id, catatan);
      await loadPendingApprovals();
      return true;
    } catch (e) {
      debugPrint('Error approving leave: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> rejectLeave(String id, String? catatan) async {
    _setLoading(true);
    try {
      await _leaveService.reject(id, catatan);
      await loadPendingApprovals();
      return true;
    } catch (e) {
      debugPrint('Error rejecting leave: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<int> getSisaCutiTahunan(String employeeId) async {
    try {
      final int defaultCuti = 12;
      final tahunIni = DateTime.now().year;
      final cutiTerpakai =
          await _attendanceService.getCutiCount(employeeId, tahunIni);
      return defaultCuti - cutiTerpakai;
    } catch (e) {
      debugPrint('Error calculating remaining leave: $e');
      return 0;
    }
  }
}
