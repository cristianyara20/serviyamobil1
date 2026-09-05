class ReservaHistorialEntity {
  final int idReserva;
  final int idCliente;
  final String nombreCliente;
  final int? idPrestador;
  final String? nombrePrestador;
  final int idServicio;
  final String nombreServicio;
  final String fechaAgenda;
  final String direccion;
  final String descripcion;
  final String estadoReserva;

  ReservaHistorialEntity({
    required this.idReserva,
    required this.idCliente,
    required this.nombreCliente,
    this.idPrestador,
    this.nombrePrestador,
    required this.idServicio,
    required this.nombreServicio,
    required this.fechaAgenda,
    required this.direccion,
    required this.descripcion,
    required this.estadoReserva,
  });

  factory ReservaHistorialEntity.fromJson(Map<String, dynamic> json) {
    return ReservaHistorialEntity(
      idReserva: json['id_reserva'] is int
          ? json['id_reserva'] as int
          : int.tryParse(json['id_reserva']?.toString() ?? '0') ?? 0,
      idCliente: json['id_cliente'] is int
          ? json['id_cliente'] as int
          : int.tryParse(json['id_cliente']?.toString() ?? '0') ?? 0,
      nombreCliente: json['nombre_cliente']?.toString() ?? 'Cliente',
      idPrestador: json['id_prestador'] != null
          ? (json['id_prestador'] is int
              ? json['id_prestador'] as int
              : int.tryParse(json['id_prestador'].toString()))
          : null,
      nombrePrestador: json['nombre_prestador']?.toString(),
      idServicio: json['id_servicio'] is int
          ? json['id_servicio'] as int
          : int.tryParse(json['id_servicio']?.toString() ?? '0') ?? 0,
      nombreServicio: json['nombre_servicio']?.toString() ?? 'Servicio',
      fechaAgenda: json['fecha_agenda']?.toString() ?? '',
      direccion: json['direccion']?.toString() ?? '',
      descripcion: json['descripcion']?.toString() ?? '',
      estadoReserva: json['estado_reserva']?.toString() ?? 'pendiente',
    );
  }
}
