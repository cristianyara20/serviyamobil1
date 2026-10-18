import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/pqrs_entity.dart';

class PqrsRemoteDataSource {
  final SupabaseClient _supabase;
  final Dio _dio;

  PqrsRemoteDataSource(this._supabase, this._dio);

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

  /// Radica una nueva PQR enviando los datos a la API REST de Go.
  /// Si ocurre un fallo temporal de red o de disponibilidad en la API,
  /// aplica contingencia resiliente hacia Supabase.
  Future<bool> createPqrs({
    required int idReserva,
    required TipoPqr tipoPqr,
    required String descripcion,
  }) async {
    final clienteId = await _resolveClienteId();
    if (clienteId == null) {
      throw 'Debes iniciar sesión para radicar una PQR.';
    }

    final payload = {
      'id_cliente': clienteId,
      'id_reserva': idReserva,
      'tipo_pqr': tipoPqr.displayName,
      'descripcion': descripcion,
    };

    // 1. Enviar petición HTTP POST a la API de Go: /operativo/pqrs
    try {
      final response = await _dio.post(
        '/operativo/pqrs',
        data: payload,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map) {
        final data = e.response!.data as Map;
        final errorMsg = data['error'] ?? data['detalle'] ?? e.message;
        if (kDebugMode) {
          print('⚠️ [PqrsRemoteDataSource] Error en API Go: $errorMsg');
        }
        throw errorMsg.toString();
      }
      if (kDebugMode) {
        print('⚠️ [PqrsRemoteDataSource] Error de conexión en API Go: $e. Intentando fallback Supabase.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [PqrsRemoteDataSource] Error inesperado en API Go: $e. Intentando fallback Supabase.');
      }
    }

    // 2. Fallback resiliente: Inserción directa en la base de datos Supabase
    try {
      final fallbackPayload = {
        ...payload,
        'estado_pqr': 'Abierto',
      };
      await _supabase.schema('soporte').from('pqrs').insert(fallbackPayload);
      return true;
    } catch (e) {
      rethrow;
    }
  }
}
