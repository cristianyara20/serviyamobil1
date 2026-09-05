enum UserRole {
  usuario,
  prestador,
  admin;

  String get displayName {
    switch (this) {
      case UserRole.usuario:
        return 'Usuario / Cliente';
      case UserRole.prestador:
        return 'Prestador de Servicios';
      case UserRole.admin:
        return 'Administrador';
    }
  }

  static UserRole fromString(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'prestador':
        return UserRole.prestador;
      default:
        return UserRole.usuario;
    }
  }
}

class UserEntity {
  final String id;
  final int? idUsuario;
  final String email;
  final String nombre;
  final String apellido;
  final String? fechaNacimiento;
  final UserRole rol;

  UserEntity({
    required this.id,
    this.idUsuario,
    required this.email,
    required this.nombre,
    required this.apellido,
    this.fechaNacimiento,
    required this.rol,
  });

  String get fullName {
    final full = '$nombre $apellido'.trim();
    return full.isNotEmpty ? full : email;
  }

  factory UserEntity.fromJson(Map<String, dynamic> json, {String? authEmail}) {
    int? parsedIdUsuario;
    if (json['id_usuario'] != null) {
      if (json['id_usuario'] is int) {
        parsedIdUsuario = json['id_usuario'] as int;
      } else {
        parsedIdUsuario = int.tryParse(json['id_usuario'].toString());
      }
    }

    return UserEntity(
      id: json['auth_id']?.toString() ?? json['id']?.toString() ?? '',
      idUsuario: parsedIdUsuario,
      email: json['correo']?.toString() ?? json['email']?.toString() ?? authEmail ?? '',
      nombre: json['nombre']?.toString() ?? '',
      apellido: json['apellido']?.toString() ?? '',
      fechaNacimiento: json['fecha_nacimiento']?.toString(),
      rol: UserRole.fromString(json['rol']?.toString()),
    );
  }
}
