enum LeaveType {
  izin,
  cuti_tahunan,
  cuti_hamil,
  cuti_sakit;

  String displayName() {
    switch (this) {
      case LeaveType.izin:
        return 'Izin';
      case LeaveType.cuti_tahunan:
        return 'Cuti Tahunan';
      case LeaveType.cuti_hamil:
        return 'Cuti Hamil';
      case LeaveType.cuti_sakit:
        return 'Cuti Sakit';
    }
  }

  static LeaveType fromString(String value) {
    switch (value) {
      case 'izin':
        return LeaveType.izin;
      case 'cuti_tahunan':
        return LeaveType.cuti_tahunan;
      case 'cuti_hamil':
        return LeaveType.cuti_hamil;
      case 'cuti_sakit':
        return LeaveType.cuti_sakit;
      default:
        throw ArgumentError('Invalid LeaveType: $value');
    }
  }

  @override
  String toString() => name;
}

enum LeaveStatus {
  pending,
  approved,
  rejected;

  static LeaveStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return LeaveStatus.pending;
      case 'approved':
        return LeaveStatus.approved;
      case 'rejected':
        return LeaveStatus.rejected;
      default:
        throw ArgumentError('Invalid LeaveStatus: $value');
    }
  }

  @override
  String toString() => name;
}

class LeaveRequestModel {
  final String id;
  final String employeeId;
  final LeaveType tipeIzin;
  final DateTime tanggalMulai;
  final DateTime tanggalSelesai;
  final int totalHari;
  final String alasan;
  final LeaveStatus status;
  final String approvedBy;
  final DateTime? approvedAt;
  final String catatanApproval;

  const LeaveRequestModel({
    required this.id,
    required this.employeeId,
    required this.tipeIzin,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.totalHari,
    required this.alasan,
    required this.status,
    required this.approvedBy,
    this.approvedAt,
    required this.catatanApproval,
  });

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) {
    return LeaveRequestModel(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      tipeIzin: LeaveType.fromString(json['tipe_izin'] as String),
      tanggalMulai: DateTime.parse(json['tanggal_mulai'] as String),
      tanggalSelesai: DateTime.parse(json['tanggal_selesai'] as String),
      totalHari: json['total_hari'] as int,
      alasan: json['alasan'] as String,
      status: LeaveStatus.fromString(json['status'] as String),
      approvedBy: json['approved_by'] as String? ?? '',
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      catatanApproval: json['catatan_approval'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'tipe_izin': tipeIzin.toString(),
      'tanggal_mulai': tanggalMulai.toIso8601String(),
      'tanggal_selesai': tanggalSelesai.toIso8601String(),
      'total_hari': totalHari,
      'alasan': alasan,
      'status': status.toString(),
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'catatan_approval': catatanApproval,
    };
  }

  LeaveRequestModel copyWith({
    String? id,
    String? employeeId,
    LeaveType? tipeIzin,
    DateTime? tanggalMulai,
    DateTime? tanggalSelesai,
    int? totalHari,
    String? alasan,
    LeaveStatus? status,
    String? approvedBy,
    DateTime? approvedAt,
    String? catatanApproval,
  }) {
    return LeaveRequestModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      tipeIzin: tipeIzin ?? this.tipeIzin,
      tanggalMulai: tanggalMulai ?? this.tanggalMulai,
      tanggalSelesai: tanggalSelesai ?? this.tanggalSelesai,
      totalHari: totalHari ?? this.totalHari,
      alasan: alasan ?? this.alasan,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      catatanApproval: catatanApproval ?? this.catatanApproval,
    );
  }

  @override
  String toString() {
    return 'LeaveRequestModel(id: $id, employeeId: $employeeId, tipeIzin: $tipeIzin, status: $status)';
  }
}
