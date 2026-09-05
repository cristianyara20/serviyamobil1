import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/prestador_operativo_entity.dart';
import '../../domain/models/reserva_historial_entity.dart';

class PrestadoresRemoteDataSource {
  final Dio _dio;
  final SupabaseClient _supabase = Supabase.instance.client;

  PrestadoresRemoteDataSource(this._dio);

  // 1. Obtener lista de prestadores con disponibilidad en tiempo real (Optimizado)
  Future<List<PrestadorOperativoEntity>> fetchPrestadores() async {
    // Intentar primero a través de la API REST de Go con timeout corto (4 segundos)
    try {
      final response = await _dio.get(
        '/operativo/prestadores',
        options: Options(receiveTimeout: const Duration(seconds: 4), sendTimeout: const Duration(seconds: 4)),
      );
      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        return list.map((item) => PrestadorOperativoEntity.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}

    // Fallback ultra-rápido en paralelo a Supabase
    try {
      final results = await Future.wait([
        _supabase
            .schema('gestion')
            .from('prestadores')
            .select('id_prestador, experiencia, calificacion_promedio, estado_disponibilidad'),
        _supabase
            .schema('seguridad')
            .from('usuarios')
            .select('id_usuario, nombre, apellido, correo'),
      ]);

      final prestadoresResp = results[0] as List<dynamic>;
      final usuariosResp = results[1] as List<dynamic>;

      final Map<int, Map<String, dynamic>> userMap = {};
      for (final u in usuariosResp) {
        final id = u['id_usuario'] as int?;
        if (id != null) {
          userMap[id] = u as Map<String, dynamic>;
        }
      }

      return prestadoresResp.map((p) {
        final id = p['id_prestador'] as int;
        final u = userMap[id];
        return PrestadorOperativoEntity(
          idPrestador: id,
          nombre: u?['nombre']?.toString() ?? 'Prestador',
          apellido: u?['apellido']?.toString() ?? '#$id',
          correo: u?['correo']?.toString() ?? '',
          experiencia: p['experiencia']?.toString() ?? 'Sin experiencia registrada',
          calificacionPromedio: p['calificacion_promedio'] != null
              ? (p['calificacion_promedio'] as num).toDouble()
              : 5.0,
          estadoDisponibilidad: p['estado_disponibilidad']?.toString() ?? 'disponible',
        );
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener prestadores: $e');
    }
  }

  // 2. Obtener historial de reservas atendidas (Optimizado en Paralelo)
  Future<List<ReservaHistorialEntity>> fetchHistorialServicios({int? idPrestador}) async {
    // Intentar primero a través de la API REST de Go con timeout corto (4 segundos)
    try {
      final response = await _dio.get(
        '/operativo/historial-servicios',
        options: Options(receiveTimeout: const Duration(seconds: 4), sendTimeout: const Duration(seconds: 4)),
      );
      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        final all = list.map((item) => ReservaHistorialEntity.fromJson(item as Map<String, dynamic>)).toList();
        if (idPrestador != null) {
          return all.where((r) => r.idPrestador == idPrestador).toList();
        }
        return all;
      }
    } catch (_) {}

    // Fallback ultra-rápido en paralelo a Supabase (1 solo viaje de red)
    try {
      var query = _supabase
          .schema('gestion')
          .from('reservas')
          .select('id_reserva, id_cliente, id_prestador, id_servicio, fecha_agenda, direccion, descripcion, estado_reserva');

      if (idPrestador != null) {
        query = query.eq('id_prestador', idPrestador);
      }

      final results = await Future.wait([
        query.order('fecha_agenda', ascending: false),
        _supabase
            .schema('seguridad')
            .from('usuarios')
            .select('id_usuario, nombre, apellido'),
        _supabase
            .schema('gestion')
            .from('servicios')
            .select('id_servicio, nombre_servicio'),
      ]);

      final rows = results[0] as List<dynamic>;
      final users = results[1] as List<dynamic>;
      final servicios = results[2] as List<dynamic>;

      // Diccionarios en memoria
      final Map<int, String> userNames = {};
      for (final u in users) {
        final id = u['id_usuario'] as int?;
        if (id != null) {
          userNames[id] = '${u['nombre'] ?? ''} ${u['apellido'] ?? ''}'.trim();
        }
      }

      final Map<int, String> serviceNames = {};
      for (final s in servicios) {
        final id = s['id_servicio'] as int?;
        if (id != null) {
          serviceNames[id] = s['nombre_servicio']?.toString() ?? 'Servicio #$id';
        }
      }

      return rows.map((r) {
        final idCliente = r['id_cliente'] as int?;
        final idServicio = r['id_servicio'] as int?;
        final idPres = r['id_prestador'] as int?;

        final nombreCliente = (idCliente != null && userNames.containsKey(idCliente) && userNames[idCliente]!.isNotEmpty)
            ? userNames[idCliente]!
            : 'Cliente #$idCliente';

        final nombrePrestador = (idPres != null && userNames.containsKey(idPres))
            ? userNames[idPres]
            : null;

        final nombreServicio = (idServicio != null && serviceNames.containsKey(idServicio))
            ? serviceNames[idServicio]!
            : 'Servicio #$idServicio';

        return ReservaHistorialEntity(
          idReserva: r['id_reserva'] as int,
          idCliente: idCliente ?? 0,
          nombreCliente: nombreCliente,
          idPrestador: idPres,
          nombrePrestador: nombrePrestador,
          idServicio: idServicio ?? 0,
          nombreServicio: nombreServicio,
          fechaAgenda: r['fecha_agenda']?.toString() ?? '',
          direccion: r['direccion']?.toString() ?? '',
          descripcion: r['descripcion']?.toString() ?? '',
          estadoReserva: r['estado_reserva']?.toString() ?? 'pendiente',
        );
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener historial: $e');
    }
  }
}
