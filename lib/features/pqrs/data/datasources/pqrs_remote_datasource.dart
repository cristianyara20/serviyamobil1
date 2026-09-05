import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/pqrs_entity.dart';

class PqrsRemoteDataSource {
  final SupabaseClient _supabase;

  PqrsRemoteDataSource(this._supabase);

  /// Resuelve el id_cliente del usuario autenticado desde seguridad.usuarios
  Future<int?> _resolveClienteId() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final result = await _supabase
          .schema('seguridad')
          .from('usuarios')
          .select('id_usuario')
          .eq('auth_id', user.id)
          .maybeSingle();
      if (result != null && result['id_usuario'] != null) {
        return result['id_usuario'] as int?;
      }
    } catch (_) {}

    try {
      if (user.email != null && user.email!.isNotEmpty) {
        final result = await _supabase
            .schema('seguridad')
            .from('usuarios')
            .select('id_usuario')
            .eq('correo', user.email!)
            .maybeSingle();
        if (result != null && result['id_usuario'] != null) {
          return result['id_usuario'] as int?;
        }
      }
    } catch (_) {}

    return null;
  }

  Future<List<PqrsEntity>> fetchPqrs() async {
    final clienteId = await _resolveClienteId();
    if (clienteId == null) return [];

    try {
      final response = await _supabase
          .schema('soporte')
          .from('pqrs')
          .select('*')
          .eq('id_cliente', clienteId)
          .order('id_pqr', ascending: false);

      return (response as List<dynamic>)
          .map((row) => PqrsEntity.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> createPqrs({
    required int idReserva,
    required TipoPqr tipoPqr,
    required String descripcion,
  }) async {
    final clienteId = await _resolveClienteId();
    if (clienteId == null) return false;

    final payload = {
      'id_cliente': clienteId,
      'id_reserva': idReserva,
      'tipo_pqr': tipoPqr.displayName,
      'descripcion': descripcion,
      'estado_pqr': 'Abierto',
    };

    try {
      await _supabase.schema('soporte').from('pqrs').insert(payload);
      return true;
    } catch (e) {
      rethrow;
    }
  }
}