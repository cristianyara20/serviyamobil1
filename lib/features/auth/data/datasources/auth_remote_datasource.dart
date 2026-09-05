import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/user_entity.dart';

class AuthRemoteDataSource {
  final SupabaseClient _supabase;

  AuthRemoteDataSource(this._supabase);

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

  Future<UserEntity> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException('No se pudo autenticar el usuario.');
    }

    // Obtener perfil real desde seguridad.usuarios (donde esta el rol real)
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

    final res = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'nombre': nombre,
        'apellido': apellido,
        if (validDate != null) 'fecha_nacimiento': validDate,
        'rol': 'usuario',
      },
    );

    final user = res.user;
    if (user != null) {
      try {
        final existing = await _supabase
            .schema('seguridad')
            .from('usuarios')
            .select('id_usuario')
            .eq('auth_id', user.id)
            .maybeSingle();

        if (existing == null) {
          final inserted = await _supabase
              .schema('seguridad')
              .from('usuarios')
              .insert({
                'auth_id': user.id,
                'correo': email,
                'nombre': nombre,
                'apellido': apellido,
                'rol': 'usuario',
                if (validDate != null) 'fecha_nacimiento': validDate,
              })
              .select('id_usuario')
              .single();

          final idUsuario = inserted['id_usuario'] as int?;
          if (idUsuario != null) {
            await _supabase.schema('gestion').from('clientes').upsert({
              'id_cliente': idUsuario,
              'auth_id': user.id,
            });
          }
        }
      } catch (_) {}
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;
}