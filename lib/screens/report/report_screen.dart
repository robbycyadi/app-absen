import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/employee_provider.dart';
import '../../providers/report_provider.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  String? _selectedEmployeeId;
  String? _selectedType;
  Uint8List? _generatedBytes;
  String? _generatedFileName;

  final List<Map<String, dynamic>> _reportTypes = [
    {
      'key': 'attendance',
      'title': 'Laporan Absensi Karyawan',
      'icon': Icons.calendar_month,
      'color': Color(0xFF1A237E),
      'needsEmployee': true,
    },
    {
      'key': 'payroll_summary',
      'title': 'Laporan Payroll (Semua Karyawan)',
      'icon': Icons.people,
      'color': Color(0xFF388E3C),
      'needsEmployee': false,
    },
    {
      'key': 'payroll_slip',
      'title': 'Slip Gaji (Individual)',
      'icon': Icons.receipt_long,
      'color': Color(0xFFF57C00),
      'needsEmployee': true,
    },
  ];

  String? _selectedEmployeeIdForFilter;
  List<Map<String, dynamic>> _reportHistory = [];

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    if (auth.currentUser != null && auth.currentUser?.role == Role.admin) {
      context.read<EmployeeProvider>().loadAllEmployees();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.currentUser?.role == Role.admin ||
        auth.currentUser?.role == Role.manager;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pilih Jenis Laporan',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ..._reportTypes.map((type) => _buildReportTypeCard(type, isAdmin)),
            const SizedBox(height: 24),
            if (_selectedType != null) _buildForm(),
            if (_generatedFile != null) ...[
              const SizedBox(height: 24),
              _buildPreviewAndActions(),
            ],
            if (_reportHistory.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildHistory(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReportTypeCard(Map<String, dynamic> type, bool isAdmin) {
    final key = type['key'] as String;
    final isSelected = _selectedType == key;

    if (key == 'payroll_summary' && !isAdmin) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _selectedType = key;
            _generatedBytes = null;
            _generatedFileName = null;
            if (!type['needsEmployee'] as bool) {
              _selectedEmployeeId = null;
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (type['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(type['icon'] as IconData, color: type['color'] as Color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type['title'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      type['needsEmployee'] as bool
                          ? 'Pilih karyawan, bulan, dan tahun'
                          : 'Pilih bulan dan tahun',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    final type = _reportTypes.firstWhere((t) => t['key'] == _selectedType);
    final needsEmployee = type['needsEmployee'] as bool;
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];

    final title = type['title'] as String;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (needsEmployee)
              Consumer<EmployeeProvider>(
                builder: (context, emp, _) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      onTap: () => _showEmployeePicker(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Karyawan',
                          prefixIcon: Icon(Icons.person),
                        ),
                        child: Text(
                          _selectedEmployeeIdForFilter != null
                              ? emp.employees
                                  .where((e) => e.id == _selectedEmployeeIdForFilter)
                                  .map((e) => e.namaLengkap)
                                  .firstOrNull ??
                                  'Pilih Karyawan'
                              : 'Pilih Karyawan',
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                      ),
                    ),
                  );
                },
              ),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _showMonthPicker(months),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Bulan',
                        prefixIcon: Icon(Icons.calendar_month),
                      ),
                      child: Text(
                        months[_selectedMonth - 1],
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _showYearPicker(),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Tahun',
                        prefixIcon: Icon(Icons.date_range),
                      ),
                      child: Text(
                        '$_selectedYear',
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Consumer<ReportProvider>(
              builder: (context, report, _) {
                return Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: report.isLoading
                              ? null
                              : () => _generateReport(context),
                          icon: report.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.play_arrow),
                          label: Text(
                            report.isLoading ? 'Memproses...' : 'Generate',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
            if (_generatedBytes != null) ...[
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () => _shareReport(context),
                          icon: const Icon(Icons.share, size: 18),
                          label: const Text('Share'),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewAndActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF388E3C), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Laporan siap!',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF388E3C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'File: ${_generatedFileName ?? "report"}',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _shareReport(context),
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Bagikan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Riwayat Laporan',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ..._reportHistory.reversed.map((item) {
          return Card(
            margin: const EdgeInsets.only(bottom: 6),
            child: ListTile(
              leading: Icon(
                item['type'] == 'attendance'
                    ? Icons.calendar_month
                    : item['type'] == 'payroll_summary'
                        ? Icons.people
                        : Icons.receipt_long,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                item['name'] as String,
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                item['date'] as String,
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.share, size: 18),
                onPressed: () {
                  if (item['bytes'] != null) {
                    context.read<ReportProvider>().shareReport(
                      item['bytes'] as Uint8List,
                      item['fileName'] as String,
                    );
                  }
                },
              ),
            ),
          );
        }),
      ],
    );
  }

  void _showMonthPicker(List<String> months) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pilih Bulan'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 12,
            itemBuilder: (_, i) => OutlinedButton(
              onPressed: () {
                setState(() => _selectedMonth = i + 1);
                Navigator.of(ctx).pop();
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: _selectedMonth == i + 1
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                    : null,
              ),
              child: Text(months[i], style: GoogleFonts.poppins(fontSize: 12)),
            ),
          ),
        ),
      ),
    );
  }

  void _showYearPicker() {
    final now = DateTime.now();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pilih Tahun'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 5,
            itemBuilder: (_, i) {
              final year = now.year - 2 + i;
              return OutlinedButton(
                onPressed: () {
                  setState(() => _selectedYear = year);
                  Navigator.of(ctx).pop();
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: _selectedYear == year
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : null,
                ),
                child: Text('$year', style: GoogleFonts.poppins(fontSize: 12)),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showEmployeePicker(BuildContext context) {
    final employees = context.read<EmployeeProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pilih Karyawan'),
        content: SizedBox(
          width: double.maxFinite,
          child: employees.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: employees.employees.length,
                  itemBuilder: (_, i) {
                    final emp = employees.employees[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: emp.fotoUrl.isNotEmpty
                            ? NetworkImage(emp.fotoUrl)
                            : null,
                        child: emp.fotoUrl.isEmpty
                            ? Text(
                                emp.namaLengkap.isNotEmpty
                                    ? emp.namaLengkap[0].toUpperCase()
                                    : '?',
                              )
                            : null,
                      ),
                      title: Text(
                        emp.namaLengkap,
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        emp.nip,
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      trailing: _selectedEmployeeIdForFilter == emp.id
                          ? Icon(Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary)
                          : null,
                      onTap: () {
                        setState(() => _selectedEmployeeIdForFilter = emp.id);
                        Navigator.of(ctx).pop();
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }

  Future<void> _generateReport(BuildContext context) async {
    if (_selectedType == null) return;

    final report = context.read<ReportProvider>();

    Uint8List? bytes;
    String? fileName;

    switch (_selectedType) {
      case 'attendance':
        if (_selectedEmployeeIdForFilter == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Silakan pilih karyawan terlebih dahulu'),
              backgroundColor: Color(0xFFD32F2F),
            ),
          );
          return;
        }
        bytes = await report.generateAttendanceReport(
          _selectedEmployeeIdForFilter!,
          _selectedMonth,
          _selectedYear,
        );
        fileName = 'laporan_absensi_$_selectedMonth-$_selectedYear.pdf';
        break;
      case 'payroll_summary':
        bytes = await report.generateAllPayrollsReport(
          _selectedMonth,
          _selectedYear,
        );
        fileName = 'rekap_gaji_$_selectedMonth-$_selectedYear.xlsx';
        break;
      case 'payroll_slip':
        if (_selectedEmployeeIdForFilter == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Silakan pilih karyawan terlebih dahulu'),
              backgroundColor: Color(0xFFD32F2F),
            ),
          );
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fitur slip gaji individual membutuhkan ID payroll')),
        );
        return;
    }

    if (!mounted) return;

    if (bytes != null) {
      setState(() {
        _generatedBytes = bytes;
        _generatedFileName = fileName;
      });

      final typeName = _reportTypes
          .firstWhere((t) => t['key'] == _selectedType)['title'] as String;

      _reportHistory.add({
        'type': _selectedType,
        'name': typeName,
        'date': DateFormat('dd MMMM yyyy HH:mm', 'id_ID').format(DateTime.now()),
        'bytes': bytes,
        'fileName': fileName,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan berhasil dibuat'),
          backgroundColor: Color(0xFF388E3C),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(report.errorMessage ?? 'Gagal membuat laporan'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _shareReport(BuildContext context) async {
    if (_generatedBytes == null || _generatedFileName == null) return;

    final report = context.read<ReportProvider>();
    await report.shareReport(_generatedBytes!, _generatedFileName!);
  }
}
