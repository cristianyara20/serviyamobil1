class PrestadorTopAnalyticsEntity {
  final int idPrestador;
  final String nombrePrestador;
  final String correoPrestador;
  final double calificacion;
  final int totalServicios;

  PrestadorTopAnalyticsEntity({
    required this.idPrestador,
    required this.nombrePrestador,
    required this.correoPrestador,
    required this.calificacion,
    required this.totalServicios,
  });

  factory PrestadorTopAnalyticsEntity.fromJson(Map<String, dynamic> json) {
    return PrestadorTopAnalyticsEntity(
      idPrestador: json['id_prestador'] is int
          ? json['id_prestador'] as int
          : int.tryParse(json['id_prestador']?.toString() ?? '0') ?? 0,
      nombrePrestador: json['nombre_prestador']?.toString() ?? 'Prestador',
      correoPrestador: json['correo_prestador']?.toString() ?? '',
      calificacion: json['calificacion'] != null
          ? (json['calificacion'] as num).toDouble()
          : 0.0,
      totalServicios: json['total_servicios'] is int
          ? json['total_servicios'] as int
          : int.tryParse(json['total_servicios']?.toString() ?? '0') ?? 0,
    );
  }
}

class ServicioPopularEntity {
  final int idServicio;
  final String nombreServicio;
  final String categoria;
  final int vecesSolicitado;

  ServicioPopularEntity({
    required this.idServicio,
    required this.nombreServicio,
    required this.categoria,
    required this.vecesSolicitado,
  });

  factory ServicioPopularEntity.fromJson(Map<String, dynamic> json) {
    return ServicioPopularEntity(
      idServicio: json['id_servicio'] is int
          ? json['id_servicio'] as int
          : int.tryParse(json['id_servicio']?.toString() ?? '0') ?? 0,
      nombreServicio: json['nombre_servicio']?.toString() ?? 'Servicio',
      categoria: json['categoria']?.toString() ?? 'General',
      vecesSolicitado: json['veces_solicitado'] is int
          ? json['veces_solicitado'] as int
          : int.tryParse(json['veces_solicitado']?.toString() ?? '0') ?? 0,
    );
  }
}

class ActividadUsuariosEntity {
  final int mes;
  final int anio;
  final int usuariosNuevos;
  final int usuariosActivos;

  ActividadUsuariosEntity({
    required this.mes,
    required this.anio,
    required this.usuariosNuevos,
    required this.usuariosActivos,
  });

  factory ActividadUsuariosEntity.fromJson(Map<String, dynamic> json) {
    return ActividadUsuariosEntity(
      mes: json['mes'] is int
          ? json['mes'] as int
          : int.tryParse(json['mes']?.toString() ?? '0') ?? 0,
      anio: json['anio'] is int
          ? json['anio'] as int
          : int.tryParse(json['anio']?.toString() ?? '0') ?? 0,
      usuariosNuevos: json['usuarios_nuevos'] is int
          ? json['usuarios_nuevos'] as int
          : int.tryParse(json['usuarios_nuevos']?.toString() ?? '0') ?? 0,
      usuariosActivos: json['usuarios_activos'] is int
          ? json['usuarios_activos'] as int
          : int.tryParse(json['usuarios_activos']?.toString() ?? '0') ?? 0,
    );
  }
}

class AdminReporteConsolidadoEntity {
  final int mes;
  final int anio;
  final int totalReservas;
  final int totalPendientes;
  final int totalAceptadas;
  final int totalCompletadas;
  final int totalCanceladas;
  final int pqrsAbiertas;
  final List<PrestadorTopAnalyticsEntity> topPrestadores;

  AdminReporteConsolidadoEntity({
    required this.mes,
    required this.anio,
    required this.totalReservas,
    required this.totalPendientes,
    required this.totalAceptadas,
    required this.totalCompletadas,
    required this.totalCanceladas,
    required this.pqrsAbiertas,
    required this.topPrestadores,
  });

  factory AdminReporteConsolidadoEntity.fromJson(Map<String, dynamic> json) {
    final list = json['top_prestadores'] as List<dynamic>? ?? [];
    return AdminReporteConsolidadoEntity(
      mes: json['mes'] is int
          ? json['mes'] as int
          : int.tryParse(json['mes']?.toString() ?? '0') ?? 0,
      anio: json['anio'] is int
          ? json['anio'] as int
          : int.tryParse(json['anio']?.toString() ?? '0') ?? 0,
      totalReservas: json['total_reservas'] is int
          ? json['total_reservas'] as int
          : int.tryParse(json['total_reservas']?.toString() ?? '0') ?? 0,
      totalPendientes: json['total_pendientes'] is int
          ? json['total_pendientes'] as int
          : int.tryParse(json['total_pendientes']?.toString() ?? '0') ?? 0,
      totalAceptadas: json['total_aceptadas'] is int
          ? json['total_aceptadas'] as int
          : int.tryParse(json['total_aceptadas']?.toString() ?? '0') ?? 0,
      totalCompletadas: json['total_completadas'] is int
          ? json['total_completadas'] as int
          : int.tryParse(json['total_completadas']?.toString() ?? '0') ?? 0,
      totalCanceladas: json['total_canceladas'] is int
          ? json['total_canceladas'] as int
          : int.tryParse(json['total_canceladas']?.toString() ?? '0') ?? 0,
      pqrsAbiertas: json['pqrs_abiertas'] is int
          ? json['pqrs_abiertas'] as int
          : int.tryParse(json['pqrs_abiertas']?.toString() ?? '0') ?? 0,
      topPrestadores: list
          .map((item) => PrestadorTopAnalyticsEntity.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AdminAnalyticsFullData {
  final AdminReporteConsolidadoEntity consolidado;
  final List<ServicioPopularEntity> servicios;
  final ActividadUsuariosEntity actividad;

  AdminAnalyticsFullData({
    required this.consolidado,
    required this.servicios,
    required this.actividad,
  });
}
