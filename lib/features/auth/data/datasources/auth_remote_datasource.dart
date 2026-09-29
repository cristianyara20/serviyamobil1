import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../config/env.dart';
import '../../domain/models/user_entity.dart';

class AuthRemoteDataSource {
  final SupabaseClient _supabase;
  final Dio? _dio;

  AuthRemoteDataSource(this._supabase, [this._dio]);


  Future<UserEntity?> fetchUserProfile(String authId, {String? email}) async {
    // 1. Intentar con el esquema seguridad (fuente principal)
    try {
      final response = await _supabase
          .schema('seguridad')
          .from('usuarios')
          .select('id_usuario, auth_id, correo, nombre, apellido, fecha_nacimiento, rol')
          .eq('auth_id', authId)
          .maybeSingle();

      if (response != null) {
        return UserEntity.fromJson(response, authEmail: email);
      }
    } catch (_) {}

    // 2. Fallback: intentar sin esquema especifico
    try {
      final fallback = await _supabase
          .from('usuarios')
          .select('id_usuario, auth_id, correo, nombre, apellido, fecha_nacimiento, rol')
          .eq('auth_id', authId)
          .maybeSingle();

      if (fallback != null) {
        return UserEntity.fromJson(fallback, authEmail: email);
      }
    } catch (_) {}

    // 3. Ultimo recurso: usar metadata del token de Supabase Auth
    final user = _supabase.auth.currentUser;
    if (user != null) {
      final meta = user.userMetadata ?? {};
      return UserEntity(
        id: user.id,
        email: user.email ?? email ?? '',
        nombre: meta['nombre'] ?? '',
        apellido: meta['apellido'] ?? '',
        fechaNacimiento: meta['fecha_nacimiento'],
        rol: UserRole.fromString(meta['rol']),
      );
    }
    return null;
  }

  /// Método de autenticación en la fuente remota de Auth.
  /// 
  /// 1. Envía credenciales a Supabase Auth.
  /// 2. Si la autenticación es exitosa, emite la sesión con el Token JWT (`accessToken`).
  /// 3. Obtiene el perfil de negocio asociado en el esquema `seguridad.usuarios`.
  Future<UserEntity> signInWithPassword({
    required String email,
    required String password,
  }) async {
    // 1. Envía las credenciales cifradas al motor de Supabase Auth
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    // 2. Si la autenticación es correcta, response.session contiene:
    //    - accessToken: Token JWT firmado digitalmente utilizado para peticiones a la API Go.
    //    - refreshToken: Token para renovar la sesión sin volver a pedir contraseña.
    final user = response.user;
    if (user == null) {
      throw const AuthException('No se pudo autenticar el usuario.');
    }

    // 3. Obtener perfil real desde seguridad.usuarios (donde está el rol de negocio del usuario)
    final userProfile = await fetchUserProfile(user.id, email: user.email);
    if (userProfile == null) {
      throw 'No se encontró el perfil del usuario en la base de datos.';
    }

    return userProfile;
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String nombre,
    required String apellido,
    required String fechaNacimiento,
  }) async {
    // Validar formato de fecha (YYYY-MM-DD)
    String? validDate;
    if (fechaNacimiento.isNotEmpty && fechaNacimiento != '--') {
      try {
        final parsed = DateTime.parse(fechaNacimiento);
        validDate =
            '${parsed.year.toString().padLeft(4, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
      } catch (_) {
        validDate = null;
      }
    }

    final payload = {
      'correo': email.trim().toLowerCase(),
      'password': password,
      'nombre': nombre.trim(),
      'apellido': apellido.trim(),
      'fecha_nacimiento': validDate ?? '',
      'rol': 'usuario',
    };

    try {
      final client = _dio ??
          Dio(
            BaseOptions(
              baseUrl: Env.apiBaseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            ),
          );

      final response = await client.post(
        '/auth/register',
        data: payload,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        String errorMsg = 'Error al registrar el usuario';
        if (response.data is Map) {
          final data = response.data as Map;
          errorMsg = data['error'] ?? data['detalle'] ?? errorMsg;
        }
        throw Exception(errorMsg);
      }
    } on DioException catch (e) {
      String errorMessage = 'Error al registrar el usuario';
      if (e.response?.data != null && e.response?.data is Map) {
        final data = e.response!.data as Map;
        errorMessage = data['error'] ?? data['detalle'] ?? errorMessage;
      } else if (e.message != null && e.message!.isNotEmpty) {
        errorMessage = e.message!;
      }
      throw Exception(errorMessage);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;
}
