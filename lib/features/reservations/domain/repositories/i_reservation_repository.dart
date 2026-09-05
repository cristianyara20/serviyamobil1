import '../models/reservation_entity.dart';

abstract class IReservationRepository {
  Future<List<ReservationEntity>> fetchMyReservations();
  Future<ReservationEntity> createReservation({
    required int idServicio,
    required String direccion,
    required String descripcion,
    required DateTime fechaAgenda,
    int? idPrestador,
  });
  Future<bool> cancelReservation(int idReserva);
}