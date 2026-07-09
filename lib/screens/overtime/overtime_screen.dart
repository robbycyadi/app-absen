import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/constants.dart';
import '../../models/user_model.dart';
import '../../models/overtime_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/overtime_provider.dart';
import '../../services/report_service.dart';

class OvertimeScreen extends StatefulWidget {
  const OvertimeScreen({super.key});

  @override
  State<OvertimeScreen> createState() => _OvertimeScreenState();
}

class _OvertimeScreenState extends State<OvertimeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    final auth = context.read<AuthProvider>();
    final overtime = context.read<OvertimeProvider>();
    if (auth.currentUser != null) {
      overtime.loadMyOvertimes(auth.currentUser!.id);
    }
    overtime.loadPendingOvertimeApprovals();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isManager =
        auth.currentUser?.role == Role.admin || auth.currentUser?.role == Role.manager;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lembur'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: 'Lembur Saya'),
            if (isManager) const Tab(text: 'Approval'),
          ],
        ),
      ),
      body: Consumer<OvertimeProvider>(
        builder: (context, overtime, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _MyOvertimeTab(),
              if (isManager) _ApprovalTab(),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showOvertimeForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showOvertimeForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _OvertimeFormSheet(),
    );
  }
}

class _MyOvertimeTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final overtime = context.watch<OvertimeProvider>();

    if (overtime.isLoading && overtime.myOvertimes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (overtime.myOvertimes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Belum ada pengajuan lembur',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => const _OvertimeFormSheet(),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Ajukan Lembur'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final auth = context.read<AuthProvider>();
        if (auth.currentUser != null) {
          await context.read<OvertimeProvider>().loadMyOvertimes(auth.currentUser!.id);
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: overtime.myOvertimes.length,
        itemBuilder: (context, index) {
          final item = overtime.myOvertimes[index];
          return _OvertimeCard(item: item);
        },
      ),
    );
  }
}

class _ApprovalTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final overtime = context.watch<OvertimeProvider>();

    if (overtime.isLoading && overtime.pendingApprovals.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (overtime.pendingApprovals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Tidak ada pengajuan yang perlu disetujui',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await context.read<OvertimeProvider>().loadPendingOvertimeApprovals();
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: overtime.pendingApprovals.length,
        itemBuilder: (context, index) {
          final item = overtime.pendingApprovals[index];
          return _ApprovalCard(item: item);
        },
      ),
    );
  }
}

class _OvertimeCard extends StatelessWidget {
  final OvertimeModel item;

  const _OvertimeCard({required this.item});

  Color _statusColor(StatusOvertime status) {
    switch (status) {
      case StatusOvertime.pending:
        return const Color(0xFFF57C00);
      case StatusOvertime.disetujui:
        return const Color(0xFF388E3C);
      case StatusOvertime.ditolak:
        return const Color(0xFFD32F2F);
    }
  }

