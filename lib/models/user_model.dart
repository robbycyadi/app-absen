class Role {
  final String value;

  const Role._(this.value);

  static const admin = Role._('admin');
  static const manager = Role._('manager');
  static const karyawan = Role._('karyawan');

  static List<Role> get values => [admin, manager, karyawan];

  static Role fromString(String value) {
    switch (value) {
      case 'admin':
        return admin;
      case 'manager':
        return manager;
      case 'karyawan':
        return karyawan;
      default:
        throw ArgumentError('Invalid Role value: $value');
    }
  }

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Role && value == other.value);

  @override
  int get hashCode => value.hashCode;
}

class UserModel {
  final String id;
  final String email;
  final String namaLengkap;
  final String nip;
  final String noTelepon;
  final String alamat;
  final String fotoUrl;
  final Role role;
  final bool isActive;
  final String positionId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.namaLengkap,
    required this.nip,
    required this.noTelepon,
    required this.alamat,
    required this.fotoUrl,
    required this.role,
    required this.isActive,
    required this.positionId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      namaLengkap: json['nama_lengkap'] as String,
      nip: json['nip'] as String,
      noTelepon: json['no_telepon'] as String,
      alamat: json['alamat'] as String,
      fotoUrl: json['foto_url'] as String? ?? '',
      role: Role.fromString(json['role'] as String),
      isActive: json['is_active'] as bool? ?? true,
      positionId: json['position_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nama_lengkap': namaLengkap,
      'nip': nip,
      'no_telepon': noTelepon,
      'alamat': alamat,
      'foto_url': fotoUrl,
      'role': role.toString(),
      'is_active': isActive,
      'position_id': positionId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? namaLengkap,
    String? nip,
    String? noTelepon,
    String? alamat,
    String? fotoUrl,
    Role? role,
    bool? isActive,
    String? positionId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      namaLengkap: namaLengkap ?? this.namaLengkap,
      nip: nip ?? this.nip,
      noTelepon: noTelepon ?? this.noTelepon,
      alamat: alamat ?? this.alamat,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      positionId: positionId ?? this.positionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, namaLengkap: $namaLengkap, nip: $nip, role: $role, isActive: $isActive)';
  }
}
