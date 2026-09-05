import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/reservation_repository_impl.dart';
import '../../domain/models/reservation_entity.dart';
import '../../domain/repositories/i_reservation_repository.dart';

final reservationsListProvider =
    StateNotifierProvider<ReservationsController, AsyncValue<List<ReservationEntity>>>((ref) {
  return ReservationsController(ref.watch(reservationRepositoryProvider))..load();
});

class ReservationsController
    extends StateNotifier<AsyncValue<List<ReservationEntity>>> {
  final IReservationRepository _repository;

  ReservationsController(this._repository) : super(const AsyncValue.loading());

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repository.fetchMyReservations();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> create({
    required int idServicio,
    required String direccion,
    required String descripcion,
    required DateTime fechaAgenda,
    int? idPrestador,
  }) async {
    try {
      final newRes = await _repository.createReservation(
        idServicio: idServicio,
        direccion: direccion,
        descripcion: descripcion,
        fechaAgenda: fechaAgenda,
        idPrestador: idPrestador,
      );

      final current = state.value ?? [];
      state = AsyncValue.data([newRes, ...current]);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> cancel(int idReserva) async {
    try {
      final success = await _repository.cancelReservation(idReserva);
      if (success) {
        final current = state.value ?? [];
        final updated = current.map((r) {
          if (r.idReserva == idReserva) {
            return ReservationEntity(
              idReserva: r.idReserva,
              idCliente: r.idCliente,
              idPrestador: r.idPrestador,
              idServicio: r.idServicio,
              nombreServicio: r.nombreServicio,
              fechaAgenda: r.fechaAgenda,
              direccion: r.direccion,
              descripcion: r.descripcion,
              estadoReserva: ReservaEstado.cancelada,
            );
          }
          return r;
        }).toList();
        state = AsyncValue.data(updated);
      }
      return success;
    } catch (e) {
      return false;
    }
  }
}