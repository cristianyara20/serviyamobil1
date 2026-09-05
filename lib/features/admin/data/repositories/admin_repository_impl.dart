import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/admin_user_entity.dart';
import '../../domain/models/admin_resena_entity.dart';
import '../datasources/admin_remote_datasource.dart';

final adminRemoteDataSourceProvider = Provider<AdminRemoteDataSource>((ref) {
  return AdminRemoteDataSource();
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepositoryImpl(ref.watch(adminRemoteDataSourceProvider));
});

abstract class AdminRepository {
  Future<List<AdminUserEntity>> fetchAllUsers();
  Future<void> createUser({
    required String nombre,
    required String apellido,
    required String correo,
    required String password,
    required String rol,
    String? fechaNacimiento,
  });
  Future<void> deleteUser(int idUsuario, String authId);
  Future<void> updateUser({
    required int idUsuario,
    required String authId,
    required String nombre,
    required String apellido,
    required String rol,
    String? correo,
    String? password,
    String? fechaNacimiento,
  });
  Future<List<AdminResenaEntity>> fetchResenas();
  Future<void> deleteResena(int idCalificacion);
}

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource _ds;

  AdminRepositoryImpl(this._ds);

  @override
  Future<List<AdminUserEntity>> fetchAllUsers() => _ds.fetchAllUsers();

  @override
  Future<void> createUser({
    required String nombre,
    required String apellido,
    required String correo,
    required String password,
    required String rol,
    String? fechaNacimiento,
  }) =>
      _ds.createUser(
        nombre: nombre,
        apellido: apellido,
        correo: correo,
        password: password,
        rol: rol,
        fechaNacimiento: fechaNacimiento,
      );

  @override
  Future<void> deleteUser(int idUsuario, String authId) =>
      _ds.deleteUser(idUsuario, authId);

  @override
  Future<void> updateUser({
    required int idUsuario,
    required String authId,
    required String nombre,
    required String apellido,
    required String rol,
    String? correo,
    String? password,
    String? fechaNacimiento,
  }) => _ds.updateUser(
        idUsuario: idUsuario,
        authId: authId,
        nombre: nombre,
        apellido: apellido,
        rol: rol,
        correo: correo,
        password: password,
        fechaNacimiento: fechaNacimiento,
      );

  @override
  Future<List<AdminResenaEntity>> fetchResenas() => _ds.fetchResenas();

  @override
  Future<void> deleteResena(int idCalificacion) => _ds.deleteResena(idCalificacion);
}
