import 'package:flutter/material.dart';

class AdminPqrEntity {
  final int idPqr;
  final int idCliente;
  final String nombreCliente;
  final int? idReserva;
  final String tipoPqr;
  final String descripcion;
  final String estadoPqr;
  final String fechaPqr;
  final String? respuestaAdmin;
  final String? fechaRespuesta;

  AdminPqrEntity({
    required this.idPqr,
    required this.idCliente,
    required this.nombreCliente,
    this.idReserva,
    required this.tipoPqr,
    required this.descripcion,
    required this.estadoPqr,
    required this.fechaPqr,
    this.respuestaAdmin,
    this.fechaRespuesta,
  });

  factory AdminPqrEntity.fromJson(Map<String, dynamic> json) {
    return AdminPqrEntity(
      idPqr: json['id_pqr'] is int
          ? json['id_pqr'] as int
          : int.tryParse(json['id_pqr']?.toString() ?? '0') ?? 0,
      idCliente: json['id_cliente'] is int
          ? json['id_cliente'] as int
          : int.tryParse(json['id_cliente']?.toString() ?? '0') ?? 0,
      nombreCliente: json['nombre_cliente']?.toString() ?? 'Usuario Anónimo',
      idReserva: json['id_reserva'] != null
          ? (json['id_reserva'] is int
              ? json['id_reserva'] as int
              : int.tryParse(json['id_reserva']?.toString() ?? ''))
          : null,
      tipoPqr: json['tipo_pqr']?.toString() ?? 'Peticion',
      descripcion: json['descripcion']?.toString() ?? '',
      estadoPqr: json['estado_pqr']?.toString() ?? 'Abierto',
      fechaPqr: json['fecha_pqr']?.toString() ?? '',
      respuestaAdmin: json['respuesta_admin']?.toString(),
      fechaRespuesta: json['fecha_respuesta']?.toString(),
    );
  }

  String get inicial {
    if (nombreCliente.trim().isEmpty) return 'U';
    return nombreCliente.trim()[0].toUpperCase();
  }

  bool get isCerrado =>
      estadoPqr.toLowerCase() == 'cerrado' ||
      (respuestaAdmin != null && respuestaAdmin!.trim().isNotEmpty);

  bool get isAbierto => !isCerrado;

  Color get tipoColor {
    switch (tipoPqr.toLowerCase()) {
      case 'peticion':
      case 'petición':
        return const Color(0xFF38BDF8); // Azul celeste
      case 'queja':
        return const Color(0xFFFB923C); // Naranja
      case 'reclamo':
        return const Color(0xFFF87171); // Rojo suave
      case 'sugerencia':
        return const Color(0xFFA78BFA); // Púrpura suave
      default:
        return const Color(0xFFE5E7EB);
    }
  }

  Color get estadoColor {
    if (isCerrado) {
      return const Color(0xFF10B981); // Verde
    } else if (estadoPqr.toLowerCase() == 'en proceso' || estadoPqr.toLowerCase() == 'en_proceso') {
      return const Color(0xFFFBBF24); // Amarillo
    }
    return const Color(0xFFF97316); // Naranja (Abierto)
  }
}
