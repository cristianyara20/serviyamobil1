import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/pqrs_repository_impl.dart';
import '../../domain/models/pqrs_entity.dart';
import '../../domain/repositories/i_pqrs_repository.dart';

final pqrsListProvider =
    StateNotifierProvider<PqrsController, AsyncValue<List<PqrsEntity>>>((ref) {
  return PqrsController(ref.watch(pqrsRepositoryProvider))..load();
});

class PqrsController extends StateNotifier<AsyncValue<List<PqrsEntity>>> {
  final IPqrsRepository _repository;

  PqrsController(this._repository) : super(const AsyncValue.loading());

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repository.fetchPqrs();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> sendPqrs({
    required int idReserva,
    required TipoPqr tipoPqr,
    required String descripcion,
  }) async {
    try {
      final success = await _repository.createPqrs(
        idReserva: idReserva,
        tipoPqr: tipoPqr,
        descripcion: descripcion,
      );
      if (success) await load();
      return success;
    } catch (_) {
      return false;
    }
  }
}