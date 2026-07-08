class BpjsConfigModel {
  final String id;
  final String namaBpjs;
  final double persentasePerusahaan;
  final double persentaseKaryawan;
  final double maksimalUpah;
  final bool isActive;

  const BpjsConfigModel({
    required this.id,
    required this.namaBpjs,
    required this.persentasePerusahaan,
    required this.persentaseKaryawan,
    required this.maksimalUpah,
    required this.isActive,
  });

  static const double bpjsKesehatanPerusahaan = 4.0;
  static const double bpjsKesehatanKaryawan = 1.0;
  static const double bpjsKetenagakerjaanPerusahaan = 3.7;
  static const double bpjsKetenagakerjaanKaryawan = 2.0;
  static const double bpjsPensiunPerusahaan = 2.0;
  static const double bpjsPensiunKaryawan = 1.0;
  static const double bpjsJKKPerusahaan = 0.24;
  static const double bpjsJKMKaryawan = 0.0;
  static const double bpjsJKMPerusahaan = 0.3;
  static const double bpjsJPPerusahaan = 0.0;
  static const double bpjsJPKaryawan = 0.0;
  static const double maksimalUpahKesehatan = 12000000;
  static const double maksimalUpahKetenagakerjaan = 15000000;

  static Map<String, Map<String, double>> calculateBpjs(double upah) {
    final kesehatanUpah = upah > maksimalUpahKesehatan
        ? maksimalUpahKesehatan
        : upah;
    final ketenagakerjaanUpah = upah > maksimalUpahKetenagakerjaan
        ? maksimalUpahKetenagakerjaan
        : upah;

    return {
      'bpjs_kesehatan': {
        'perusahaan': kesehatanUpah * bpjsKesehatanPerusahaan / 100,
        'karyawan': kesehatanUpah * bpjsKesehatanKaryawan / 100,
      },
      'bpjs_ketenagakerjaan': {
        'perusahaan': ketenagakerjaanUpah * bpjsKetenagakerjaanPerusahaan / 100,
        'karyawan': ketenagakerjaanUpah * bpjsKetenagakerjaanKaryawan / 100,
      },
      'bpjs_pensiun': {
        'perusahaan': ketenagakerjaanUpah * bpjsPensiunPerusahaan / 100,
        'karyawan': ketenagakerjaanUpah * bpjsPensiunKaryawan / 100,
      },
      'bpjs_jkk': {
        'perusahaan': ketenagakerjaanUpah * bpjsJKKPerusahaan / 100,
        'karyawan': ketenagakerjaanUpah * bpjsJKMKaryawan / 100,
      },
      'bpjs_jkm': {
        'perusahaan': ketenagakerjaanUpah * bpjsJKMPerusahaan / 100,
        'karyawan': 0.0,
      },
      'bpjs_jp': {
        'perusahaan': ketenagakerjaanUpah * bpjsJPPerusahaan / 100,
        'karyawan': ketenagakerjaanUpah * bpjsJPKaryawan / 100,
      },
    };
  }

  factory BpjsConfigModel.fromJson(Map<String, dynamic> json) {
    return BpjsConfigModel(
      id: json['id'] as String,
      namaBpjs: json['nama_bpjs'] as String,
      persentasePerusahaan:
          (json['persentase_perusahaan'] as num).toDouble(),
      persentaseKaryawan: (json['persentase_karyawan'] as num).toDouble(),
      maksimalUpah: (json['maksimal_upah'] as num).toDouble(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_bpjs': namaBpjs,
      'persentase_perusahaan': persentasePerusahaan,
      'persentase_karyawan': persentaseKaryawan,
      'maksimal_upah': maksimalUpah,
      'is_active': isActive,
    };
  }

  BpjsConfigModel copyWith({
    String? id,
    String? namaBpjs,
    double? persentasePerusahaan,
    double? persentaseKaryawan,
    double? maksimalUpah,
    bool? isActive,
  }) {
    return BpjsConfigModel(
      id: id ?? this.id,
      namaBpjs: namaBpjs ?? this.namaBpjs,
      persentasePerusahaan:
          persentasePerusahaan ?? this.persentasePerusahaan,
      persentaseKaryawan: persentaseKaryawan ?? this.persentaseKaryawan,
      maksimalUpah: maksimalUpah ?? this.maksimalUpah,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'BpjsConfigModel(id: $id, namaBpjs: $namaBpjs, isActive: $isActive)';
  }
}
