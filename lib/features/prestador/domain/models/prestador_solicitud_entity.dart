class PrestadorSolicitudEntity {
  final int idReserva;
  final int idCliente;
  final String nombreCliente;
  final String correoCliente;
  final int? idPrestador;
  final int idServicio;
  final String nombreServicio;
  final String fechaAgenda;
  final String direccion;
  final String descripcion;
  final String estadoReserva;
  final String? fotoEvidencia;

  PrestadorSolicitudEntity({
    required this.idReserva,
    required this.idCliente,
    required this.nombreCliente,
    required this.correoCliente,
    this.idPrestador,
    required this.idServicio,
    required this.nombreServicio,
    required this.fechaAgenda,
    required this.direccion,
    required this.descripcion,
    required this.estadoReserva,
    this.fotoEvidencia,
  });

  bool get isPendiente => estadoReserva.toLowerCase() == 'pendiente';
  bool get isEnCurso =>
      estadoReserva.toLowerCase() == 'confirmada' ||
      estadoReserva.toLowerCase() == 'en_progreso' ||
      estadoReserva.toLowerCase() == 'aceptada';
  bool get isCompletada =>
      estadoReserva.toLowerCase() == 'completada' ||
      estadoReserva.toLowerCase() == 'terminada';
  bool get isCancelada =>
      estadoReserva.toLowerCase() == 'cancelada' ||
      estadoReserva.toLowerCase() == 'rechazada';
}
