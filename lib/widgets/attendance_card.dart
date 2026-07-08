import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app_absen/models/attendance_model.dart';

class AttendanceCard extends StatelessWidget {
  final AttendanceModel attendance;
  final VoidCallback? onTap;

  const AttendanceCard({
    super.key,
    required this.attendance,
    this.onTap,
  });

  Color _getStatusColor() {
    switch (attendance.status) {
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

  IconData _getStatusIcon() {
    switch (attendance.status) {
      case AttendanceStatus.hadir:
        return Icons.check_circle;
      case AttendanceStatus.telat:
        return Icons.warning;
      case AttendanceStatus.izin:
        return Icons.description;
      case AttendanceStatus.cuti:
        return Icons.beach_access;
      case AttendanceStatus.alpha:
        return Icons.cancel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMMM yyyy', 'id');
    final timeFormat = DateFormat('HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getStatusColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getStatusIcon(),
                  color: _getStatusColor(),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateFormat.format(attendance.tanggal),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (attendance.jamMasuk != null)
                          Text(
                            'Masuk: ${timeFormat.format(attendance.jamMasuk!)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        if (attendance.jamMasuk != null &&
                            attendance.jamKeluar != null)
                          const Text(' | '),
                        if (attendance.jamKeluar != null)
                          Text(
                            'Keluar: ${timeFormat.format(attendance.jamKeluar!)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  attendance.status.name.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
