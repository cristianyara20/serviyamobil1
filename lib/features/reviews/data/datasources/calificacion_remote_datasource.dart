import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/calificacion_entity.dart';

class CalificacionRemoteDataSource {
  final SupabaseClient _supabase;

  CalificacionRemoteDataSource(this._supabase);

  Future<int?> _resolveClienteId() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final userSeg = await _supabase
          .schema('seguridad')
          .from('usuarios')
          .select('id_usuario')
          .eq('auth_id', user.id)
          .maybeSingle();

      if (userSeg != null && userSeg['id_usuario'] != null) {
        final idUsuario = userSeg['id_usuario'] is int
            ? userSeg['id_usuario'] as int
            : int.tryParse(userSeg['id_usuario'].toString());
        if (idUsuario != null) return idUsuario;
      }
    } catch (_) {}

    try {
      if (user.email != null && user.email!.isNotEmpty) {
        final userByEmail = await _supabase
            .schema('seguridad')
            .from('usuarios')
            .select('id_usuario')
            .eq('correo', user.email!)
            .maybeSingle();

        if (userByEmail != null && userByEmail['id_usuario'] != null) {
          final idUsuario = userByEmail['id_usuario'] is int
              ? userByEmail['id_usuario'] as int
              : int.tryParse(userByEmail['id_usuario'].toString());
          if (idUsuario != null) return idUsuario;
        }
      }
    } catch (_) {}

    return null;
  }

  Future<List<CalificacionEntity>> fetchCalificaciones() async {
    final clienteId = await _resolveClienteId();
    if (clienteId == null) return [];

    try {
      // 1. Obtener las reservas del cliente
      final reservas = await _supabase
          .schema('gestion')
          .from('reservas')
          .select('id_reserva')
          .eq('id_cliente', clienteId);

      final reservaIds = (reservas as List<dynamic>)
          .map((r) => r['id_reserva'] is int
              ? r['id_reserva'] as int
              : int.tryParse(r['id_reserva']?.toString() ?? '0') ?? 0)
          .where((id) => id > 0)
          .toList();

      if (reservaIds.isEmpty) return [];

      // 2. Filtrar calificaciones únicamente de sus reservas
      final response = await _supabase
          .schema('gestion')
          .from('calificaciones')
          .select('*')
          .inFilter('id_reserva', reservaIds)
          .order('fecha_calificacion', ascending: false);

      return (response as List<dynamic>)
          .map((row) => CalificacionEntity.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (_) {
      try {
        final reservas = await _supabase
            .from('reservas')
            .select('id_reserva')
            .eq('id_cliente', clienteId);

        final reservaIds = (reservas as List<dynamic>)
            .map((r) => r['id_reserva'] is int
                ? r['id_reserva'] as int
                : int.tryParse(r['id_reserva']?.toString() ?? '0') ?? 0)
            .where((id) => id > 0)
            .toList();

        if (reservaIds.isEmpty) return [];

        final response = await _supabase
            .from('calificaciones')
            .select('*')
            .inFilter('id_reserva', reservaIds)
            .order('fecha_calificacion', ascending: false);

        return (response as List<dynamic>)
            .map((row) => CalificacionEntity.fromJson(row as Map<String, dynamic>))
            .toList();
      } catch (_) {
        return [];
      }
    }
  }

  Future<bool> createCalificacion({
    required int idReserva,
    required int puntuacion,
    required String comentario,
  }) async {
    final payload = {
      'id_reserva': idReserva,
      'puntuacion': puntuacion,
      'comentario': comentario,
      'fecha_calificacion': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      await _supabase.schema('gestion').from('calificaciones').insert(payload);
      return true;
    } catch (_) {
      try {
        await _supabase.from('calificaciones').insert(payload);
        return true;
      } catch (e) {
        rethrow;
      }
    }
  }
}