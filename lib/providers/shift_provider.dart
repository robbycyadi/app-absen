import 'package:flutter/foundation.dart';
import 'package:app_absen/models/shift_model.dart';
import 'package:app_absen/services/shift_service.dart';

class ShiftProvider extends ChangeNotifier {
  final ShiftService _shiftService = ShiftService();

  List<ShiftModel> _shifts = [];
  ShiftModel? _selectedShift;
  bool _isLoading = false;

  List<ShiftModel> get shifts => _shifts;
  ShiftModel? get selectedShift => _selectedShift;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> loadShifts() async {
    _setLoading(true);
    try {
      final data = await _shiftService.getAll();
      _shifts = data.map((e) => ShiftModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error loading shifts: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createShift(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      await _shiftService.create(data);
      await loadShifts();
      return true;
    } catch (e) {
      debugPrint('Error creating shift: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateShift(String id, Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      await _shiftService.update(id, data);
      await loadShifts();
      if (_selectedShift?.id == id) {
        final updated = _shifts.where((s) => s.id == id).firstOrNull;
        if (updated != null) {
          _selectedShift = updated;
        }
      }
      return true;
    } catch (e) {
      debugPrint('Error updating shift: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteShift(String id) async {
    _setLoading(true);
    try {
      await _shiftService.delete(id);
      if (_selectedShift?.id == id) {
        _selectedShift = null;
      }
      await loadShifts();
      return true;
    } catch (e) {
      debugPrint('Error deleting shift: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void selectShift(ShiftModel? shift) {
    _selectedShift = shift;
    notifyListeners();
  }

  ShiftModel? getEmployeeShift(String employeeId, DateTime date) {
    // Find shift assigned for this employee on this date
    // For simplicity, return the first available shift
    if (_shifts.isEmpty) return null;
    return _shifts.first;
  }

  Future<bool> assignShiftToEmployee(
      String employeeId, String shiftId, DateTime date) async {
    _setLoading(true);
    try {
      await _shiftService.create({
        'employee_id': employeeId,
        'shift_id': shiftId,
        'tanggal': date.toIso8601String().substring(0, 10),
      });
      return true;
    } catch (e) {
      debugPrint('Error assigning shift: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
