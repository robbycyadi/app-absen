import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/payroll_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payroll_provider.dart';
import '../../providers/employee_provider.dart';
import '../../services/report_service.dart';
import 'payroll_detail_screen.dart';

class PayrollScreen extends StatefulWidget {
  const PayrollScreen({super.key});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final auth = context.read<AuthProvider>();
    final payroll = context.read<PayrollProvider>();

    if (auth.currentUser != null) {
      payroll.loadMyPayrolls(auth.currentUser!.id, _selectedYear);
    }

    if (auth.currentUser?.role == Role.admin) {
      payroll.loadAllPayrolls(_selectedMonth, _selectedYear);
      context.read<EmployeeProvider>().loadAllEmployees();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.currentUser?.role == Role.admin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Penggajian'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Generate Payroll',
              onPressed: () => _showGenerateDialog(context),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildPeriodSelector(),
          if (isAdmin) _buildSummaryCard(),
          if (isAdmin) _buildSearchBar(),
          Expanded(child: _buildPayrollList(isAdmin)),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _showMonthPicker(months),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Bulan',
                  prefixIcon: Icon(Icons.calendar_month),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                _loadData();
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: _selectedMonth == i + 1
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                    : null,
              ),
              child: Text(
                months[i],
                style: GoogleFonts.poppins(fontSize: 12),
              ),
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
                  _loadData();
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: _selectedYear == year
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : null,
                ),
                child: Text(
                  '$year',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Consumer2<PayrollProvider, AuthProvider>(
      builder: (context, payroll, auth, _) {
        if (payroll.allPayrolls.isEmpty) return const SizedBox.shrink();

        final totalGajiBersih = payroll.allPayrolls.fold<double>(
          0, (sum, p) => sum + p.gajiBersih,
        );
        final totalLembur = payroll.allPayrolls.fold<double>(
          0, (sum, p) => sum + p.lembur,
        );
        final totalBpjs = payroll.allPayrolls.fold<double>(
          0, (sum, p) => sum + p.bpjsKesehatan + p.bpjsJHT + p.bpjsJP,
        );

        final reportService = ReportService();

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ringkasan Bulanan',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _summaryItem('Total Gaji Bersih', reportService.formatRupiah(totalGajiBersih)),
                    _summaryItem('Total Lembur', reportService.formatRupiah(totalLembur)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _summaryItem('Total BPJS', reportService.formatRupiah(totalBpjs)),
                    _summaryItem('Jml Karyawan', '${payroll.allPayrolls.length}'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Cari karyawan...',
          prefixIcon: Icon(Icons.search),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
      ),
    );
  }

  Widget _buildPayrollList(bool isAdmin) {
    return Consumer2<PayrollProvider, AuthProvider>(
      builder: (context, payroll, auth, _) {
        if (payroll.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        List<PayrollModel> items;
        if (isAdmin) {
          items = payroll.allPayrolls.where((p) {
            return _searchQuery.isEmpty ||
                p.namaKaryawan.toLowerCase().contains(_searchQuery);
          }).toList();
        } else {
          items = payroll.myPayrolls;
        }

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Belum ada data payroll',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (isAdmin) ...[
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showGenerateDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Generate Payroll'),
                  ),
                ],
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            _loadData();
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _PayrollCard(
                item: item,
                isAdmin: isAdmin,
                onTap: () {
                  payroll.selectPayroll(item);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PayrollDetailScreen(),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  void _showGenerateDialog(BuildContext context) {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          int dialogMonth = _selectedMonth;
          int dialogYear = _selectedYear;

          return AlertDialog(
            title: const Text('Generate Payroll'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Generate payroll untuk periode:',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Text(
                  '${months[dialogMonth - 1]} $dialogYear',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _generateAllPayrolls(dialogMonth, dialogYear);
                        },
                        icon: const Icon(Icons.group, size: 18),
                        label: const Text('Generate All'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Batal'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _generateAllPayrolls(int month, int year) async {
    final payroll = context.read<PayrollProvider>();
    final employeeProvider = context.read<EmployeeProvider>();

    final employees = employeeProvider.employees;
    if (employees.isEmpty) {
      await employeeProvider.loadAllEmployees();
    }

    if (employeeProvider.employees.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data karyawan')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Memproses payroll...'),
          ],
        ),
        duration: Duration(seconds: 10),
      ),
    );

    int success = 0;
    int failed = 0;

    for (final emp in employeeProvider.employees) {
      if (!emp.isActive) continue;
      final result = await payroll.calculatePayroll(emp.id, month, year);
      if (result != null) {
        success++;
      } else {
        failed++;
      }
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payroll generated: $success berhasil, $failed gagal'),
        backgroundColor: failed == 0 ? const Color(0xFF388E3C) : const Color(0xFFF57C00),
      ),
    );

    payroll.loadAllPayrolls(month, year);
  }
}

class _PayrollCard extends StatelessWidget {
  final PayrollModel item;
  final bool isAdmin;
  final VoidCallback onTap;

  const _PayrollCard({
    required this.item,
    required this.isAdmin,
    required this.onTap,
  });

  Color _statusColor(StatusPayroll status) {
    switch (status) {
      case StatusPayroll.draft:
        return const Color(0xFFF57C00);
      case StatusPayroll.approved:
        return const Color(0xFF1A237E);
      case StatusPayroll.paid:
        return const Color(0xFF388E3C);
    }
  }

  String _statusLabel(StatusPayroll status) {
    switch (status) {
      case StatusPayroll.draft:
        return 'Draft';
      case StatusPayroll.approved:
        return 'Approved';
      case StatusPayroll.paid:
        return 'Paid';
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportService = ReportService();
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${months[item.bulan - 1]} ${item.tahun}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(item.status).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _statusLabel(item.status),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _statusColor(item.status),
                      ),
                    ),
                  ),
                ],
              ),
              if (isAdmin) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      item.namaKaryawan,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Gaji Bersih',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    reportService.formatRupiah(item.gajiBersih),
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _infoChip('Pokok', reportService.formatRupiah(item.gajiPokok)),
                  const SizedBox(width: 8),
                  _infoChip('Lembur', reportService.formatRupiah(item.lembur)),
                  const SizedBox(width: 8),
                  _infoChip('BPJS', reportService.formatRupiah(item.bpjsKesehatan + item.bpjsJHT + item.bpjsJP)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $value',
        style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade700),
      ),
    );
  }
}
