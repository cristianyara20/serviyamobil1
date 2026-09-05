import 'service_category_entity.dart';

enum ReservaEstado {
  pendiente,
  aceptada,
  terminada,
  cancelada,
  rechazada;

  String get displayName {
    switch (this) {
      case ReservaEstado.pendiente:
        return 'Pendiente';
      case ReservaEstado.aceptada:
        return 'Aceptada / En Curso';
      case ReservaEstado.terminada:
        return 'Terminada';
      case ReservaEstado.cancelada:
        return 'Cancelada';
      case ReservaEstado.rechazada:
        return 'Rechazada';
    }
  }

  static ReservaEstado fromString(String? val) {
    switch (val?.toLowerCase().trim()) {
      case 'aceptada':
      case 'asignado':
      case 'en camino':
      case 'en curso':
        return ReservaEstado.aceptada;
      case 'terminada':
      case 'completado':
      case 'completada':
      case 'realizada':
        return ReservaEstado.terminada;
      case 'cancelada':
        return ReservaEstado.cancelada;
      case 'rechazada':
        return ReservaEstado.rechazada;
      case 'pendiente':
      default:
        return ReservaEstado.pendiente;
    }
  }
}

class ReservationEntity {
  final int idReserva;
  final int idCliente;
  final int? idPrestador;
  final int idServicio;
  final String nombreServicio;
  final DateTime fechaAgenda;
  final String direccion;
  final String descripcion;
  final ReservaEstado estadoReserva;
  final String? fotoEvidencia;

  ReservationEntity({
    required this.idReserva,
    required this.idCliente,
    this.idPrestador,
    required this.idServicio,
    required this.nombreServicio,
    required this.fechaAgenda,
    required this.direccion,
    required this.descripcion,
    required this.estadoReserva,
    this.fotoEvidencia,
  });

  factory ReservationEntity.fromJson(Map<String, dynamic> json) {
    final idServ = json['id_servicio'] is int
        ? json['id_servicio'] as int
        : int.tryParse(json['id_servicio']?.toString() ?? '1') ?? 1;

    String nombreServ = '';
    if (json['servicios'] != null && json['servicios'] is Map) {
      nombreServ = json['servicios']['nombre_servicio']?.toString() ?? '';
    }
    if (nombreServ.isEmpty) {
      final match = ServiceCategoryEntity.allServices.firstWhere(
        (s) => s.id == idServ,
        orElse: () => ServiceCategoryEntity.allServices.first,
      );
      nombreServ = match.nombre;
    }

    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(
          json['fecha_agenda']?.toString() ?? DateTime.now().toIso8601String());
    } catch (_) {
      parsedDate = DateTime.now();
    }

    final rawFoto = json['detalle_extra']?.toString().trim();
    final fotoUrl = (rawFoto != null && rawFoto.isNotEmpty && rawFoto.startsWith('http'))
        ? rawFoto
        : null;

    return ReservationEntity(
      idReserva: json['id_reserva'] is int
          ? json['id_reserva'] as int
          : int.tryParse(json['id_reserva']?.toString() ?? '0') ?? 0,
      idCliente: json['id_cliente'] is int
          ? json['id_cliente'] as int
          : int.tryParse(json['id_cliente']?.toString() ?? '0') ?? 0,
      idPrestador: json['id_prestador'] != null
          ? (json['id_prestador'] is int
              ? json['id_prestador'] as int
              : int.tryParse(json['id_prestador'].toString()))
          : null,
      idServicio: idServ,
      nombreServicio: nombreServ,
      fechaAgenda: parsedDate,
      direccion: json['direccion']?.toString() ?? '',
      descripcion: json['descripcion']?.toString() ?? '',
      estadoReserva:
          ReservaEstado.fromString(json['estado_reserva']?.toString()),
      fotoEvidencia: fotoUrl,
    );
  }
}