class OvertimeModel {
  final String id;
  final String employeeId;
  final String namaKaryawan;
  final DateTime tanggal;
  final String jamMulai;
  final String jamSelesai;
  final double totalJam;
  final String alasan;
  final StatusOvertime status;
  final String? catatan;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OvertimeModel({
    required this.id,
    required this.employeeId,
    required this.namaKaryawan,
    required this.tanggal,
    required this.jamMulai,
    required this.jamSelesai,
    required this.totalJam,
    required this.alasan,
    required this.status,
    this.catatan,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OvertimeModel.fromJson(Map<String, dynamic> json) {
    return OvertimeModel(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      namaKaryawan: json['nama_karyawan'] as String? ?? '',
      tanggal: DateTime.parse(json['tanggal'] as String),
      jamMulai: json['jam_mulai'] as String,
      jamSelesai: json['jam_selesai'] as String,
      totalJam: (json['total_jam'] as num).toDouble(),
      alasan: json['alasan'] as String,
      status: StatusOvertime.fromString(json['status'] as String),
      catatan: json['catatan'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'nama_karyawan': namaKaryawan,
      'tanggal': tanggal.toIso8601String(),
      'jam_mulai': jamMulai,
      'jam_selesai': jamSelesai,
      'total_jam': totalJam,
      'alasan': alasan,
      'status': status.toString(),
      'catatan': catatan,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  OvertimeModel copyWith({
    String? id,
    String? employeeId,
    String? namaKaryawan,
    DateTime? tanggal,
    String? jamMulai,
    String? jamSelesai,
    double? totalJam,
    String? alasan,
    StatusOvertime? status,
    String? catatan,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OvertimeModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      namaKaryawan: namaKaryawan ?? this.namaKaryawan,
      tanggal: tanggal ?? this.tanggal,
      jamMulai: jamMulai ?? this.jamMulai,
      jamSelesai: jamSelesai ?? this.jamSelesai,
      totalJam: totalJam ?? this.totalJam,
      alasan: alasan ?? this.alasan,
      status: status ?? this.status,
      catatan: catatan ?? this.catatan,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'OvertimeModel(id: $id, employeeId: $employeeId, tanggal: $tanggal, totalJam: $totalJam, status: $status)';
  }
}

enum StatusOvertime {
  pending,
  disetujui,
  ditolak;

  static StatusOvertime fromString(String value) {
    switch (value) {
      case 'pending':
        return StatusOvertime.pending;
      case 'disetujui':
        return StatusOvertime.disetujui;
      case 'ditolak':
        return StatusOvertime.ditolak;
      default:
        throw ArgumentError('Invalid StatusOvertime: $value');
    }
  }

  @override
  String toString() => name;
}
