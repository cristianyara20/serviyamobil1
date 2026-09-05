class AdminUserEntity {
  final int idUsuario;
  final String authId;
  final String nombre;
  final String apellido;
  final String correo;
  final String rol;
  final String? fechaNacimiento;
  final String? fechaRegistro;
  final int numCitas;
  final int numResenas;
  final int numPqrs;

  AdminUserEntity({
    required this.idUsuario,
    required this.authId,
    required this.nombre,
    required this.apellido,
    required this.correo,
    required this.rol,
    this.fechaNacimiento,
    this.fechaRegistro,
    this.numCitas = 0,
    this.numResenas = 0,
    this.numPqrs = 0,
  });

  String get fullName {
    final full = ' '.trim();
    return full.isNotEmpty ? full : correo;
  }

  String get inicial => fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
}
