import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app.dart';
import '../../config/constants.dart';
import '../../models/attendance_model.dart';
import '../../models/user_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  void _loadData() {
    final auth = context.read<AuthProvider>();
    final attendance = context.read<AttendanceProvider>();

    if (auth.currentUser != null) {
      attendance.loadTodayAttendance(auth.currentUser!.id);
    }
  }

  Future<void> _handleLogout() async {
    final auth = context.read<AuthProvider>();
    await auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.currentUser;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white.withOpacity(0.2),
                backgroundImage: (user?.fotoUrl != null &&
                        user!.fotoUrl.isNotEmpty)
                    ? NetworkImage(user.fotoUrl)
                    : null,
                child: (user?.fotoUrl == null || user!.fotoUrl.isEmpty)
                    ? Text(
                        _getInitials(user?.namaLengkap ?? 'U'),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user?.namaLengkap ?? 'User',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _getRoleDisplay(user?.role),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final user = auth.currentUser;
        final isAdmin = user?.role == Role.admin;
        final isManager = user?.role == Role.manager;
        final isAdminOrManager = isAdmin || isManager;

        return Drawer(
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1A237E),
                      Color(0xFF3949AB),
                    ],
                  ),
                ),
                currentAccountPicture: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  backgroundImage: (user?.fotoUrl != null &&
                          user!.fotoUrl.isNotEmpty)
                      ? NetworkImage(user.fotoUrl)
                      : null,
                  child: (user?.fotoUrl == null || user!.fotoUrl.isEmpty)
                      ? Text(
                          _getInitials(user?.namaLengkap ?? 'U'),
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                accountName: Text(
                  user?.namaLengkap ?? 'User',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                accountEmail: Text(
                  user?.email ?? '',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _drawerItem(
                      icon: Icons.person_outline,
                      title: 'Profil',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, AppRoutes.profile);
                      },
                    ),
                    _drawerItem(
                      icon: Icons.fingerprint,
                      title: 'Absensi',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, AppRoutes.attendance);
                      },
                    ),
                    _drawerItem(
                      icon: Icons.history,
                      title: 'Riwayat Absensi',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, AppRoutes.history);
                      },
                    ),
                    _drawerItem(
                      icon: Icons.event_note,
                      title: 'Pengajuan Izin/Cuti',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, AppRoutes.leaveRequest);
                      },
                    ),
                    _drawerItem(
                      icon: Icons.access_time,
                      title: 'Lembur',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, AppRoutes.overtime);
                      },
                    ),
                    _drawerItem(
                      icon: Icons.receipt_long,
                      title: 'Slip Gaji',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, AppRoutes.payroll);
                      },
                    ),
                    _drawerItem(
                      icon: Icons.bar_chart,
                      title: 'Laporan',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, AppRoutes.reports);
                      },
                    ),
                    if (isAdminOrManager) ...[
                      const Divider(height: 1),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(
                          'ADMIN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      if (isAdmin)
                        _drawerItem(
                          icon: Icons.people_outline,
                          title: 'Kelola Karyawan',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, AppRoutes.employees);
                          },
                        ),
                      if (isAdmin)
                        _drawerItem(
                          icon: Icons.schedule,
                          title: 'Shift',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, AppRoutes.shifts);
                          },
                        ),
                      _drawerItem(
                        icon: Icons.check_circle_outline,
                        title: 'Approve Izin',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                              context, AppRoutes.leaveApproval);
                        },
                      ),
                      _drawerItem(
                        icon: Icons.checklist,
                        title: 'Approve Lembur',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, AppRoutes.overtime);
                        },
                      ),
                      if (isAdmin)
                        _drawerItem(
                          icon: Icons.payments_outlined,
                          title: 'Generate Payroll',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, AppRoutes.payroll);
                          },
                        ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1),
              SafeArea(
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: Text(
                    'Logout',
                    style: GoogleFonts.poppins(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showLogoutDialog();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1A237E)),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 14),
      ),
      onTap: onTap,
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderDateTime(),
            _buildAttendanceStatusCard(),
            _buildCheckInOutButton(),
            _buildQuickStats(),
            _buildRecentAttendance(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderDateTime() {
    final dayName = DateFormat(AppConstants.dateFormatDayName, 'id')
        .format(_now);
    final date = DateFormat(AppConstants.dateFormatFull, 'id').format(_now);
    final time = DateFormat(AppConstants.timeFormat24).format(_now);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        children: [
          Text(
            time,
            style: GoogleFonts.poppins(
              fontSize: 42,
              fontWeight: FontWeight.w300,
              color: const Color(0xFF1A237E),
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$dayName, $date',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceStatusCard() {
    return Consumer<AttendanceProvider>(
      builder: (context, attendance, _) {
        final todayAtt = attendance.todayAttendance;
        final hasCheckIn = todayAtt?.jamMasuk != null;
        final hasCheckOut = todayAtt?.jamKeluar != null;

        AttendanceStatusType statusType;
        if (hasCheckOut) {
          statusType = AttendanceStatusType.complete;
        } else if (hasCheckIn) {
          statusType = AttendanceStatusType.checkedIn;
        } else {
          statusType = AttendanceStatusType.pending;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: _getStatusGradient(statusType),
              boxShadow: [
                BoxShadow(
                  color: _getStatusColor(statusType).withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _getStatusIcon(statusType),
                    size: 36,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _getStatusTitle(statusType),
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusSubtitle(statusType, todayAtt),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (todayAtt != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    DateFormat(AppConstants.timeFormat24)
                        .format(todayAtt.jamMasuk!),
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                    ),
                  ),
                  if (todayAtt.jamKeluar != null)
                    Text(
                      'Keluar: ${DateFormat(AppConstants.timeFormat24).format(todayAtt.jamKeluar!)}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCheckInOutButton() {
    return Consumer2<AuthProvider, AttendanceProvider>(
      builder: (context, auth, attendance, _) {
        final isLoading = attendance.isLoading;
        final todayAtt = attendance.todayAttendance;
        final hasCheckIn = todayAtt?.jamMasuk != null;
        final hasCheckOut = todayAtt?.jamKeluar != null;

        if (hasCheckOut) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: isLoading
                  ? null
                  : () {
                      Navigator.pushNamed(context, AppRoutes.attendance);
                    },
              icon: isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      hasCheckIn ? Icons.logout : Icons.login,
                      size: 24,
                    ),
              label: Text(
                hasCheckIn ? 'Check-out' : 'Check-in',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: hasCheckIn
                    ? const Color(0xFFF57C00)
                    : const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: (hasCheckIn
                        ? const Color(0xFFF57C00)
                        : const Color(0xFF1A237E))
                    .withOpacity(0.4),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Statistik Bulan Ini',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1C1B1F),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  icon: Icons.check_circle,
                  label: 'Hadir',
                  value: '18',
                  color: const Color(0xFF388E3C),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statCard(
                  icon: Icons.description,
                  label: 'Izin',
                  value: '2',
                  color: const Color(0xFFF57C00),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statCard(
                  icon: Icons.beach_access,
                  label: 'Cuti',
                  value: '1',
                  color: const Color(0xFF00BCD4),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statCard(
                  icon: Icons.cancel,
                  label: 'Alpha',
                  value: '0',
                  color: const Color(0xFFD32F2F),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1C1B1F),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAttendance() {
    return Consumer<AttendanceProvider>(
      builder: (context, attendance, _) {
        final history = attendance.history;
        final displayList =
            history.take(5).toList();

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Riwayat Absensi',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1C1B1F),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.history);
                      },
                      child: const Text('Lihat Semua'),
                    ),
                  ],
                ),
              ),
              if (displayList.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.history,
                        size: 40,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Belum ada riwayat absensi',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...displayList.map((att) => _historyItem(att)),
            ],
          ),
        );
      },
    );
  }

  Widget _historyItem(AttendanceModel att) {
    final dateStr =
        DateFormat(AppConstants.dateFormatShort).format(att.tanggal);
    final dayName =
        DateFormat(AppConstants.dateFormatDayName, 'id').format(att.tanggal);
    final statusColor = _getHistoryStatusColor(att.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getHistoryStatusIcon(att.status),
              color: statusColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayName,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1C1B1F),
                  ),
                ),
                Text(
                  dateStr,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (att.jamMasuk != null)
                Text(
                  DateFormat(AppConstants.timeFormat24).format(att.jamMasuk!),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1C1B1F),
                  ),
                ),
              if (att.jamMasuk != null && att.jamKeluar != null)
                Text(
                  DateFormat(AppConstants.timeFormat24)
                      .format(att.jamKeluar!),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getStatusLabel(att.status),
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentNavIndex,
      onTap: (index) {
        setState(() => _currentNavIndex = index);
        switch (index) {
          case 0:
            break;
          case 1:
            Navigator.pushNamed(context, AppRoutes.attendance);
            break;
          case 2:
            Navigator.pushNamed(context, AppRoutes.leaveRequest);
            break;
          case 3:
            Navigator.pushNamed(context, AppRoutes.payroll);
            break;
          case 4:
            Navigator.pushNamed(context, AppRoutes.profile);
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.fingerprint),
          label: 'Absensi',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.event_note_outlined),
          activeIcon: Icon(Icons.event_note),
          label: 'Izin',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          activeIcon: Icon(Icons.receipt_long),
          label: 'Gaji',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profil',
        ),
      ],
    );
  }

  Future<void> _showLogoutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _handleLogout();
    }
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  String _getRoleDisplay(Role? role) {
    if (role == null) return '';
    switch (role) {
      case Role.admin:
        return 'Administrator';
      case Role.manager:
        return 'Manager';
      case Role.karyawan:
        return 'Karyawan';
      default:
        return '';
    }
  }

  Color _getStatusColor(AttendanceStatusType type) {
    switch (type) {
      case AttendanceStatusType.pending:
        return const Color(0xFFF57C00);
      case AttendanceStatusType.checkedIn:
        return const Color(0xFF388E3C);
      case AttendanceStatusType.complete:
        return const Color(0xFF1A237E);
    }
  }

  LinearGradient _getStatusGradient(AttendanceStatusType type) {
    switch (type) {
      case AttendanceStatusType.pending:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF6F00), Color(0xFFF57C00)],
        );
      case AttendanceStatusType.checkedIn:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
        );
      case AttendanceStatusType.complete:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
        );
    }
  }

  IconData _getStatusIcon(AttendanceStatusType type) {
    switch (type) {
      case AttendanceStatusType.pending:
        return Icons.schedule;
      case AttendanceStatusType.checkedIn:
        return Icons.login;
      case AttendanceStatusType.complete:
        return Icons.check_circle;
    }
  }

  String _getStatusTitle(AttendanceStatusType type) {
    switch (type) {
      case AttendanceStatusType.pending:
        return 'Belum Absen';
      case AttendanceStatusType.checkedIn:
        return 'Sudah Absen Masuk';
      case AttendanceStatusType.complete:
        return 'Sudah Absen Keluar';
    }
  }

  String _getStatusSubtitle(
    AttendanceStatusType type,
    AttendanceModel? att,
  ) {
    switch (type) {
      case AttendanceStatusType.pending:
        return 'Silakan lakukan absensi masuk';
      case AttendanceStatusType.checkedIn:
        return 'Jangan lupa absen keluar';
      case AttendanceStatusType.complete:
        return 'Absensi hari ini selesai';
    }
  }

  Color _getHistoryStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.hadir:
        return const Color(0xFF388E3C);
      case AttendanceStatus.izin:
        return const Color(0xFFF57C00);
      case AttendanceStatus.cuti:
        return const Color(0xFF00BCD4);
      case AttendanceStatus.alpha:
        return const Color(0xFFD32F2F);
      case AttendanceStatus.telat:
        return const Color(0xFFFFA000);
    }
  }

  IconData _getHistoryStatusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.hadir:
        return Icons.check_circle;
      case AttendanceStatus.izin:
        return Icons.description;
      case AttendanceStatus.cuti:
        return Icons.beach_access;
      case AttendanceStatus.alpha:
        return Icons.cancel;
      case AttendanceStatus.telat:
        return Icons.warning;
    }
  }

  String _getStatusLabel(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.hadir:
        return 'Hadir';
      case AttendanceStatus.izin:
        return 'Izin';
      case AttendanceStatus.cuti:
        return 'Cuti';
      case AttendanceStatus.alpha:
        return 'Alpha';
      case AttendanceStatus.telat:
        return 'Telat';
    }
  }
}

enum AttendanceStatusType { pending, checkedIn, complete }
