import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/admin_pqr_entity.dart';

class AdminPqrsRemoteDataSource {
  final Dio _dio;
  final SupabaseClient _supabase;

  AdminPqrsRemoteDataSource(this._dio, this._supabase);

  /// 1. Consulta todas las PQRs desde la API de Go (/operativo/pqrs)
  Future<List<AdminPqrEntity>> fetchPqrs() async {
    try {
      final response = await _dio.get('/operativo/pqrs');
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data is List
            ? response.data
            : (response.data['data'] is List ? response.data['data'] : []);
        return data.map((json) => AdminPqrEntity.fromJson(json as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [AdminPqrsRemoteDataSource] Error en API Go (/operativo/pqrs): $e. Usando fallback Supabase.');
      }
    }

    // Fallback: Consulta directa a PostgreSQL via Supabase
    try {
      final pqrsRes = await _supabase
          .schema('soporte')
          .from('pqrs')
          .select('id_pqr, id_cliente, id_reserva, tipo_pqr, descripcion, estado_pqr, fecha_pqr, respuesta_admin, fecha_respuesta')
          .order('id_pqr', ascending: false);

      final usersRes = await _supabase
          .schema('seguridad')
          .from('usuarios')
          .select('id_usuario, nombre, apellido');

      final userMap = <int, String>{};
      for (final u in usersRes) {
        final id = u['id_usuario'] as int?;
        if (id != null) {
          final nombre = u['nombre']?.toString() ?? '';
          final apellido = u['apellido']?.toString() ?? '';
          userMap[id] = '$nombre $apellido'.trim();
        }
      }

      return (pqrsRes as List<dynamic>).map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        final idCliente = map['id_cliente'] as int? ?? 0;
        map['nombre_cliente'] = userMap[idCliente] ?? 'Cliente #$idCliente';
        return AdminPqrEntity.fromJson(map);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AdminPqrsRemoteDataSource] Error en fallback Supabase: $e');
      }
      rethrow;
    }
  }

  /// 2. Envía la respuesta del Administrador a la API de Go (/operativo/pqrs/responder)
  Future<bool> responderPqr({required int idPqr, required String respuestaAdmin}) async {
    try {
      final response = await _dio.post(
        '/operativo/pqrs/responder',
        data: {
          'id_pqr': idPqr,
          'respuesta_admin': respuestaAdmin,
        },
      );
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [AdminPqrsRemoteDataSource] Error respondiendo en API Go: $e. Aplicando en Supabase.');
      }
    }

    // Fallback directo en Supabase
    try {
      await _supabase.schema('soporte').from('pqrs').update({
        'respuesta_admin': respuestaAdmin,
        'estado_pqr': 'Cerrado',
        'fecha_respuesta': DateTime.now().toIso8601String(),
      }).eq('id_pqr', idPqr);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AdminPqrsRemoteDataSource] Error actualizando PQR en Supabase: $e');
      }
      return false;
    }
  }
}
