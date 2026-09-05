class PrestadorStatsEntity {
  final int completados;
  final double calificacion;
  final int activos;
  final String disponibilidad; // disponible, ocupado, inactivo
  final String nivel; // Novato, Avanzado, Experto, Maestro
  final double progresoMeta; // 0.0 to 1.0

  PrestadorStatsEntity({
    required this.completados,
    required this.calificacion,
    required this.activos,
    required this.disponibilidad,
    required this.nivel,
    required this.progresoMeta,
  });
}
