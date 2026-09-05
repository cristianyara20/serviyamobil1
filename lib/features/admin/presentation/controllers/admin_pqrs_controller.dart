import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/admin_pqrs_repository_impl.dart';
import '../../domain/models/admin_pqr_entity.dart';
import '../../domain/repositories/i_admin_pqrs_repository.dart';

final adminPqrsProvider =
    StateNotifierProvider<AdminPqrsController, AsyncValue<List<AdminPqrEntity>>>((ref) {
  final repo = ref.watch(adminPqrsRepositoryProvider);
  return AdminPqrsController(repo)..load();
});

class AdminPqrsController extends StateNotifier<AsyncValue<List<AdminPqrEntity>>> {
  final IAdminPqrsRepository _repository;

  AdminPqrsController(this._repository) : super(const AsyncValue.loading());

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repository.fetchPqrs();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> responderPqr({required int idPqr, required String respuestaAdmin}) async {
    final ok = await _repository.responderPqr(idPqr: idPqr, respuestaAdmin: respuestaAdmin);
    if (ok) {
      // Actualizamos optimistamente el estado local
      state.whenData((currentList) {
        final updated = currentList.map((p) {
          if (p.idPqr == idPqr) {
            return AdminPqrEntity(
              idPqr: p.idPqr,
              idCliente: p.idCliente,
              nombreCliente: p.nombreCliente,
              idReserva: p.idReserva,
              tipoPqr: p.tipoPqr,
              descripcion: p.descripcion,
              estadoPqr: 'Cerrado',
              fechaPqr: p.fechaPqr,
              respuestaAdmin: respuestaAdmin,
              fechaRespuesta: DateTime.now().toIso8601String(),
            );
          }
          return p;
        }).toList();
        state = AsyncValue.data(updated);
      });
      // Recargamos en segundo plano
      load();
    }
    return ok;
  }
}