  String _statusLabel(StatusOvertime status) {
    switch (status) {
      case StatusOvertime.pending:
        return 'Menunggu';
      case StatusOvertime.disetujui:
        return 'Disetujui';
      case StatusOvertime.ditolak:
        return 'Ditolak';
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportService = ReportService();
    final dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateFormat.format(item.tanggal),
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
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(item.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  '${item.jamMulai} - ${item.jamSelesai}',
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700),
                ),
                const SizedBox(width: 16),
                Text(
                  '${item.totalJam.toStringAsFixed(1)} jam',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.namaKaryawan,
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
            if (item.alasan.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.alasan,
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700),
                ),
              ),
            ],
            if (item.catatan != null && item.catatan!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Catatan: ${item.catatan}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              reportService.formatRupiah(
                (item.totalJam * 15000).toInt(),
              ),
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  final OvertimeModel item;

  const _ApprovalCard({required this.item});

  Color _statusColor(StatusOvertime status) {
    switch (status) {
      case StatusOvertime.pending:
        return const Color(0xFFF57C00);
      case StatusOvertime.disetujui:
        return const Color(0xFF388E3C);
      case StatusOvertime.ditolak:
        return const Color(0xFFD32F2F);
    }
  }

  String _statusLabel(StatusOvertime status) {
    switch (status) {
      case StatusOvertime.pending:
        return 'Menunggu';
      case StatusOvertime.disetujui:
        return 'Disetujui';
      case StatusOvertime.ditolak:
        return 'Ditolak';
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportService = ReportService();
    final dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateFormat.format(item.tanggal),
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
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(item.status),
                    ),
                  ),
                ),
              ],
            ),
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
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  '${item.jamMulai} - ${item.jamSelesai} (${item.totalJam.toStringAsFixed(1)} jam)',
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
            if (item.alasan.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.alasan,
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              reportService.formatRupiah(
                (item.totalJam * 15000).toInt(),
              ),
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            if (item.status == StatusOvertime.pending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handleReject(context),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Tolak'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD32F2F),
                        side: const BorderSide(color: Color(0xFFD32F2F)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleApprove(context),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Setujui'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF388E3C),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleApprove(BuildContext context) async {
    final overtime = context.read<OvertimeProvider>();
    final success = await overtime.approveOvertime(item.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Lembur berhasil disetujui' : 'Gagal menyetujui lembur'),
        backgroundColor: success ? const Color(0xFF388E3C) : Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _handleReject(BuildContext context) async {
    final overtime = context.read<OvertimeProvider>();
    final success = await overtime.rejectOvertime(item.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Lembur berhasil ditolak' : 'Gagal menolak lembur'),
        backgroundColor: success ? const Color(0xFF388E3C) : Theme.of(context).colorScheme.error,
      ),
    );
  }
}

class _OvertimeFormSheet extends StatefulWidget {
  const _OvertimeFormSheet();

  @override
  State<_OvertimeFormSheet> createState() => _OvertimeFormSheetState();
}

class _OvertimeFormSheetState extends State<_OvertimeFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _alasanController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _jamMulai = const TimeOfDay(hour: 17, minute: 0);
  TimeOfDay _jamSelesai = const TimeOfDay(hour: 20, minute: 0);
  bool _isSubmitting = false;

  double get _totalJam {
    final mulai = _jamMulai.hour + _jamMulai.minute / 60.0;
    final selesai = _jamSelesai.hour + _jamSelesai.minute / 60.0;
    double diff = selesai - mulai;
    if (diff < 0) diff += 24;
    return double.parse(diff.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _alasanController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      locale: const Locale('id', 'ID'),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _pickTime({required bool isMulai}) async {
    final time = await showTimePicker(
      context: context,
      initialTime: isMulai ? _jamMulai : _jamSelesai,
    );
    if (time != null) {
      setState(() {
        if (isMulai) {
          _jamMulai = time;
        } else {
          _jamSelesai = time;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_totalJam <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jam selesai harus lebih dari jam mulai'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
      return;
    }

    if (_totalJam > AppConstants.maxOvertimeHoursPerDay) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lembur maksimal ${AppConstants.maxOvertimeHoursPerDay} jam per hari'),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    final overtime = context.read<OvertimeProvider>();

    final data = {
      'employee_id': auth.currentUser!.id,
      'nama_karyawan': auth.currentUser!.namaLengkap,
      'tanggal': DateFormat('yyyy-MM-dd').format(_selectedDate),
      'jam_mulai': '${_jamMulai.hour.toString().padLeft(2, '0')}:${_jamMulai.minute.toString().padLeft(2, '0')}',
      'jam_selesai': '${_jamSelesai.hour.toString().padLeft(2, '0')}:${_jamSelesai.minute.toString().padLeft(2, '0')}',
      'total_jam': _totalJam,
      'alasan': _alasanController.text.trim(),
    };

    final success = await overtime.submitOvertime(data);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppConstants.successOvertimeSubmitted),
          backgroundColor: Color(0xFF388E3C),
        ),
      );
      if (auth.currentUser != null) {
        overtime.loadMyOvertimes(auth.currentUser!.id);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengajukan lembur'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final reportService = ReportService();
    final estimatedPay = auth.currentUser != null
        ? context.read<OvertimeProvider>().calculateOvertimePay(
              _totalJam,
              auth.currentUser!.positionId.isEmpty ? 4000000 : 0,
            )
        : 0.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pengajuan Lembur',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate),
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickTime(isMulai: true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Jam Mulai',
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        child: Text(
                          '${_jamMulai.hour.toString().padLeft(2, '0')}:${_jamMulai.minute.toString().padLeft(2, '0')}',
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickTime(isMulai: false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Jam Selesai',
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        child: Text(
                          '${_jamSelesai.hour.toString().padLeft(2, '0')}:${_jamSelesai.minute.toString().padLeft(2, '0')}',
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _alasanController,
                maxLines: 3,
                maxLength: AppConstants.maxNotesLength,
                decoration: const InputDecoration(
                  labelText: 'Alasan / Keterangan',
                  hintText: 'Jelaskan alasan lembur',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Alasan tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Jam',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '${_totalJam.toStringAsFixed(1)} jam',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Estimasi Upah',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          reportService.formatRupiah(estimatedPay),
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF388E3C),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Ajukan Lembur',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
