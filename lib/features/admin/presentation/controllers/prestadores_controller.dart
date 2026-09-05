import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/prestador_operativo_entity.dart';
import '../../domain/models/reserva_historial_entity.dart';
import '../../data/repositories/prestadores_repository_impl.dart';

final prestadoresListProvider =
    StateNotifierProvider<PrestadoresController, AsyncValue<List<PrestadorOperativoEntity>>>((ref) {
  return PrestadoresController(ref.watch(prestadoresRepositoryProvider));
});

class PrestadoresController extends StateNotifier<AsyncValue<List<PrestadorOperativoEntity>>> {
  final PrestadoresRepository _repo;

  PrestadoresController(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repo.fetchPrestadores();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<List<ReservaHistorialEntity>> getHistorial(int idPrestador) async {
    return _repo.fetchHistorialServicios(idPrestador: idPrestador);
  }
}
