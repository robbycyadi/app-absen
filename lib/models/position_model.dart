class PositionModel {
  final String id;
  final String namaJabatan;
  final double gajiPokok;
  final double tunjanganTetap;
  final double uangMakan;
  final double uangTransport;

  const PositionModel({
    required this.id,
    required this.namaJabatan,
    required this.gajiPokok,
    required this.tunjanganTetap,
    required this.uangMakan,
    required this.uangTransport,
  });

  factory PositionModel.fromJson(Map<String, dynamic> json) {
    return PositionModel(
      id: json['id'] as String,
      namaJabatan: json['nama_jabatan'] as String,
      gajiPokok: (json['gaji_pokok'] as num).toDouble(),
      tunjanganTetap: (json['tunjangan_tetap'] as num).toDouble(),
      uangMakan: (json['uang_makan'] as num).toDouble(),
      uangTransport: (json['uang_transport'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_jabatan': namaJabatan,
      'gaji_pokok': gajiPokok,
      'tunjangan_tetap': tunjanganTetap,
      'uang_makan': uangMakan,
      'uang_transport': uangTransport,
    };
  }

  PositionModel copyWith({
    String? id,
    String? namaJabatan,
    double? gajiPokok,
    double? tunjanganTetap,
    double? uangMakan,
    double? uangTransport,
  }) {
    return PositionModel(
      id: id ?? this.id,
      namaJabatan: namaJabatan ?? this.namaJabatan,
      gajiPokok: gajiPokok ?? this.gajiPokok,
      tunjanganTetap: tunjanganTetap ?? this.tunjanganTetap,
      uangMakan: uangMakan ?? this.uangMakan,
      uangTransport: uangTransport ?? this.uangTransport,
    );
  }

  @override
  String toString() {
    return 'PositionModel(id: $id, namaJabatan: $namaJabatan, gajiPokok: $gajiPokok)';
  }
}
