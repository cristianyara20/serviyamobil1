import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/admin_resena_entity.dart';
import '../../data/repositories/admin_repository_impl.dart';

final adminResenasProvider =
    StateNotifierProvider<AdminResenasController, AsyncValue<List<AdminResenaEntity>>>((ref) {
  return AdminResenasController(ref.watch(adminRepositoryProvider));
});

class AdminResenasController extends StateNotifier<AsyncValue<List<AdminResenaEntity>>> {
  final AdminRepository _repo;

  AdminResenasController(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repo.fetchResenas();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> deleteResena(int idCalificacion) async {
    try {
      await _repo.deleteResena(idCalificacion);
      final current = state.value ?? [];
      state = AsyncValue.data(current.where((r) => r.idCalificacion != idCalificacion).toList());
      return true;
    } catch (_) {
      return false;
    }
  }
}
