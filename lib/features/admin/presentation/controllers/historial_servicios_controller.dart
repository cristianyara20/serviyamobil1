import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/reserva_historial_entity.dart';
import '../../data/repositories/prestadores_repository_impl.dart';

final historialServiciosProvider =
    StateNotifierProvider<HistorialServiciosController, AsyncValue<List<ReservaHistorialEntity>>>((ref) {
  return HistorialServiciosController(ref.watch(prestadoresRepositoryProvider));
});

class HistorialServiciosController extends StateNotifier<AsyncValue<List<ReservaHistorialEntity>>> {
  final PrestadoresRepository _repo;

  HistorialServiciosController(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repo.fetchHistorialServicios();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
