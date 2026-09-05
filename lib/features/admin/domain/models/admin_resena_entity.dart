class AdminResenaEntity {
  final int idCalificacion;
  final int idReserva;
  final double puntuacion;
  final String comentario;
  final String fechaCalificacion;
  final String nombreCliente;
  final String nombrePrestador;
  final String nombreServicio;

  AdminResenaEntity({
    required this.idCalificacion,
    required this.idReserva,
    required this.puntuacion,
    required this.comentario,
    required this.fechaCalificacion,
    required this.nombreCliente,
    required this.nombrePrestador,
    required this.nombreServicio,
  });

  String get inicialCliente =>
      nombreCliente.isNotEmpty ? nombreCliente[0].toUpperCase() : 'U';

  factory AdminResenaEntity.fromJson(Map<String, dynamic> json) {
    double parseScore(dynamic val) {
      if (val == null) return 5.0;
      if (val is double) return val;
      if (val is int) return val.toDouble();
      return double.tryParse(val.toString()) ?? 5.0;
    }

    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      return int.tryParse(val.toString()) ?? 0;
    }

    return AdminResenaEntity(
      idCalificacion: parseInt(json['id_calificacion']),
      idReserva: parseInt(json['id_reserva']),
      puntuacion: parseScore(json['puntuacion']),
      comentario: json['comentario']?.toString() ?? '',
      fechaCalificacion: json['fecha_calificacion']?.toString() ?? '',
      nombreCliente: json['nombre_cliente']?.toString() ?? 'Cliente',
      nombrePrestador: json['nombre_prestador']?.toString() ?? 'Prestador',
      nombreServicio: json['nombre_servicio']?.toString() ?? 'Servicio',
    );
  }
}
