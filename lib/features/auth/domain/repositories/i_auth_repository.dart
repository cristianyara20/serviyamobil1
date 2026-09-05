import '../models/user_entity.dart';

abstract class IAuthRepository {
  Future<UserEntity?> getCurrentUser();
  Future<UserEntity> signIn({
    required String email,
    required String password,
  });
  Future<void> signUp({
    required String email,
    required String password,
    required String nombre,
    required String apellido,
    required String fechaNacimiento,
  });
  Future<void> signOut();
  Stream<UserEntity?> authStateChanges();
}
