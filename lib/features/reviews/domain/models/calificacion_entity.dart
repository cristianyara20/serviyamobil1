class CalificacionEntity {
  final int idCalificacion;
  final int idReserva;
  final int puntuacion;
  final String comentario;
  final DateTime fechaCalificacion;

  CalificacionEntity({
    required this.idCalificacion,
    required this.idReserva,
    required this.puntuacion,
    required this.comentario,
    required this.fechaCalificacion,
  });

  factory CalificacionEntity.fromJson(Map<String, dynamic> json) {
    DateTime parsed;
    try {
      parsed = DateTime.parse(
          json['fecha_calificacion']?.toString() ?? DateTime.now().toIso8601String());
    } catch (_) {
      parsed = DateTime.now();
    }

    return CalificacionEntity(
      idCalificacion: json['id_calificacion'] is int
          ? json['id_calificacion'] as int
          : int.tryParse(json['id_calificacion']?.toString() ?? '0') ?? 0,
      idReserva: json['id_reserva'] is int
          ? json['id_reserva'] as int
          : int.tryParse(json['id_reserva']?.toString() ?? '0') ?? 0,
      puntuacion: json['puntuacion'] is int
          ? json['puntuacion'] as int
          : int.tryParse(json['puntuacion']?.toString() ?? '5') ?? 5,
      comentario: json['comentario']?.toString() ?? '',
      fechaCalificacion: parsed,
    );
  }
}