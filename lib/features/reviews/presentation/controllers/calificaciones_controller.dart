import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/calificacion_repository_impl.dart';
import '../../domain/models/calificacion_entity.dart';
import '../../domain/repositories/i_calificacion_repository.dart';

final calificacionesListProvider = StateNotifierProvider<
    CalificacionesController, AsyncValue<List<CalificacionEntity>>>((ref) {
  return CalificacionesController(ref.watch(calificacionRepositoryProvider))
    ..load();
});

class CalificacionesController
    extends StateNotifier<AsyncValue<List<CalificacionEntity>>> {
  final ICalificacionRepository _repository;

  CalificacionesController(this._repository)
      : super(const AsyncValue.loading());

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repository.fetchCalificaciones();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> sendCalificacion({
    required int idReserva,
    required int puntuacion,
    required String comentario,
  }) async {
    try {
      final success = await _repository.createCalificacion(
        idReserva: idReserva,
        puntuacion: puntuacion,
        comentario: comentario,
      );
      if (success) {
        await load();
      }
      return success;
    } catch (e) {
      return false;
    }
  }
}