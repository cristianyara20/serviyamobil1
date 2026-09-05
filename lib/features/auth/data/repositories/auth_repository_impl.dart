import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/supabase_client.dart';
import '../../domain/models/user_entity.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(supabaseClientProvider));
});

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider));
});

class AuthRepositoryImpl implements IAuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<UserEntity?> getCurrentUser() async {
    return await _remoteDataSource.fetchUserProfile('');
  }

  @override
  Future<UserEntity> signIn({
    required String email,
    required String password,
  }) async {
    return await _remoteDataSource.signInWithPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String nombre,
    required String apellido,
    required String fechaNacimiento,
  }) async {
    return await _remoteDataSource.signUp(
      email: email,
      password: password,
      nombre: nombre,
      apellido: apellido,
      fechaNacimiento: fechaNacimiento,
    );
  }

  @override
  Future<void> signOut() async {
    return await _remoteDataSource.signOut();
  }

  @override
  Stream<UserEntity?> authStateChanges() {
    return _remoteDataSource.onAuthStateChange.asyncMap((event) async {
      final user = event.session?.user;
      if (user == null) return null;
      return await _remoteDataSource.fetchUserProfile(user.id, email: user.email);
    });
  }
}
