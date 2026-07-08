import 'package:flutter/foundation.dart';
import 'package:app_absen/models/payroll_model.dart';
import 'package:app_absen/models/position_model.dart';
import 'package:app_absen/services/payroll_service.dart';
import 'package:app_absen/services/employee_service.dart';

class PayrollProvider extends ChangeNotifier {
  final PayrollService _payrollService = PayrollService();
  final EmployeeService _employeeService = EmployeeService();

  List<PayrollModel> _myPayrolls = [];
  List<PayrollModel> _allPayrolls = [];
  PayrollModel? _selectedPayroll;
  bool _isLoading = false;

  List<PayrollModel> get myPayrolls => _myPayrolls;
  List<PayrollModel> get allPayrolls => _allPayrolls;
  PayrollModel? get selectedPayroll => _selectedPayroll;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> loadMyPayrolls(String employeeId, int tahun) async {
    _setLoading(true);
    try {
      _myPayrolls = await _payrollService.getMyPayrolls(employeeId, tahun);
    } catch (e) {
      debugPrint('Error loading my payrolls: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadAllPayrolls(int bulan, int tahun) async {
    _setLoading(true);
    try {
      _allPayrolls = await _payrollService.getAllPayrolls(bulan, tahun);
    } catch (e) {
      debugPrint('Error loading all payrolls: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<PayrollModel?> calculatePayroll(
      String employeeId, int bulan, int tahun) async {
    _setLoading(true);
    try {
      final employee = await _employeeService.getById(employeeId);
      if (employee == null) {
        debugPrint('Employee not found');
        return null;
      }

      final position = await _employeeService.getPosition(employee.positionId);
      if (position == null) {
        debugPrint('Position not found');
        return null;
      }

      final totalLembur =
          await _payrollService.getTotalLembur(employeeId, bulan, tahun);

      final thr = (bulan == 6 || bulan == 12) ? position.gajiPokok : 0.0;

      final totalLemburRp =
          _calculateLemburRp(totalLembur, position.gajiPokok);

      final totalPendapatan = position.gajiPokok +
          position.tunjanganTetap +
          position.uangMakan +
          position.uangTransport +
          totalLemburRp +
          thr;

      final bpjsKesehatan = position.gajiPokok * 0.01;
      final bpjsJHT = position.gajiPokok * 0.02;
      final bpjsJP = position.gajiPokok * 0.01;
      final bpjsJKK = position.gajiPokok * 0.0054;
      final bpjsJKM = position.gajiPokok * 0.003;

      final potonganKaryawan = bpjsKesehatan + bpjsJHT + bpjsJP;
      final gajiBersih = totalPendapatan - potonganKaryawan;

      final payroll = PayrollModel(
        id: '',
        employeeId: employeeId,
        namaKaryawan: employee.namaLengkap,
        bulan: bulan,
        tahun: tahun,
        gajiPokok: position.gajiPokok,
        tunjanganTetap: position.tunjanganTetap,
        uangMakan: position.uangMakan,
        uangTransport: position.uangTransport,
        lembur: totalLemburRp,
        thr: thr,
        bpjsKesehatan: bpjsKesehatan,
        bpjsJHT: bpjsJHT,
        bpjsJP: bpjsJP,
        bpjsJKK: bpjsJKK,
        bpjsJKM: bpjsJKM,
        totalPendapatan: totalPendapatan,
        totalPotongan: potonganKaryawan,
        gajiBersih: gajiBersih,
        status: StatusPayroll.draft,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final saved = await _payrollService.savePayroll(payroll);
      _selectedPayroll = saved;
      return saved;
    } catch (e) {
      debugPrint('Error calculating payroll: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  double _calculateLemburRp(double totalJam, double gajiPokok) {
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

  Future<bool> approvePayroll(String id) async {
    _setLoading(true);
    try {
      await _payrollService.approve(id);
      if (_selectedPayroll?.id == id) {
        _selectedPayroll = await _payrollService.getById(id);
      }
      return true;
    } catch (e) {
      debugPrint('Error approving payroll: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> markAsPaid(String id) async {
    _setLoading(true);
    try {
      await _payrollService.markAsPaid(id);
      if (_selectedPayroll?.id == id) {
        _selectedPayroll = await _payrollService.getById(id);
      }
      return true;
    } catch (e) {
      debugPrint('Error marking payroll as paid: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> generateQrForPayroll(String id) async {
    try {
      final qrUrl = await _payrollService.generateQr(id);
      if (_selectedPayroll?.id == id) {
        _selectedPayroll = await _payrollService.getById(id);
      }
      return qrUrl;
    } catch (e) {
      debugPrint('Error generating QR for payroll: $e');
      return null;
    }
  }

  void selectPayroll(PayrollModel? payroll) {
    _selectedPayroll = payroll;
    notifyListeners();
  }
}
