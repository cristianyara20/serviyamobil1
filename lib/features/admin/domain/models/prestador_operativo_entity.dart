class PrestadorOperativoEntity {
  final int idPrestador;
  final String nombre;
  final String apellido;
  final String correo;
  final String experiencia;
  final double calificacionPromedio;
  final String estadoDisponibilidad; // 'disponible', 'ocupado', 'inactivo'

  PrestadorOperativoEntity({
    required this.idPrestador,
    required this.nombre,
    required this.apellido,
    required this.correo,
    required this.experiencia,
    required this.calificacionPromedio,
    required this.estadoDisponibilidad,
  });

  String get fullName => '$nombre $apellido'.trim().isEmpty ? correo : '$nombre $apellido'.trim();
  String get inicial => fullName.isNotEmpty ? fullName[0].toUpperCase() : 'P';

  bool get isDisponible => estadoDisponibilidad.toLowerCase() == 'disponible';
  bool get isOcupado => estadoDisponibilidad.toLowerCase() == 'ocupado';
  bool get isInactivo => estadoDisponibilidad.toLowerCase() == 'inactivo';

  factory PrestadorOperativoEntity.fromJson(Map<String, dynamic> json) {
    return PrestadorOperativoEntity(
      idPrestador: json['id_prestador'] is int
          ? json['id_prestador'] as int
          : int.tryParse(json['id_prestador']?.toString() ?? '0') ?? 0,
      nombre: json['nombre']?.toString() ?? '',
      apellido: json['apellido']?.toString() ?? '',
      correo: json['correo']?.toString() ?? '',
      experiencia: json['experiencia']?.toString() ?? 'Sin experiencia registrada',
      calificacionPromedio: json['calificacion_promedio'] is num
          ? (json['calificacion_promedio'] as num).toDouble()
          : double.tryParse(json['calificacion_promedio']?.toString() ?? '5.0') ?? 5.0,
      estadoDisponibilidad: json['estado_disponibilidad']?.toString() ?? 'disponible',
    );
  }
}
