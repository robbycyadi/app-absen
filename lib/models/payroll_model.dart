class PayrollModel {
  final String id;
  final String employeeId;
  final String namaKaryawan;
  final int bulan;
  final int tahun;
  final double gajiPokok;
  final double tunjanganTetap;
  final double uangMakan;
  final double uangTransport;
  final double lembur;
  final double thr;
  final double bpjsKesehatan;
  final double bpjsJHT;
  final double bpjsJP;
  final double bpjsJKK;
  final double bpjsJKM;
  final double totalPendapatan;
  final double totalPotongan;
  final double gajiBersih;
  final StatusPayroll status;
  final String? qrCodeUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PayrollModel({
    required this.id,
    required this.employeeId,
    required this.namaKaryawan,
    required this.bulan,
    required this.tahun,
    required this.gajiPokok,
    required this.tunjanganTetap,
    required this.uangMakan,
    required this.uangTransport,
    required this.lembur,
    required this.thr,
    required this.bpjsKesehatan,
    required this.bpjsJHT,
    required this.bpjsJP,
    required this.bpjsJKK,
    required this.bpjsJKM,
    required this.totalPendapatan,
    required this.totalPotongan,
    required this.gajiBersih,
    required this.status,
    this.qrCodeUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PayrollModel.fromJson(Map<String, dynamic> json) {
    return PayrollModel(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      namaKaryawan: json['nama_karyawan'] as String? ?? '',
      bulan: json['bulan'] as int,
      tahun: json['tahun'] as int,
      gajiPokok: (json['gaji_pokok'] as num).toDouble(),
      tunjanganTetap: (json['tunjangan_tetap'] as num).toDouble(),
      uangMakan: (json['uang_makan'] as num).toDouble(),
      uangTransport: (json['uang_transport'] as num).toDouble(),
      lembur: (json['lembur'] as num).toDouble(),
      thr: (json['thr'] as num?)?.toDouble() ?? 0.0,
      bpjsKesehatan: (json['bpjs_kesehatan'] as num).toDouble(),
      bpjsJHT: (json['bpjs_jht'] as num).toDouble(),
      bpjsJP: (json['bpjs_jp'] as num).toDouble(),
      bpjsJKK: (json['bpjs_jkk'] as num).toDouble(),
      bpjsJKM: (json['bpjs_jkm'] as num).toDouble(),
      totalPendapatan: (json['total_pendapatan'] as num).toDouble(),
      totalPotongan: (json['total_potongan'] as num).toDouble(),
      gajiBersih: (json['gaji_bersih'] as num).toDouble(),
      status: StatusPayroll.fromString(json['status'] as String),
      qrCodeUrl: json['qr_code_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'nama_karyawan': namaKaryawan,
      'bulan': bulan,
      'tahun': tahun,
      'gaji_pokok': gajiPokok,
      'tunjangan_tetap': tunjanganTetap,
      'uang_makan': uangMakan,
      'uang_transport': uangTransport,
      'lembur': lembur,
      'thr': thr,
      'bpjs_kesehatan': bpjsKesehatan,
      'bpjs_jht': bpjsJHT,
      'bpjs_jp': bpjsJP,
      'bpjs_jkk': bpjsJKK,
      'bpjs_jkm': bpjsJKM,
      'total_pendapatan': totalPendapatan,
      'total_potongan': totalPotongan,
      'gaji_bersih': gajiBersih,
      'status': status.toString(),
      'qr_code_url': qrCodeUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  PayrollModel copyWith({
    String? id,
    String? employeeId,
    String? namaKaryawan,
    int? bulan,
    int? tahun,
    double? gajiPokok,
    double? tunjanganTetap,
    double? uangMakan,
    double? uangTransport,
    double? lembur,
    double? thr,
    double? bpjsKesehatan,
    double? bpjsJHT,
    double? bpjsJP,
    double? bpjsJKK,
    double? bpjsJKM,
    double? totalPendapatan,
    double? totalPotongan,
    double? gajiBersih,
    StatusPayroll? status,
    String? qrCodeUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PayrollModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      namaKaryawan: namaKaryawan ?? this.namaKaryawan,
      bulan: bulan ?? this.bulan,
      tahun: tahun ?? this.tahun,
      gajiPokok: gajiPokok ?? this.gajiPokok,
      tunjanganTetap: tunjanganTetap ?? this.tunjanganTetap,
      uangMakan: uangMakan ?? this.uangMakan,
      uangTransport: uangTransport ?? this.uangTransport,
      lembur: lembur ?? this.lembur,
      thr: thr ?? this.thr,
      bpjsKesehatan: bpjsKesehatan ?? this.bpjsKesehatan,
      bpjsJHT: bpjsJHT ?? this.bpjsJHT,
      bpjsJP: bpjsJP ?? this.bpjsJP,
      bpjsJKK: bpjsJKK ?? this.bpjsJKK,
      bpjsJKM: bpjsJKM ?? this.bpjsJKM,
      totalPendapatan: totalPendapatan ?? this.totalPendapatan,
      totalPotongan: totalPotongan ?? this.totalPotongan,
      gajiBersih: gajiBersih ?? this.gajiBersih,
      status: status ?? this.status,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'PayrollModel(id: $id, employeeId: $employeeId, bulan: $bulan, tahun: $tahun, gajiBersih: $gajiBersih, status: $status)';
  }
}

enum StatusPayroll {
  draft,
  approved,
  paid;

  static StatusPayroll fromString(String value) {
    switch (value) {
      case 'draft':
        return StatusPayroll.draft;
      case 'approved':
        return StatusPayroll.approved;
      case 'paid':
        return StatusPayroll.paid;
      default:
        throw ArgumentError('Invalid StatusPayroll: $value');
    }
  }

  @override
  String toString() => name;
}
