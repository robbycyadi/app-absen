import 'package:flutter/foundation.dart';
import 'package:app_absen/models/user_model.dart';
import 'package:app_absen/services/employee_service.dart';

class EmployeeProvider extends ChangeNotifier {
  final EmployeeService _employeeService = EmployeeService();

  List<UserModel> _employees = [];
  UserModel? _selectedEmployee;
  bool _isLoading = false;

  List<UserModel> get employees => _employees;
  UserModel? get selectedEmployee => _selectedEmployee;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> loadAllEmployees() async {
    _setLoading(true);
    try {
      _employees = await _employeeService.getAllEmployees();
    } catch (e) {
      debugPrint('Error loading employees: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadEmployeeDetail(String id) async {
    _setLoading(true);
    try {
      _selectedEmployee = await _employeeService.getEmployeeById(id);
    } catch (e) {
      debugPrint('Error loading employee detail: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createEmployee(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      await _employeeService.createEmployee(data);
      await loadAllEmployees();
      return true;
    } catch (e) {
      debugPrint('Error creating employee: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateEmployee(String id, Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      await _employeeService.updateEmployee(id, data);
      if (_selectedEmployee?.id == id) {
        await loadEmployeeDetail(id);
      }
      await loadAllEmployees();
      return true;
    } catch (e) {
      debugPrint('Error updating employee: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> toggleActive(String id) async {
    _setLoading(true);
    try {
      final employee = _employees.where((e) => e.id == id).firstOrNull;
      await _employeeService.toggleActive(id, !(employee?.isActive ?? true));
      if (_selectedEmployee?.id == id) {
        await loadEmployeeDetail(id);
      }
      await loadAllEmployees();
      return true;
    } catch (e) {
      debugPrint('Error toggling employee active status: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
