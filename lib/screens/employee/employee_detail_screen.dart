import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:app_absen/models/user_model.dart';
import 'package:app_absen/models/position_model.dart';
import 'package:app_absen/models/attendance_model.dart';
import 'package:app_absen/providers/employee_provider.dart';
import 'package:app_absen/providers/auth_provider.dart';
import 'package:app_absen/providers/attendance_provider.dart';

class EmployeeDetailScreen extends StatefulWidget {
  const EmployeeDetailScreen({super.key});

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  bool _isEditing = false;
  bool _isAdmin = false;
  late UserModel _employee;

  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _nipController = TextEditingController();
  final _emailController = TextEditingController();
  final _noTeleponController = TextEditingController();
  final _alamatController = TextEditingController();
  Role _selectedRole = Role.karyawan;
  String _selectedPositionId = '';

  List<PositionModel> _positions = [];
  List<AttendanceModel> _recentAttendance = [];
  int _hadirCount = 0;
  int _telatCount = 0;
  int _izinCount = 0;
  int _alphaCount = 0;
  bool _isLoadingAttendance = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is UserModel) {
      _employee = args;
      _populateForm(_employee);
      _loadAttendanceStats(_employee.id);
    } else {
      final provider = context.read<EmployeeProvider>();
      if (provider.selectedEmployee != null) {
        _employee = provider.selectedEmployee!;
        _populateForm(_employee);
        _loadAttendanceStats(_employee.id);
      }
    }

    final auth = context.read<AuthProvider>();
    _isAdmin = auth.currentUser?.role == Role.admin;

    _loadPositions();
  }

  void _populateForm(UserModel emp) {
    _namaController.text = emp.namaLengkap;
    _nipController.text = emp.nip;
    _emailController.text = emp.email;
    _noTeleponController.text = emp.noTelepon;
    _alamatController.text = emp.alamat;
    _selectedRole = emp.role;
    _selectedPositionId = emp.positionId;
  }

  Future<void> _loadPositions() async {
    _positions = [
      const PositionModel(
        id: 'pos-1', namaJabatan: 'Staff',
        gajiPokok: 4000000, tunjanganTetap: 500000,
        uangMakan: 300000, uangTransport: 200000,
      ),
      const PositionModel(
        id: 'pos-2', namaJabatan: 'Senior Staff',
        gajiPokok: 6000000, tunjanganTetap: 700000,
        uangMakan: 400000, uangTransport: 300000,
      ),
      const PositionModel(
        id: 'pos-3', namaJabatan: 'Supervisor',
        gajiPokok: 8000000, tunjanganTetap: 1000000,
        uangMakan: 500000, uangTransport: 400000,
      ),
      const PositionModel(
        id: 'pos-4', namaJabatan: 'Manager',
        gajiPokok: 12000000, tunjanganTetap: 1500000,
        uangMakan: 700000, uangTransport: 500000,
      ),
    ];
    setState(() {});
  }

  Future<void> _loadAttendanceStats(String employeeId) async {
    setState(() => _isLoadingAttendance = true);
    try {
      final attendanceProvider = context.read<AttendanceProvider>();
      final now = DateTime.now();
      await attendanceProvider.loadHistory(employeeId, now.month, now.year);
      _recentAttendance = attendanceProvider.history;

      _hadirCount = _recentAttendance
          .where((a) => a.status == AttendanceStatus.hadir)
          .length;
      _telatCount = _recentAttendance
          .where((a) => a.status == AttendanceStatus.telat)
          .length;
      _izinCount = _recentAttendance
          .where((a) => a.status == AttendanceStatus.izin)
          .length;
      _alphaCount = _recentAttendance
          .where((a) => a.status == AttendanceStatus.alpha)
          .length;
    } catch (_) {}
    if (mounted) setState(() => _isLoadingAttendance = false);
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'nama_lengkap': _namaController.text.trim(),
      'nip': _nipController.text.trim(),
      'email': _emailController.text.trim(),
      'no_telepon': _noTeleponController.text.trim(),
      'alamat': _alamatController.text.trim(),
      'role': _selectedRole.toString(),
      'position_id': _selectedPositionId,
    };

    final provider = context.read<EmployeeProvider>();
    final success = await provider.updateEmployee(_employee.id, data);

    if (mounted) {
      if (success) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data karyawan berhasil diperbarui')),
        );
        if (provider.selectedEmployee != null) {
          setState(() {
            _employee = provider.selectedEmployee!;
            _populateForm(_employee);
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memperbarui data')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_employee.namaLengkap),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: Icon(_isEditing ? Icons.close : Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = !_isEditing;
                  if (!_isEditing) _populateForm(_employee);
                });
              },
            ),
        ],
      ),
      body: Consumer<EmployeeProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && _employee.id.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildProfileHeader(),
                if (_isEditing) _buildEditForm() else _buildInfoSection(),
                _buildAttendanceStats(),
                _buildRecentAttendance(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundImage: _employee.fotoUrl.isNotEmpty
                ? NetworkImage(_employee.fotoUrl)
                : null,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: _employee.fotoUrl.isEmpty
                ? Text(
                    _employee.namaLengkap.isNotEmpty
                        ? _employee.namaLengkap[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            _employee.namaLengkap,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _employee.nip,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 8),
          _buildRoleBadge(_employee.role),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _employee.isActive ? Icons.check_circle : Icons.cancel,
                size: 16,
                color: _employee.isActive ? Colors.greenAccent : Colors.redAccent,
              ),
              const SizedBox(width: 4),
              Text(
                _employee.isActive ? 'Aktif' : 'Nonaktif',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(Role role) {
    Color color = Colors.grey;
    switch (role) {
      case Role.admin:
        color = Colors.red;
        break;
      case Role.manager:
        color = Colors.orange;
        break;
      case Role.karyawan:
        color = Colors.blue;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        role.toString().toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            title: 'Informasi Pribadi',
            icon: Icons.person,
            children: [
              _infoRow('Email', _employee.email),
              _infoRow('No. Telepon', _employee.noTelepon.isNotEmpty ? _employee.noTelepon : '-'),
              _infoRow('Alamat', _employee.alamat.isNotEmpty ? _employee.alamat : '-'),
            ],
          ),
          const SizedBox(height: 8),
          _buildPositionCard(),
          const SizedBox(height: 8),
          _buildShiftCard(),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionCard() {
    final position = _positions.where((p) => p.id == _employee.positionId).firstOrNull;
    final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return _buildInfoCard(
      title: 'Posisi & Gaji',
      icon: Icons.work,
      children: [
        _infoRow('Jabatan', position?.namaJabatan ?? '-'),
        _infoRow('Gaji Pokok', position != null ? currencyFormat.format(position.gajiPokok) : '-'),
        _infoRow('Tunjangan Tetap', position != null ? currencyFormat.format(position.tunjanganTetap) : '-'),
        _infoRow('Uang Makan', position != null ? currencyFormat.format(position.uangMakan) : '-'),
        _infoRow('Uang Transport', position != null ? currencyFormat.format(position.uangTransport) : '-'),
      ],
    );
  }

  Widget _buildShiftCard() {
    return _buildInfoCard(
      title: 'Jadwal Shift',
      icon: Icons.schedule,
      children: [
        _infoRow('Shift', 'Belum diatur'),
        _infoRow('Jam Masuk', '-'),
        _infoRow('Jam Keluar', '-'),
      ],
    );
  }

  Widget _buildEditForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.edit, size: 20, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'Edit Data Karyawan',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    TextFormField(
                      controller: _namaController,
                      decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nipController,
                      decoration: const InputDecoration(labelText: 'NIP'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                        if (!v.contains('@')) return 'Email tidak valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _noTeleponController,
                      decoration: const InputDecoration(labelText: 'No. Telepon'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _alamatController,
                      decoration: const InputDecoration(labelText: 'Alamat'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Role>(
                      value: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        prefixIcon: Icon(Icons.shield),
                      ),
                      items: Role.values.map((role) {
                        return DropdownMenuItem(
                          value: role,
                          child: Text(role.toString().toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedRole = v);
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedPositionId,
                      decoration: const InputDecoration(
                        labelText: 'Posisi / Jabatan',
                        prefixIcon: Icon(Icons.work),
                      ),
                      items: _positions.map((pos) {
                        final posName = pos.namaJabatan;
                        return DropdownMenuItem(
                          value: pos.id,
                          child: Text(posName),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedPositionId = v);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveChanges,
                icon: const Icon(Icons.save),
                label: const Text('Simpan Perubahan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceStats() {
    final total = _hadirCount + _telatCount + _izinCount + _alphaCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.bar_chart, size: 20, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'Statistik Bulan Ini',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const Divider(height: 24),
              if (_isLoadingAttendance)
                const Center(child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ))
              else ...[
                Row(
                  children: [
                    _statItem('Hadir', _hadirCount, Colors.green, total),
                    _statItem('Telat', _telatCount, Colors.orange, total),
                    _statItem('Izin', _izinCount, Colors.blue, total),
                    _statItem('Alpha', _alphaCount, Colors.red, total),
                  ],
                ),
                if (total > 0) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 8,
                      child: Row(
                        children: [
                          if (_hadirCount > 0)
                            Flexible(
                              flex: _hadirCount,
                              child: Container(color: Colors.green),
                            ),
                          if (_telatCount > 0)
                            Flexible(
                              flex: _telatCount,
                              child: Container(color: Colors.orange),
                            ),
                          if (_izinCount > 0)
                            Flexible(
                              flex: _izinCount,
                              child: Container(color: Colors.blue),
                            ),
                          if (_alphaCount > 0)
                            Flexible(
                              flex: _alphaCount,
                              child: Container(color: Colors.red),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statItem(String label, int count, Color color, int total) {
    return Expanded(
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          if (total > 0)
            Text(
              '${(count / total * 100).toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentAttendance() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.history, size: 20, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'Riwayat Absensi Terbaru',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const Divider(height: 24),
              if (_isLoadingAttendance)
                const Center(child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ))
              else if (_recentAttendance.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'Belum ada data absensi',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ),
                )
              else
                ...List.generate(
                  _recentAttendance.length > 10 ? 10 : _recentAttendance.length,
                  (index) {
                    final att = _recentAttendance[index];
                    final dateFormat = DateFormat('dd/MM/yyyy');
                    final timeFormat = DateFormat('HH:mm');

                    Color statusColor;
                    String statusText;
                    switch (att.status) {
                      case AttendanceStatus.hadir:
                        statusColor = Colors.green;
                        statusText = 'Hadir';
                        break;
                      case AttendanceStatus.telat:
                        statusColor = Colors.orange;
                        statusText = 'Telat';
                        break;
                      case AttendanceStatus.izin:
                        statusColor = Colors.blue;
                        statusText = 'Izin';
                        break;
                      case AttendanceStatus.cuti:
                        statusColor = Colors.purple;
                        statusText = 'Cuti';
                        break;
                      case AttendanceStatus.alpha:
                        statusColor = Colors.red;
                        statusText = 'Alpha';
                        break;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            dateFormat.format(att.tanggal),
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(width: 16),
                          if (att.jamMasuk != null)
                            Text(
                              timeFormat.format(att.jamMasuk!),
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            ),
                          if (att.jamMasuk != null) const Text(' - '),
                          if (att.jamKeluar != null)
                            Text(
                              timeFormat.format(att.jamKeluar!),
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 11,
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _nipController.dispose();
    _emailController.dispose();
    _noTeleponController.dispose();
    _alamatController.dispose();
    super.dispose();
  }
}
