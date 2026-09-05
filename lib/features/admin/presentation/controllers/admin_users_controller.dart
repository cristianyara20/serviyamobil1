import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/admin_user_entity.dart';
import '../../data/repositories/admin_repository_impl.dart';

final adminUsersProvider =
    StateNotifierProvider<AdminUsersController, AsyncValue<List<AdminUserEntity>>>((ref) {
  return AdminUsersController(ref.watch(adminRepositoryProvider));
});

class AdminUsersController extends StateNotifier<AsyncValue<List<AdminUserEntity>>> {
  final AdminRepository _repo;

  AdminUsersController(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final users = await _repo.fetchAllUsers();
      state = AsyncValue.data(users);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> createUser({
    required String nombre,
    required String apellido,
    required String correo,
    required String password,
    required String rol,
    String? fechaNacimiento,
  }) async {
    try {
      await _repo.createUser(
        nombre: nombre,
        apellido: apellido,
        correo: correo,
        password: password,
        rol: rol,
        fechaNacimiento: fechaNacimiento,
      );
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteUser(int idUsuario, String authId) async {
    try {
      await _repo.deleteUser(idUsuario, authId);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateUser({
    required int idUsuario,
    required String authId,
    required String nombre,
    required String apellido,
    required String rol,
    String? correo,
    String? password,
    String? fechaNacimiento,
  }) async {
    try {
      await _repo.updateUser(
        idUsuario: idUsuario,
        authId: authId,
        nombre: nombre,
        apellido: apellido,
        rol: rol,
        correo: correo,
        password: password,
        fechaNacimiento: fechaNacimiento,
      );
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }
}
