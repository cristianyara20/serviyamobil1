import '../models/calificacion_entity.dart';

abstract class ICalificacionRepository {
  Future<List<CalificacionEntity>> fetchCalificaciones();
  Future<bool> createCalificacion({
    required int idReserva,
    required int puntuacion,
    required String comentario,
  });
}