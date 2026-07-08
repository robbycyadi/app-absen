import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../config/constants.dart';
import '../../models/payroll_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payroll_provider.dart';
import '../../providers/report_provider.dart';
import '../../services/report_service.dart';

class PayrollDetailScreen extends StatefulWidget {
  const PayrollDetailScreen({super.key});

  @override
  State<PayrollDetailScreen> createState() => _PayrollDetailScreenState();
}

class _PayrollDetailScreenState extends State<PayrollDetailScreen> {
  bool _showQr = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final payrollProvider = context.watch<PayrollProvider>();
    final payroll = payrollProvider.selectedPayroll;
    final isAdmin = auth.currentUser?.role == Role.admin;
    final reportService = ReportService();
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];

    if (payroll == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Payroll')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Pilih data payroll terlebih dahulu',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Slip Gaji'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            tooltip: 'QR Code',
            onPressed: () => setState(() => _showQr = !_showQr),
          ),
          Consumer<ReportProvider>(
            builder: (context, report, _) {
              return IconButton(
                icon: report.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.download),
                tooltip: 'Download PDF',
                onPressed: report.isLoading ? null : () => _downloadPdf(context, payroll),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Bagikan',
            onPressed: () => _sharePdf(context, payroll),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(payroll, months, reportService),
            const SizedBox(height: 16),
            if (_showQr) _buildQrSection(payroll, reportService),
            if (_showQr) const SizedBox(height: 16),
            _buildIncomeSection(payroll, reportService),
            const SizedBox(height: 12),
            _buildDeductionSection(payroll, reportService),
            const SizedBox(height: 12),
            _buildCompanyContribution(payroll, reportService),
            const SizedBox(height: 12),
            _buildNetSalary(payroll, reportService),
            const SizedBox(height: 12),
            _buildStatusBadge(payroll),
            if (isAdmin) ...[
              const SizedBox(height: 20),
              _buildAdminActions(payroll),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(PayrollModel payroll, List<String> months, ReportService rs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                Icons.business,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppConstants.appName,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'SLIP GAJI',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              payroll.namaKaryawan,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${months[payroll.bulan - 1]} ${payroll.tahun}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrSection(PayrollModel payroll, ReportService rs) {
    final qrData = jsonEncode({
      'id': payroll.id,
      'employeeId': payroll.employeeId,
      'nama': payroll.namaKaryawan,
      'periode': '${payroll.bulan}/${payroll.tahun}',
      'gajiBersih': payroll.gajiBersih,
      'status': payroll.status.toString(),
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'QR Code Slip Gaji',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 180,
              gapless: false,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Scan untuk verifikasi slip gaji',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeSection(PayrollModel payroll, ReportService rs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Pendapatan', Icons.trending_up, const Color(0xFF388E3C)),
            const Divider(),
            _incomeRow('Gaji Pokok', rs.formatRupiah(payroll.gajiPokok)),
            _incomeRow('Tunjangan Tetap', rs.formatRupiah(payroll.tunjanganTetap)),
            _incomeRow('Uang Makan', rs.formatRupiah(payroll.uangMakan)),
            _incomeRow('Uang Transport', rs.formatRupiah(payroll.uangTransport)),
            _incomeRow('Lembur', rs.formatRupiah(payroll.lembur)),
            if (payroll.thr > 0) _incomeRow('THR', rs.formatRupiah(payroll.thr)),
            const Divider(),
            _totalRow('Total Pendapatan', rs.formatRupiah(payroll.totalPendapatan), const Color(0xFF388E3C)),
          ],
        ),
      ),
    );
  }

  Widget _buildDeductionSection(PayrollModel payroll, ReportService rs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Potongan', Icons.trending_down, const Color(0xFFD32F2F)),
            const Divider(),
            _incomeRow('BPJS Kesehatan (1%)', '-${rs.formatRupiah(payroll.bpjsKesehatan)}'),
            _incomeRow('BPJS JHT (2%)', '-${rs.formatRupiah(payroll.bpjsJHT)}'),
            _incomeRow('BPJS JP (1%)', '-${rs.formatRupiah(payroll.bpjsJP)}'),
            if ((payroll.totalPotongan - payroll.bpjsKesehatan - payroll.bpjsJHT - payroll.bpjsJP) > 0)
              _incomeRow(
                'Potongan Lain',
                '-${rs.formatRupiah(payroll.totalPotongan - payroll.bpjsKesehatan - payroll.bpjsJHT - payroll.bpjsJP)}',
              ),
            const Divider(),
            _totalRow('Total Potongan', '-${rs.formatRupiah(payroll.totalPotongan)}', const Color(0xFFD32F2F)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyContribution(PayrollModel payroll, ReportService rs) {
    final bpjsPerusahaan =
        (payroll.gajiPokok * 0.04) + (payroll.gajiPokok * 0.0054) +
        (payroll.gajiPokok * 0.003) + (payroll.gajiPokok * 0.037) +
        (payroll.gajiPokok * 0.02);
    final totalPerusahaan = payroll.gajiPokok + payroll.tunjanganTetap +
        payroll.uangMakan + payroll.uangTransport + payroll.lembur +
        payroll.thr + bpjsPerusahaan;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Kontribusi Perusahaan', Icons.business, const Color(0xFF1A237E)),
            const Divider(),
            _incomeRow('BPJS Kesehatan (4%)', rs.formatRupiah(payroll.gajiPokok * 0.04)),
            _incomeRow('BPJS JKK (0.54%)', rs.formatRupiah(payroll.gajiPokok * 0.0054)),
            _incomeRow('BPJS JKM (0.3%)', rs.formatRupiah(payroll.gajiPokok * 0.003)),
            _incomeRow('BPJS JHT (3.7%)', rs.formatRupiah(payroll.gajiPokok * 0.037)),
            _incomeRow('BPJS JP (2%)', rs.formatRupiah(payroll.gajiPokok * 0.02)),
            const Divider(),
            _totalRow('Total Biaya Karyawan', rs.formatRupiah(totalPerusahaan), const Color(0xFF1A237E)),
          ],
        ),
      ),
    );
  }

  Widget _buildNetSalary(PayrollModel payroll, ReportService rs) {
    return Card(
      color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'GAJI BERSIH',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              rs.formatRupiah(payroll.gajiBersih),
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(PayrollModel payroll) {
    Color color;
    String label;
    IconData icon;

    switch (payroll.status) {
      case StatusPayroll.draft:
        color = const Color(0xFFF57C00);
        label = 'Draft';
        icon = Icons.edit_note;
      case StatusPayroll.approved:
        color = const Color(0xFF1A237E);
        label = 'Approved';
        icon = Icons.verified;
      case StatusPayroll.paid:
        color = const Color(0xFF388E3C);
        label = 'Paid';
        icon = Icons.check_circle;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActions(PayrollModel payroll) {
    if (payroll.status == StatusPayroll.paid) return const SizedBox.shrink();

    return Column(
      children: [
        if (payroll.status == StatusPayroll.draft)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _approvePayroll(payroll.id),
              icon: const Icon(Icons.verified),
              label: const Text('Approve Payroll'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
              ),
            ),
          ),
        if (payroll.status == StatusPayroll.approved) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _markAsPaid(payroll.id),
              icon: const Icon(Icons.check_circle),
              label: const Text('Mark as Paid'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF388E3C),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _sectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _incomeRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadPdf(BuildContext context, PayrollModel payroll) async {
    final report = context.read<ReportProvider>();

    final payrollData = {
      'id': payroll.id,
      'employee_id': payroll.employeeId,
      'nama_lengkap': payroll.namaKaryawan,
      'nip': '',
      'nama_jabatan': '',
      'gaji_pokok': payroll.gajiPokok,
      'tunjangan_tetap': payroll.tunjanganTetap,
      'uang_makan': payroll.uangMakan,
      'uang_transport': payroll.uangTransport,
      'total_lembur': payroll.lembur,
      'thr': payroll.thr,
      'bpjs_kesehatan_karyawan': payroll.bpjsKesehatan,
      'bpjs_jht_karyawan': payroll.bpjsJHT,
      'bpjs_jp_karyawan': payroll.bpjsJP,
      'potongan_lain': 0,
      'total_pendapatan': payroll.totalPendapatan,
      'total_potongan': payroll.totalPotongan,
      'gaji_bersih': payroll.gajiBersih,
      'status': payroll.status.toString(),
      'periode_bulan': payroll.bulan,
      'periode_tahun': payroll.tahun,
    };

    final employeeData = {
      'nama_lengkap': payroll.namaKaryawan,
      'nip': '',
      'nama_jabatan': '',
    };

    final file = await report.generatePayrollSlip(payroll.id);

    if (!mounted) return;

    if (file != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Slip gaji berhasil diunduh'),
          backgroundColor: Color(0xFF388E3C),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(report.errorMessage ?? 'Gagal mengunduh slip gaji'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _sharePdf(BuildContext context, PayrollModel payroll) async {
    final report = context.read<ReportProvider>();
    final file = await report.generatePayrollSlip(payroll.id);

    if (!mounted) return;

    if (file != null) {
      await report.shareReport(file);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(report.errorMessage ?? 'Gagal membagikan slip gaji'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _approvePayroll(String id) async {
    final payroll = context.read<PayrollProvider>();
    final success = await payroll.approvePayroll(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Payroll berhasil di-approve' : 'Gagal approve payroll'),
        backgroundColor: success ? const Color(0xFF388E3C) : Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _markAsPaid(String id) async {
    final payroll = context.read<PayrollProvider>();
    final success = await payroll.markAsPaid(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Payroll berhasil ditandai dibayar' : 'Gagal menandai dibayar'),
        backgroundColor: success ? const Color(0xFF388E3C) : Theme.of(context).colorScheme.error,
      ),
    );
  }
}
