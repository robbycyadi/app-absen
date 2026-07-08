import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:app_absen/models/attendance_model.dart';
import 'package:app_absen/providers/attendance_provider.dart';
import 'package:app_absen/providers/auth_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late DateTime _selectedMonth;
  AttendanceStatus? _filterStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final auth = context.read<AuthProvider>();
    final attendanceProv = context.read<AttendanceProvider>();
    if (auth.currentUser == null) return;

    setState(() => _isLoading = true);
    await attendanceProv.loadHistory(
      auth.currentUser!.id,
      _selectedMonth.month,
      _selectedMonth.year,
    );
    if (mounted) setState(() => _isLoading = false);
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
    _loadHistory();
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
    _loadHistory();
  }

  List<AttendanceModel> _getFilteredHistory() {
    final attendanceProv = context.read<AttendanceProvider>();
    final history = attendanceProv.history;
    if (_filterStatus == null) return history;
    return history.where((a) => a.status == _filterStatus).toList();
  }

  Map<DateTime, AttendanceStatus> _getAttendanceMap() {
    final attendanceProv = context.read<AttendanceProvider>();
    final map = <DateTime, AttendanceStatus>{};
    for (final attendance in attendanceProv.history) {
      final date = DateTime(
        attendance.tanggal.year,
        attendance.tanggal.month,
        attendance.tanggal.day,
      );
      map[date] = attendance.status;
    }
    return map;
  }

  AttendanceSummary _getSummary() {
    final attendanceProv = context.read<AttendanceProvider>();
    final history = attendanceProv.history;
    int hadir = 0, telat = 0, izin = 0, cuti = 0, alpha = 0;

    for (final a in history) {
      switch (a.status) {
        case AttendanceStatus.hadir:
          hadir++;
        case AttendanceStatus.telat:
          telat++;
        case AttendanceStatus.izin:
          izin++;
        case AttendanceStatus.cuti:
          cuti++;
        case AttendanceStatus.alpha:
          alpha++;
      }
    }

    return AttendanceSummary(
      hadir: hadir,
      telat: telat,
      izin: izin,
      cuti: cuti,
      alpha: alpha,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Absensi'),
      ),
      body: Column(
        children: [
          _buildMonthPicker(),
          _buildSummaryCard(),
          _buildFilterChips(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildMonthPicker() {
    final monthFormatter = DateFormat('MMMM yyyy', 'id_ID');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _previousMonth,
          ),
          Text(
            monthFormatter.format(_selectedMonth),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final summary = _getSummary();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSummaryItem(
              'Hadir',
              summary.hadir.toString(),
              Colors.green,
              Icons.check_circle,
            ),
            _buildDivider(),
            _buildSummaryItem(
              'Telat',
              summary.telat.toString(),
              Colors.orange,
              Icons.warning_amber,
            ),
            _buildDivider(),
            _buildSummaryItem(
              'Izin',
              summary.izin.toString(),
              Colors.blue,
              Icons.article,
            ),
            _buildDivider(),
            _buildSummaryItem(
              'Cuti',
              summary.cuti.toString(),
              Colors.grey,
              Icons.beach_access,
            ),
            _buildDivider(),
            _buildSummaryItem(
              'Alpha',
              summary.alpha.toString(),
              Colors.red,
              Icons.cancel,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
      String label, String value, Color color, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.grey.shade300,
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Semua', null),
            const SizedBox(width: 8),
            _buildFilterChip('Hadir', AttendanceStatus.hadir),
            const SizedBox(width: 8),
            _buildFilterChip('Telat', AttendanceStatus.telat),
            const SizedBox(width: 8),
            _buildFilterChip('Izin', AttendanceStatus.izin),
            const SizedBox(width: 8),
            _buildFilterChip('Cuti', AttendanceStatus.cuti),
            const SizedBox(width: 8),
            _buildFilterChip('Alpha', AttendanceStatus.alpha),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, AttendanceStatus? status) {
    final isSelected = _filterStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _filterStatus = status);
      },
      selectedColor: _getStatusColor(status).withValues(alpha: 0.2),
      checkmarkColor: _getStatusColor(status),
      labelStyle: TextStyle(
        fontSize: 12,
        color: isSelected ? _getStatusColor(status) : null,
        fontWeight: isSelected ? FontWeight.w600 : null,
      ),
    );
  }

  Color _getStatusColor(AttendanceStatus? status) {
    if (status == null) return Theme.of(context).primaryColor;
    switch (status) {
      case AttendanceStatus.hadir:
        return Colors.green;
      case AttendanceStatus.telat:
        return Colors.orange;
      case AttendanceStatus.izin:
        return Colors.blue;
      case AttendanceStatus.cuti:
        return Colors.grey;
      case AttendanceStatus.alpha:
        return Colors.red;
    }
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final history = _getFilteredHistory();
    final attendanceMap = _getAttendanceMap();

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildCalendar(attendanceMap),
          ),
          if (history.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Tidak ada data absensi',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final attendance = history[index];
                    return _buildHistoryItem(attendance);
                  },
                  childCount: history.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCalendar(Map<DateTime, AttendanceStatus> attendanceMap) {
    final year = _selectedMonth.year;
    final month = _selectedMonth.month;
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final daysInMonth = lastDay.day;
    final startWeekday = firstDay.weekday % 7;

    final dayNames = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: dayNames
                  .map(
                    (d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 4),
            ...List.generate(
              ((startWeekday + daysInMonth) / 7).ceil(),
              (weekIndex) {
                final row = <Widget>[];
                for (int dayOfWeek = 0; dayOfWeek < 7; dayOfWeek++) {
                  final day = weekIndex * 7 + dayOfWeek - startWeekday + 1;
                  if (day < 1 || day > daysInMonth) {
                    row.add(const Expanded(child: SizedBox(height: 38)));
                  } else {
                    final date = DateTime(year, month, day);
                    final status = attendanceMap[date];
                    final isToday = _isToday(date);
                    row.add(
                      Expanded(
                        child: Container(
                          height: 38,
                          margin: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: status != null
                                ? _getStatusColor(status).withValues(alpha: 0.2)
                                : null,
                            borderRadius: BorderRadius.circular(6),
                            border: isToday
                                ? Border.all(
                                    color: Theme.of(context).primaryColor,
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  day.toString(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight:
                                        isToday ? FontWeight.bold : FontWeight.normal,
                                    color: status != null
                                        ? _getStatusColor(status)
                                        : null,
                                  ),
                                ),
                                if (status != null)
                                  Container(
                                    width: 5,
                                    height: 5,
                                    margin: const EdgeInsets.only(top: 1),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _getStatusColor(status),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: Row(children: row),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Widget _buildHistoryItem(AttendanceModel attendance) {
    final dateFormatter = DateFormat('dd MMMM yyyy', 'id_ID');
    final timeFormatter = DateFormat('HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetailDialog(attendance),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _getStatusColor(attendance.status).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getStatusIcon(attendance.status),
                  color: _getStatusColor(attendance.status),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateFormatter.format(attendance.tanggal),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (attendance.jamMasuk != null) ...[
                          Icon(Icons.login, size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 2),
                          Text(
                            timeFormatter.format(attendance.jamMasuk!),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (attendance.jamKeluar != null) ...[
                          Icon(Icons.logout, size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 2),
                          Text(
                            timeFormatter.format(attendance.jamKeluar!),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _getStatusColor(attendance.status).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  attendance.status.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _getStatusColor(attendance.status),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getStatusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.hadir:
        return Icons.check_circle;
      case AttendanceStatus.telat:
        return Icons.warning_amber;
      case AttendanceStatus.izin:
        return Icons.article;
      case AttendanceStatus.cuti:
        return Icons.beach_access;
      case AttendanceStatus.alpha:
        return Icons.cancel;
    }
  }

  void _showDetailDialog(AttendanceModel attendance) {
    final dateFormatter = DateFormat('dd MMMM yyyy', 'id_ID');
    final timeFormatter = DateFormat('HH:mm');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getStatusColor(attendance.status).withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getStatusIcon(attendance.status),
                      color: _getStatusColor(attendance.status),
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          attendance.status.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(attendance.status),
                          ),
                        ),
                        Text(
                          dateFormatter.format(attendance.tanggal),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (attendance.jamMasuk != null)
                      _buildDetailRow(
                        Icons.login,
                        'Jam Masuk',
                        timeFormatter.format(attendance.jamMasuk!),
                      ),
                    if (attendance.jamKeluar != null)
                      _buildDetailRow(
                        Icons.logout,
                        'Jam Keluar',
                        timeFormatter.format(attendance.jamKeluar!),
                      ),
                    _buildDetailRow(
                      Icons.schedule,
                      'Total Jam',
                      attendance.getWorkHours().inHours > 0
                          ? '${attendance.getWorkHours().inHours} jam ${attendance.getWorkHours().inMinutes.remainder(60)} menit'
                          : '-',
                    ),
                    const Divider(height: 16),
                    if (attendance.fotoMasukUrl.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Foto Masuk',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: attendance.fotoMasukUrl,
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  height: 160,
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  height: 160,
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: Icon(Icons.broken_image,
                                        color: Colors.grey),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (attendance.qrCodeUrl.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'QR Code',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: attendance.qrCodeUrl,
                                height: 120,
                                width: 120,
                                fit: BoxFit.contain,
                                placeholder: (_, __) => Container(
                                  height: 120,
                                  width: 120,
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  height: 120,
                                  width: 120,
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: Icon(Icons.qr_code,
                                        color: Colors.grey),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (attendance.catatan.isNotEmpty)
                      _buildDetailRow(
                        Icons.notes,
                        'Catatan',
                        attendance.catatan,
                      ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lokasi',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${attendance.latitudeMasuk.toStringAsFixed(6)}, ${attendance.longitudeMasuk.toStringAsFixed(6)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Tutup'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AttendanceSummary {
  final int hadir;
  final int telat;
  final int izin;
  final int cuti;
  final int alpha;

  const AttendanceSummary({
    required this.hadir,
    required this.telat,
    required this.izin,
    required this.cuti,
    required this.alpha,
  });
}
