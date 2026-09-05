class PqrsEntity {
  final int idPqr;
  final int idCliente;
  final int idReserva;
  final String tipoPqr;
  final String descripcion;
  final String estadoPqr;
  final String? respuestaAdmin;

  PqrsEntity({
    required this.idPqr,
    required this.idCliente,
    required this.idReserva,
    required this.tipoPqr,
    required this.descripcion,
    required this.estadoPqr,
    this.respuestaAdmin,
  });

  factory PqrsEntity.fromJson(Map<String, dynamic> json) {
    return PqrsEntity(
      idPqr: json['id_pqr'] is int
          ? json['id_pqr'] as int
          : int.tryParse(json['id_pqr']?.toString() ?? '0') ?? 0,
      idCliente: json['id_cliente'] is int
          ? json['id_cliente'] as int
          : int.tryParse(json['id_cliente']?.toString() ?? '0') ?? 0,
      idReserva: json['id_reserva'] is int
          ? json['id_reserva'] as int
          : int.tryParse(json['id_reserva']?.toString() ?? '0') ?? 0,
      tipoPqr: json['tipo_pqr']?.toString() ?? 'Peticion',
      descripcion: json['descripcion']?.toString() ?? '',
      estadoPqr: json['estado_pqr']?.toString() ?? 'Abierto',
      respuestaAdmin: json['respuesta_admin']?.toString(),
    );
  }
}

enum TipoPqr {
  peticion,
  queja,
  reclamo,
  sugerencia;

  String get displayName {
    switch (this) {
      case TipoPqr.peticion:
        return 'Peticion';
      case TipoPqr.queja:
        return 'Queja';
      case TipoPqr.reclamo:
        return 'Reclamo';
      case TipoPqr.sugerencia:
        return 'Sugerencia';
    }
  }

  String get icon {
    switch (this) {
      case TipoPqr.peticion:
        return '📋';
      case TipoPqr.queja:
        return '⚠️';
      case TipoPqr.reclamo:
        return '🔴';
      case TipoPqr.sugerencia:
        return '💡';
    }
  }

  static TipoPqr fromString(String s) {
    switch (s.toLowerCase()) {
      case 'queja':
        return TipoPqr.queja;
      case 'reclamo':
        return TipoPqr.reclamo;
      case 'sugerencia':
        return TipoPqr.sugerencia;
      default:
        return TipoPqr.peticion;
    }
  }
}