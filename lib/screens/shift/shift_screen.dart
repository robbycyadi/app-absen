import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:app_absen/models/shift_model.dart';
import 'package:app_absen/models/user_model.dart';
import 'package:app_absen/providers/shift_provider.dart';
import 'package:app_absen/providers/employee_provider.dart';
import 'package:app_absen/providers/auth_provider.dart';

class ShiftScreen extends StatefulWidget {
  const ShiftScreen({super.key});

  @override
  State<ShiftScreen> createState() => _ShiftScreenState();
}

class _ShiftScreenState extends State<ShiftScreen> {
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    context.read<ShiftProvider>().loadShifts();
    final auth = context.read<AuthProvider>();
    _isAdmin = auth.currentUser?.role == Role.admin;
  }

  Future<void> _confirmDelete(ShiftModel shift) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Shift'),
        content: Text('Apakah Anda yakin ingin menghapus shift "${shift.namaShift}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<ShiftProvider>();
      final success = await provider.deleteShift(shift.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Shift berhasil dihapus' : 'Gagal menghapus shift'),
          ),
        );
      }
    }
  }

  void _showShiftForm({ShiftModel? existing}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ShiftFormDialog(
        existingShift: existing,
        onSaved: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(existing != null ? 'Shift berhasil diperbarui' : 'Shift berhasil ditambahkan'),
              ),
            );
          }
        },
      ),
    );
  }

  void _showAssignShiftDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AssignShiftDialog(),
    );
  }

  IconData _getTipeIcon(TipeShift tipe) {
    switch (tipe) {
      case TipeShift.pagi:
        return Icons.wb_sunny;
      case TipeShift.siang:
        return Icons.wb_cloudy;
      case TipeShift.malam:
        return Icons.nightlight_round;
    }
  }

  Color _getTipeColor(TipeShift tipe) {
    switch (tipe) {
      case TipeShift.pagi:
        return Colors.orange;
      case TipeShift.siang:
        return Colors.amber;
      case TipeShift.malam:
        return Colors.indigo;
    }
  }

  String _getTipeLabel(TipeShift tipe) {
    switch (tipe) {
      case TipeShift.pagi:
        return 'Pagi';
      case TipeShift.siang:
        return 'Siang';
      case TipeShift.malam:
        return 'Malam';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shift'),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.assignment_ind),
              tooltip: 'Assign Shift',
              onPressed: _showAssignShiftDialog,
            ),
        ],
      ),
      body: Consumer<ShiftProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.shifts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.shifts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.schedule, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada shift',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tambahkan shift baru untuk memulai',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadShifts(),
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80, top: 8),
              itemCount: provider.shifts.length,
              itemBuilder: (context, index) {
                final shift = provider.shifts[index];
                return _buildShiftCard(shift);
              },
            ),
          );
        },
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              onPressed: () => _showShiftForm(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildShiftCard(ShiftModel shift) {
    final timeFormat = TimeOfDay(
      hour: shift.jamMasuk.hour,
      minute: shift.jamMasuk.minute,
    );
    final tipeColor = _getTipeColor(shift.tipeShift);

    return Dismissible(
      key: Key(shift.id),
      direction: _isAdmin ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Colors.red.shade400,
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async {
        await _confirmDelete(shift);
        return false;
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (_isAdmin) _showShiftForm(existing: shift);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: tipeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getTipeIcon(shift.tipeShift),
                    color: tipeColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shift.namaShift,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: tipeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getTipeLabel(shift.tipeShift),
                          style: TextStyle(
                            fontSize: 11,
                            color: tipeColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${shift.jamMasuk.format(context)} - ${shift.jamKeluar.format(context)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(Icons.chevron_right, color: Colors.grey.shade400),
                    const SizedBox(height: 4),
                    Text(
                      'Toleransi: ${shift.toleransiTerlambat} menit',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShiftFormDialog extends StatefulWidget {
  final ShiftModel? existingShift;
  final VoidCallback onSaved;

  const _ShiftFormDialog({this.existingShift, required this.onSaved});

  @override
  State<_ShiftFormDialog> createState() => _ShiftFormDialogState();
}

class _ShiftFormDialogState extends State<_ShiftFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  TimeOfDay _jamMasuk = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _jamKeluar = const TimeOfDay(hour: 16, minute: 0);
  TipeShift _tipeShift = TipeShift.pagi;
  int _toleransi = 15;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingShift != null) {
      final s = widget.existingShift!;
      _namaController.text = s.namaShift;
      _jamMasuk = s.jamMasuk;
      _jamKeluar = s.jamKeluar;
      _tipeShift = s.tipeShift;
      _toleransi = s.toleransiTerlambat;
    }
  }

  Future<void> _pickTime({required bool isMasuk}) async {
    final initial = isMasuk ? _jamMasuk : _jamKeluar;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() {
        if (isMasuk) {
          _jamMasuk = picked;
        } else {
          _jamKeluar = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final data = {
      'nama_shift': _namaController.text.trim(),
      'tipe_shift': _tipeShift.toString(),
      'jam_masuk': '${_jamMasuk.hour.toString().padLeft(2, '0')}:${_jamMasuk.minute.toString().padLeft(2, '0')}',
      'jam_keluar': '${_jamKeluar.hour.toString().padLeft(2, '0')}:${_jamKeluar.minute.toString().padLeft(2, '0')}',
      'toleransi_terlambat': _toleransi,
    };

    final provider = context.read<ShiftProvider>();
    bool success;
    if (widget.existingShift != null) {
      success = await provider.updateShift(widget.existingShift!.id, data);
    } else {
      success = await provider.createShift(data);
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        widget.onSaved();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan shift')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingShift != null;
    final timeFormat = DateFormat('HH:mm');

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'Edit Shift' : 'Tambah Shift',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama Shift',
                  prefixIcon: Icon(Icons.badge),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Nama shift wajib diisi';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TipeShift>(
                value: _tipeShift,
                decoration: const InputDecoration(
                  labelText: 'Tipe Shift',
                  prefixIcon: Icon(Icons.category),
                ),
                items: TipeShift.values.map((tipe) {
                  String label;
                  switch (tipe) {
                    case TipeShift.pagi:
                      label = 'Pagi';
                      break;
                    case TipeShift.siang:
                      label = 'Siang';
                      break;
                    case TipeShift.malam:
                      label = 'Malam';
                      break;
                  }
                  return DropdownMenuItem(
                    value: tipe,
                    child: Text(label),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _tipeShift = v);
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Jam Masuk'),
                subtitle: Text(
                  '${_jamMasuk.hour.toString().padLeft(2, '0')}:${_jamMasuk.minute.toString().padLeft(2, '0')}',
                ),
                trailing: const Icon(Icons.access_time),
                onTap: () => _pickTime(isMasuk: true),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Jam Keluar'),
                subtitle: Text(
                  '${_jamKeluar.hour.toString().padLeft(2, '0')}:${_jamKeluar.minute.toString().padLeft(2, '0')}',
                ),
                trailing: const Icon(Icons.access_time),
                onTap: () => _pickTime(isMasuk: false),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _toleransi.toString(),
                decoration: const InputDecoration(
                  labelText: 'Toleransi Keterlambatan (menit)',
                  prefixIcon: Icon(Icons.timer),
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  final parsed = int.tryParse(v);
                  if (parsed != null) _toleransi = parsed;
                },
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                  if (int.tryParse(v) == null) return 'Harus angka';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEdit ? 'Simpan Perubahan' : 'Simpan'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
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
    super.dispose();
  }
}

class _AssignShiftDialog extends StatefulWidget {
  @override
  State<_AssignShiftDialog> createState() => _AssignShiftDialogState();
}

class _AssignShiftDialogState extends State<_AssignShiftDialog> {
  String? _selectedEmployeeId;
  String? _selectedShiftId;
  DateTime? _tanggalMulai;
  DateTime? _tanggalSelesai;
  bool _isRecurring = false;
  int _hariMinggu = 1; // 1 = Senin
  bool _isSubmitting = false;
  bool _isLoadingEmployees = false;

  final List<UserModel> _employees = [];

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoadingEmployees = true);
    try {
      final provider = context.read<EmployeeProvider>();
      await provider.loadAllEmployees();
      _employees.addAll(provider.employees.where((e) => e.isActive));
    } catch (_) {}
    if (mounted) setState(() => _isLoadingEmployees = false);
  }

  Future<void> _pickDate({required bool isMulai}) async {
    final initial = isMulai ? _tanggalMulai : _tanggalSelesai;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isMulai) {
          _tanggalMulai = picked;
        } else {
          _tanggalSelesai = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedEmployeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih karyawan')),
      );
      return;
    }
    if (_selectedShiftId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih shift')),
      );
      return;
    }
    if (_tanggalMulai == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal mulai')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final shiftProvider = context.read<ShiftProvider>();
    var currentDate = DateTime(
      _tanggalMulai!.year,
      _tanggalMulai!.month,
      _tanggalMulai!.day,
    );
    final endDate = _tanggalSelesai ?? currentDate;
    bool allSuccess = true;

    while (!currentDate.isAfter(endDate)) {
      if (_isRecurring) {
        if (currentDate.weekday == _hariMinggu) {
          final success = await shiftProvider.assignShiftToEmployee(
            _selectedEmployeeId!,
            _selectedShiftId!,
            currentDate,
          );
          if (!success) allSuccess = false;
        }
      } else {
        final success = await shiftProvider.assignShiftToEmployee(
          _selectedEmployeeId!,
          _selectedShiftId!,
          currentDate,
        );
        if (!success) allSuccess = false;
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (allSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shift berhasil di-assign')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Beberapa shift gagal di-assign')),
        );
      }
    }
  }

  String _dayName(int day) {
    switch (day) {
      case 1: return 'Senin';
      case 2: return 'Selasa';
      case 3: return 'Rabu';
      case 4: return 'Kamis';
      case 5: return 'Jumat';
      case 6: return 'Sabtu';
      case 7: return 'Minggu';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final shiftProvider = context.read<ShiftProvider>();

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assign Shift', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            if (_isLoadingEmployees)
              const LinearProgressIndicator()
            else
              DropdownButtonFormField<String>(
                value: _selectedEmployeeId,
                decoration: const InputDecoration(
                  labelText: 'Karyawan',
                  prefixIcon: Icon(Icons.person),
                ),
                items: _employees.map((emp) {
                  return DropdownMenuItem(
                    value: emp.id,
                    child: Text(emp.namaLengkap),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedEmployeeId = v),
              ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedShiftId,
              decoration: const InputDecoration(
                labelText: 'Shift',
                prefixIcon: Icon(Icons.schedule),
              ),
              items: shiftProvider.shifts.map((shift) {
                return DropdownMenuItem(
                  value: shift.id,
                  child: Text(shift.namaShift),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedShiftId = v),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tanggal Mulai'),
              subtitle: Text(_tanggalMulai != null ? dateFormat.format(_tanggalMulai!) : 'Pilih tanggal'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDate(isMulai: true),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tanggal Selesai'),
              subtitle: Text(_tanggalSelesai != null ? dateFormat.format(_tanggalSelesai!) : 'Pilih tanggal (opsional)'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDate(isMulai: false),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Pola Mingguan'),
              subtitle: const Text('Assign shift hanya pada hari tertentu setiap minggu'),
              value: _isRecurring,
              onChanged: (v) => setState(() => _isRecurring = v),
            ),
            if (_isRecurring) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _hariMinggu,
                decoration: const InputDecoration(
                  labelText: 'Hari',
                  prefixIcon: Icon(Icons.calendar_view_week),
                ),
                items: List.generate(7, (i) {
                  final day = i + 1;
                  return DropdownMenuItem(
                    value: day,
                    child: Text(_dayName(day)),
                  );
                }),
                onChanged: (v) {
                  if (v != null) setState(() => _hariMinggu = v);
                },
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Assign'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
