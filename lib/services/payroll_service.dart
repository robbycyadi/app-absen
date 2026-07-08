import 'package:app_absen/config/supabase_config.dart';
import 'package:app_absen/models/payroll_model.dart';
import 'package:app_absen/models/position_model.dart';
import 'package:app_absen/models/attendance_model.dart';
import 'package:app_absen/config/constants.dart';

class PayrollService {
  final _client = SupabaseConfig.getSupabaseClient();

  Future<List<PayrollModel>> getMyPayrolls(
      String employeeId, int tahun) async {
    final response = await _client
        .from('payrolls')
        .select('*')
        .eq('employee_id', employeeId)
        .eq('periode_tahun', tahun)
        .order('periode_bulan', ascending: false)
        .execute();

    if (response.data != null) {
      final list = response.data as List;
      return list
          .map((e) => PayrollModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<PayrollModel>> getAllPayrolls(int bulan, int tahun) async {
    final response = await _client
        .from('payrolls')
        .select('*, profiles(*)')
        .eq('periode_bulan', bulan)
        .eq('periode_tahun', tahun)
        .order('created_at', ascending: false)
        .execute();

    if (response.data != null) {
      final list = response.data as List;
      return list
          .map((e) => PayrollModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<PayrollModel?> getPayrollDetail(String id) async {
    final response = await _client
        .from('payrolls')
        .select('*, profiles(*)')
        .eq('id', id)
        .single()
        .execute();

    if (response.data != null) {
      return PayrollModel.fromJson(response.data as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> savePayroll(PayrollModel payroll) async {
    await _client.from('payrolls').upsert(payroll.toJson()).execute();
  }

  Future<void> approvePayroll(String id) async {
    await _client
        .from('payrolls')
        .update({'status': 'approved'})
        .eq('id', id)
        .execute();
  }

  Future<void> markAsPaid(String id) async {
    await _client
        .from('payrolls')
        .update({
          'status': 'paid',
          'paid_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id)
        .execute();
  }

  Future<PayrollModel> calculatePayroll({
    required String employeeId,
    required int bulan,
    required int tahun,
    required double gajiPokok,
    required double tunjanganTetap,
    required double uangMakan,
    required double uangTransport,
    double totalLembur = 0,
    double thr = 0,
    double potonganLain = 0,
  }) async {
    final upahBpjs =
        gajiPokok + tunjanganTetap;
    final maxUpah = AppConstants.bpjsKetenagakerjaanJHTEmployer * 1000000;

    final bpjsKesehatanKaryawan =
        upahBpjs * AppConstants.bpjsKesehatanEmployee / 100;
    final bpjsKesehatanPerusahaan =
        upahBpjs * AppConstants.bpjsKesehatanEmployer / 100;
    final bpjsJhtKaryawan =
        upahBpjs * AppConstants.bpjsKetenagakerjaanJHTEmployee / 100;
    final bpjsJhtPerusahaan =
        upahBpjs * AppConstants.bpjsKetenagakerjaanJHTEmployer / 100;
    final bpjsJpKaryawan =
        upahBpjs * AppConstants.bpjsKetenagakerjaanJPEmployee / 100;
    final bpjsJpPerusahaan =
        upahBpjs * AppConstants.bpjsKetenagakerjaanJPEmployer / 100;
    final bpjsJkkPerusahaan =
        upahBpjs * AppConstants.bpjsKetenagakerjaanJKK / 100;
    final bpjsJkmPerusahaan =
        upahBpjs * AppConstants.bpjsKetenagakerjaanJKM / 100;

    final totalPendapatan = gajiPokok +
        tunjanganTetap +
        uangMakan +
        uangTransport +
        totalLembur +
        thr;

    final totalPotonganKaryawan = bpjsKesehatanKaryawan +
        bpjsJhtKaryawan +
        bpjsJpKaryawan +
        potonganLain;

    final gajiBersih = totalPendapatan - totalPotonganKaryawan;

    return PayrollModel(
      id: '',
      employeeId: employeeId,
      namaKaryawan: '',
      bulan: bulan,
      tahun: tahun,
      gajiPokok: gajiPokok,
      tunjanganTetap: tunjanganTetap,
      uangMakan: uangMakan,
      uangTransport: uangTransport,
      lembur: totalLembur,
      thr: thr,
      bpjsKesehatan: bpjsKesehatanKaryawan,
      bpjsJHT: bpjsJhtKaryawan,
      bpjsJP: bpjsJpKaryawan,
      bpjsJKK: bpjsJkkPerusahaan,
      bpjsJKM: bpjsJkmPerusahaan,
      totalPendapatan: totalPendapatan,
      totalPotongan: totalPotonganKaryawan,
      gajiBersih: gajiBersih,
      status: 'draft',
    );
  }
}
