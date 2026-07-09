import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:app_absen/models/leave_model.dart';
import 'package:app_absen/providers/leave_provider.dart';

class LeaveApprovalScreen extends StatefulWidget {
  const LeaveApprovalScreen({super.key});

  @override
  State<LeaveApprovalScreen> createState() => _LeaveApprovalScreenState();
}

class _LeaveApprovalScreenState extends State<LeaveApprovalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    context.read<LeaveProvider>().loadPendingApprovals();
  }

  List<LeaveRequestModel> _filterByStatus(
      List<LeaveRequestModel> leaves, LeaveStatus status) {
    return leaves.where((l) => l.status == status).toList();
  }

  void _showApprovalDialog(LeaveRequestModel leave) {
    final catatanController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Detail Pengajuan Cuti'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Karyawan', leave.employeeId),
              _detailRow('Tipe Izin', leave.tipeIzin.displayName()),
              _detailRow(
                'Tanggal',
                '${DateFormat('dd/MM/yyyy').format(leave.tanggalMulai)} - ${DateFormat('dd/MM/yyyy').format(leave.tanggalSelesai)}',
              ),
              _detailRow('Total Hari', '${leave.totalHari} hari'),
              _detailRow('Alasan', leave.alasan),
              if (leave.status != LeaveStatus.pending) ...[
                const Divider(),
                _detailRow('Status', leave.status.toString().toUpperCase()),
                if (leave.catatanApproval.isNotEmpty)
                  _detailRow('Catatan', leave.catatanApproval),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmApprove(LeaveRequestModel leave) async {
    final catatanController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Setujui Cuti'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Setujui pengajuan cuti ini?'),
            const SizedBox(height: 16),
            TextField(
              controller: catatanController,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                hintText: 'Tambahkan catatan...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Setujui'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<LeaveProvider>();
      final success = await provider.approveLeave(
        leave.id,
        catatanController.text.trim().isNotEmpty ? catatanController.text.trim() : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Cuti berhasil disetujui' : 'Gagal menyetujui cuti'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
    catatanController.dispose();
  }

  Future<void> _confirmReject(LeaveRequestModel leave) async {
    final catatanController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tolak Cuti'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tolak pengajuan cuti ini?'),
            const SizedBox(height: 16),
            TextFormField(
              controller: catatanController,
              decoration: const InputDecoration(
                labelText: 'Alasan Penolakan',
                hintText: 'Masukkan alasan penolakan...',
              ),
              maxLines: 3,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Alasan penolakan wajib diisi';
                return null;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (catatanController.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Alasan penolakan wajib diisi')),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<LeaveProvider>();
      final success = await provider.rejectLeave(
        leave.id,
        catatanController.text.trim().isNotEmpty ? catatanController.text.trim() : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Cuti berhasil ditolak' : 'Gagal menolak cuti'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
    catatanController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Approval Cuti'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Disetujui'),
            Tab(text: 'Ditolak'),
          ],
        ),
      ),
      body: Consumer<LeaveProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.pendingApprovals.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadPendingApprovals(),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStatusList(
                  provider,
                  LeaveStatus.pending,
                  dateFormat,
                  showActions: true,
                ),
                _buildStatusList(
                  provider,
                  LeaveStatus.approved,
                  dateFormat,
                  showActions: false,
                ),
                _buildStatusList(
                  provider,
                  LeaveStatus.rejected,
                  dateFormat,
                  showActions: false,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusList(
    LeaveProvider provider,
    LeaveStatus status,
    DateFormat dateFormat, {
    bool showActions = false,
  }) {
    final leaves = _filterByStatus(provider.pendingApprovals, status);

    if (leaves.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == LeaveStatus.pending
                  ? Icons.pending_actions
                  : status == LeaveStatus.approved
                      ? Icons.check_circle
                      : Icons.cancel,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              status == LeaveStatus.pending
                  ? 'Tidak ada pengajuan pending'
                  : status == LeaveStatus.approved
                      ? 'Belum ada yang disetujui'
                      : 'Belum ada yang ditolak',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: leaves.length,
      itemBuilder: (context, index) {
        final leave = leaves[index];
        return _buildLeaveCard(leave, dateFormat, showActions);
      },
    );
  }

  Widget _buildLeaveCard(
    LeaveRequestModel leave,
    DateFormat dateFormat,
    bool showActions,
  ) {
    final statusColor = _getStatusColor(leave.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: statusColor.withOpacity(0.1),
                  child: Icon(Icons.person, color: statusColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        leave.employeeId,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          leave.tipeIzin.displayName(),
                          style: TextStyle(
                            fontSize: 11,
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
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
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  '${dateFormat.format(leave.tanggalMulai)} - ${dateFormat.format(leave.tanggalSelesai)}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const SizedBox(width: 12),
                Icon(Icons.event_note, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  '${leave.totalHari} hari',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                leave.alasan,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (leave.catatanApproval.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.comment, size: 14, color: statusColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        leave.catatanApproval,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (showActions) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showApprovalDialog(leave),
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('Detail'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmApprove(leave),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Setujui'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmReject(leave),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Tolak'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
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
        return 'Pending';
      case LeaveStatus.approved:
        return 'Disetujui';
      case LeaveStatus.rejected:
        return 'Ditolak';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
