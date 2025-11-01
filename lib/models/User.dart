class User {
  final int id;
  final String username;
  final String password;
  final String role;
  final String? ten_nv;
  final String? sdt_nv;
  final String? dia_chi_nv;

  User({
    required this.id,
    required this.username,
    required this.password,
    required this.role,
    this.ten_nv,
    this.sdt_nv,
    this.dia_chi_nv,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      role: map['role'],
      ten_nv: map['ten_nv'],
      sdt_nv: map['sdt_nv'],
      dia_chi_nv: map['dia_chi_nv'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'role': role,
      'ten_nv': ten_nv,
      'sdt_nv': sdt_nv,
      'dia_chi_nv': dia_chi_nv,
    };
  }
}