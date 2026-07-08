enum AttendanceStatus {
  hadir,
  izin,
  cuti,
  alpha,
  telat;

  static AttendanceStatus fromString(String value) {
    switch (value) {
      case 'hadir':
        return AttendanceStatus.hadir;
      case 'izin':
        return AttendanceStatus.izin;
      case 'cuti':
        return AttendanceStatus.cuti;
      case 'alpha':
        return AttendanceStatus.alpha;
      case 'telat':
        return AttendanceStatus.telat;
      default:
        throw ArgumentError('Invalid AttendanceStatus: $value');
    }
  }

  @override
  String toString() => name;
}

class AttendanceModel {
  final String id;
  final String employeeId;
  final DateTime tanggal;
  final String shiftId;
  final DateTime? jamMasuk;
  final DateTime? jamKeluar;
  final String fotoMasukUrl;
  final String fotoKeluarUrl;
  final double latitudeMasuk;
  final double longitudeMasuk;
  final double latitudeKeluar;
  final double longitudeKeluar;
  final AttendanceStatus status;
  final String qrCodeUrl;
  final String catatan;

  const AttendanceModel({
    required this.id,
    required this.employeeId,
    required this.tanggal,
    required this.shiftId,
    this.jamMasuk,
    this.jamKeluar,
    required this.fotoMasukUrl,
    required this.fotoKeluarUrl,
    required this.latitudeMasuk,
    required this.longitudeMasuk,
    required this.latitudeKeluar,
    required this.longitudeKeluar,
    required this.status,
    required this.qrCodeUrl,
    required this.catatan,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      tanggal: DateTime.parse(json['tanggal'] as String),
      shiftId: json['shift_id'] as String,
      jamMasuk: json['jam_masuk'] != null
          ? DateTime.parse(json['jam_masuk'] as String)
          : null,
      jamKeluar: json['jam_keluar'] != null
          ? DateTime.parse(json['jam_keluar'] as String)
          : null,
      fotoMasukUrl: json['foto_masuk_url'] as String? ?? '',
      fotoKeluarUrl: json['foto_keluar_url'] as String? ?? '',
      latitudeMasuk: (json['latitude_masuk'] as num?)?.toDouble() ?? 0.0,
      longitudeMasuk: (json['longitude_masuk'] as num?)?.toDouble() ?? 0.0,
      latitudeKeluar: (json['latitude_keluar'] as num?)?.toDouble() ?? 0.0,
      longitudeKeluar: (json['longitude_keluar'] as num?)?.toDouble() ?? 0.0,
      status: AttendanceStatus.fromString(json['status'] as String),
      qrCodeUrl: json['qr_code_url'] as String? ?? '',
      catatan: json['catatan'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'tanggal': tanggal.toIso8601String(),
      'shift_id': shiftId,
      'jam_masuk': jamMasuk?.toIso8601String(),
      'jam_keluar': jamKeluar?.toIso8601String(),
      'foto_masuk_url': fotoMasukUrl,
      'foto_keluar_url': fotoKeluarUrl,
      'latitude_masuk': latitudeMasuk,
      'longitude_masuk': longitudeMasuk,
      'latitude_keluar': latitudeKeluar,
      'longitude_keluar': longitudeKeluar,
      'status': status.toString(),
      'qr_code_url': qrCodeUrl,
      'catatan': catatan,
    };
  }

  bool isLate() {
    if (jamMasuk == null) return false;
    final batas = DateTime(
      jamMasuk!.year,
      jamMasuk!.month,
      jamMasuk!.day,
      8,
      0,
    );
    return jamMasuk!.isAfter(batas);
  }

  Duration getWorkHours() {
    if (jamMasuk == null || jamKeluar == null) return Duration.zero;
    return jamKeluar!.difference(jamMasuk!);
  }

  AttendanceModel copyWith({
    String? id,
    String? employeeId,
    DateTime? tanggal,
    String? shiftId,
    DateTime? jamMasuk,
    DateTime? jamKeluar,
    String? fotoMasukUrl,
    String? fotoKeluarUrl,
    double? latitudeMasuk,
    double? longitudeMasuk,
    double? latitudeKeluar,
    double? longitudeKeluar,
    AttendanceStatus? status,
    String? qrCodeUrl,
    String? catatan,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      tanggal: tanggal ?? this.tanggal,
      shiftId: shiftId ?? this.shiftId,
      jamMasuk: jamMasuk ?? this.jamMasuk,
      jamKeluar: jamKeluar ?? this.jamKeluar,
      fotoMasukUrl: fotoMasukUrl ?? this.fotoMasukUrl,
      fotoKeluarUrl: fotoKeluarUrl ?? this.fotoKeluarUrl,
      latitudeMasuk: latitudeMasuk ?? this.latitudeMasuk,
      longitudeMasuk: longitudeMasuk ?? this.longitudeMasuk,
      latitudeKeluar: latitudeKeluar ?? this.latitudeKeluar,
      longitudeKeluar: longitudeKeluar ?? this.longitudeKeluar,
      status: status ?? this.status,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      catatan: catatan ?? this.catatan,
    );
  }

  @override
  String toString() {
    return 'AttendanceModel(id: $id, employeeId: $employeeId, tanggal: $tanggal, status: $status)';
  }
}
