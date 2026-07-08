import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:app_absen/models/leave_model.dart';
import 'package:app_absen/providers/leave_provider.dart';
import 'package:app_absen/providers/auth_provider.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _alasanController = TextEditingController();

  LeaveType _tipeIzin = LeaveType.izin;
  DateTime? _tanggalMulai;
  DateTime? _tanggalSelesai;
  int _totalHari = 0;
  int _sisaCuti = 0;
  bool _isSubmitting = false;
  bool _isLoadingSisaCuti = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSisaCuti();
      _loadMyLeaves();
    });
  }

  Future<void> _loadSisaCuti() async {
    setState(() => _isLoadingSisaCuti = true);
    final auth = context.read<AuthProvider>();
    final employeeId = auth.currentUser?.id;
    if (employeeId != null) {
      final sisa = await context.read<LeaveProvider>().getSisaCutiTahunan(employeeId);
      if (mounted) setState(() => _sisaCuti = sisa);
    }
    if (mounted) setState(() => _isLoadingSisaCuti = false);
  }

  Future<void> _loadMyLeaves() async {
    final auth = context.read<AuthProvider>();
    final employeeId = auth.currentUser?.id;
    if (employeeId != null) {
      await context.read<LeaveProvider>().loadMyLeaves(employeeId);
    }
  }

  void _calculateTotalHari() {
    if (_tanggalMulai != null && _tanggalSelesai != null) {
      if (_tanggalSelesai!.isBefore(_tanggalMulai!)) {
        setState(() => _totalHari = 0);
        return;
      }
      int count = 0;
      var date = DateTime(_tanggalMulai!.year, _tanggalMulai!.month, _tanggalMulai!.day);
      final end = DateTime(_tanggalSelesai!.year, _tanggalSelesai!.month, _tanggalSelesai!.day);
      while (!date.isAfter(end)) {
        if (date.weekday != DateTime.saturday && date.weekday != DateTime.sunday) {
          count++;
        }
        date = date.add(const Duration(days: 1));
      }
      setState(() => _totalHari = count);
    } else {
      setState(() => _totalHari = 0);
    }
  }

  Future<void> _pickDate({required bool isMulai}) async {
    final initial = isMulai ? _tanggalMulai : _tanggalSelesai;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isMulai) {
          _tanggalMulai = picked;
          if (_tanggalSelesai != null && _tanggalSelesai!.isBefore(picked)) {
            _tanggalSelesai = picked;
          }
        } else {
          _tanggalSelesai = picked;
          if (_tanggalMulai != null && _tanggalMulai!.isAfter(picked)) {
            _tanggalMulai = picked;
          }
        }
      });
      _calculateTotalHari();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_tipeIzin == LeaveType.cuti_tahunan && _totalHari > _sisaCuti) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sisa cuti tahunan tidak mencukupi')),
      );
      return;
    }

    if (_tanggalMulai == null || _tanggalSelesai == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal mulai dan selesai')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    final data = {
      'employee_id': auth.currentUser?.id ?? '',
      'tipe_izin': _tipeIzin.toString(),
      'tanggal_mulai': _tanggalMulai!.toIso8601String(),
      'tanggal_selesai': _tanggalSelesai!.toIso8601String(),
      'total_hari': _totalHari,
      'alasan': _alasanController.text.trim(),
      'status': LeaveStatus.pending.toString(),
    };

    final provider = context.read<LeaveProvider>();
    final success = await provider.submitLeave(data);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengajuan cuti berhasil dikirim')),
        );
        _alasanController.clear();
        setState(() {
          _tanggalMulai = null;
          _tanggalSelesai = null;
          _totalHari = 0;
          _tipeIzin = LeaveType.izin;
        });
        _loadMyLeaves();
        _loadSisaCuti();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengirim pengajuan cuti')),
        );
      }
    }
  }

  Color _getStatusColor(LeaveStatus status) {
    switch (status) {
      case LeaveStatus.pending:
        return Colors.orange;
      case LeaveStatus.approved:
        return Colors.green;
      case LeaveStatus.rejected:
        return Colors.red;
    }
  }

  String _getStatusLabel(LeaveStatus status) {
    switch (status) {
      case LeaveStatus.pending:
        return 'Menunggu';
      case LeaveStatus.approved:
        return 'Disetujui';
      case LeaveStatus.rejected:
        return 'Ditolak';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengajuan Cuti'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSisaCutiCard(),
            const SizedBox(height: 16),
            _buildFormSection(dateFormat),
            const SizedBox(height: 24),
            _buildPreviousRequests(),
          ],
        ),
      ),
    );
  }

  Widget _buildSisaCutiCard() {
    return Card(
      margin: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          children: [
            const Text(
              'Sisa Cuti Tahunan',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 8),
            if (_isLoadingSisaCuti)
              const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              Text(
                '$_sisaCuti hari',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection(DateFormat dateFormat) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.edit_note, size: 20, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'Form Pengajuan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const Divider(height: 24),
              DropdownButtonFormField<LeaveType>(
                value: _tipeIzin,
                decoration: const InputDecoration(
                  labelText: 'Tipe Izin',
                  prefixIcon: Icon(Icons.category),
                ),
                items: LeaveType.values.map((tipe) {
                  return DropdownMenuItem(
                    value: tipe,
                    child: Text(tipe.displayName()),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _tipeIzin = v);
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Tanggal Mulai'),
                subtitle: Text(
                  _tanggalMulai != null ? dateFormat.format(_tanggalMulai!) : 'Pilih tanggal',
                  style: TextStyle(
                    color: _tanggalMulai != null ? null : Colors.grey.shade400,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _pickDate(isMulai: true),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Tanggal Selesai'),
                subtitle: Text(
                  _tanggalSelesai != null ? dateFormat.format(_tanggalSelesai!) : 'Pilih tanggal',
                  style: TextStyle(
                    color: _tanggalSelesai != null ? null : Colors.grey.shade400,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _pickDate(isMulai: false),
              ),
              if (_totalHari > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calculate, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Total: $_totalHari hari kerja',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _alasanController,
                decoration: const InputDecoration(
                  labelText: 'Alasan',
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                maxLength: 500,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Alasan wajib diisi';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.upload_file, color: Colors.grey.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dokumen Pendukung',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            'Upload file (opsional)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Fitur upload akan segera tersedia')),
                        );
                      },
                      child: const Text('Pilih File'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(_isSubmitting ? 'Mengirim...' : 'Ajukan Cuti'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviousRequests() {
    return Consumer<LeaveProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'Riwayat Pengajuan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (provider.isLoading && provider.myLeaves.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ))
            else if (provider.myLeaves.isEmpty)
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Belum ada pengajuan cuti',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ),
                ),
              )
            else
              ...provider.myLeaves.map((leave) {
                final dateFormat2 = DateFormat('dd/MM/yyyy');
                final statusColor = _getStatusColor(leave.status);

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.event_note,
                            color: statusColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                leave.tipeIzin.displayName(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${dateFormat2.format(leave.tanggalMulai)} - ${dateFormat2.format(leave.tanggalSelesai)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                '${leave.totalHari} hari',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: statusColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            _getStatusLabel(leave.status),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _alasanController.dispose();
    super.dispose();
  }
}
