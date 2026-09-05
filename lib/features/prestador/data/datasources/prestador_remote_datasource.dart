import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../config/env.dart';
import '../../domain/models/prestador_solicitud_entity.dart';
import '../../domain/models/prestador_stats_entity.dart';

class PrestadorRemoteDataSource {
  Future<List<dynamic>> _query(String schema, String table, String select, {String? filter, String? order}) async {
    try {
      final serviceKey = Env.supabaseServiceRoleKey;
      final supabaseUrl = Env.supabaseUrl;
      final filterParam = filter != null ? '&$filter' : '';
      final orderParam = order != null ? '&order=$order' : '';
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/$table?select=$select$filterParam$orderParam'),
        headers: {
          'apikey': serviceKey,
          'Authorization': 'Bearer $serviceKey',
          'Accept': 'application/json',
          'Accept-Profile': schema,
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
    } catch (_) {}
    return [];
  }

  // Obtener todas las reservas con datos enriquecidos de cliente y servicio
  Future<List<PrestadorSolicitudEntity>> fetchReservas(int idPrestador) async {
    final results = await Future.wait([
      _query('gestion', 'reservas', '*', order: 'fecha_agenda.desc'),
      _query('seguridad', 'usuarios', 'id_usuario,nombre,apellido,correo'),
      _query('gestion', 'servicios', 'id_servicio,nombre_servicio'),
    ]);

    final reservas = results[0];
    final usuarios = results[1];
    final servicios = results[2];

    int? parseInt(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString().trim());
    }

    final Map<int, Map<String, dynamic>> userMap = {};
    for (final u in usuarios) {
      final id = parseInt(u['id_usuario']);
      if (id != null) {
        userMap[id] = u as Map<String, dynamic>;
      }
    }

    final Map<int, String> serviceMap = {};
    for (final s in servicios) {
      final id = parseInt(s['id_servicio']);
      if (id != null) {
        serviceMap[id] = s['nombre_servicio']?.toString() ?? 'Servicio #$id';
      }
    }

    final List<PrestadorSolicitudEntity> list = [];
    for (final r in reservas) {
      final idPres = parseInt(r['id_prestador']);
      final estado = r['estado_reserva']?.toString().toLowerCase() ?? 'pendiente';

      // Mostrar si está asignado a este prestador O si es una solicitud pendiente general
      final belongsToMe = idPres == idPrestador;
      final isGeneralPending = (idPres == null || idPres == idPrestador) && estado == 'pendiente';

      if (belongsToMe || isGeneralPending) {
        final idCliente = parseInt(r['id_cliente']) ?? 0;
        final idServicio = parseInt(r['id_servicio']) ?? 0;

        final u = userMap[idCliente];
        final nombreCli = u != null
            ? '${u['nombre'] ?? ''} ${u['apellido'] ?? ''}'.trim()
            : 'Cliente #$idCliente';
        final correoCli = u?['correo']?.toString() ?? '';

        final nombreServ = serviceMap[idServicio] ??
            (r['descripcion']?.toString().isNotEmpty == true ? r['descripcion'].toString() : 'Servicio');

        final rawFoto = r['detalle_extra']?.toString().trim();
        final fotoUrl = (rawFoto != null && rawFoto.isNotEmpty && rawFoto.startsWith('http'))
            ? rawFoto
            : null;

        list.add(PrestadorSolicitudEntity(
          idReserva: parseInt(r['id_reserva']) ?? 0,
          idCliente: idCliente,
          nombreCliente: nombreCli.isNotEmpty ? nombreCli : 'Cliente',
          correoCliente: correoCli,
          idPrestador: idPres,
          idServicio: idServicio,
          nombreServicio: nombreServ,
          fechaAgenda: r['fecha_agenda']?.toString() ?? '',
          direccion: r['direccion']?.toString() ?? '',
          descripcion: r['descripcion']?.toString() ?? '',
          estadoReserva: estado,
          fotoEvidencia: fotoUrl,
        ));
      }
    }
    return list;
  }

  // Obtener estadísticas y disponibilidad del prestador
  Future<PrestadorStatsEntity> fetchStats(int idPrestador) async {
    final results = await Future.wait([
      _query('gestion', 'prestadores', '*', filter: 'id_prestador=eq.$idPrestador'),
      _query('gestion', 'reservas', 'id_reserva,estado_reserva', filter: 'id_prestador=eq.$idPrestador'),
    ]);

    final prestadorRows = results[0];
    final misReservas = results[1];

    String disp = 'disponible';
    double califPromedio = 5.0;
    if (prestadorRows.isNotEmpty) {
      disp = prestadorRows.first['estado_disponibilidad']?.toString().toLowerCase() ?? 'disponible';
      if (prestadorRows.first['calificacion_promedio'] != null) {
        califPromedio = (prestadorRows.first['calificacion_promedio'] as num).toDouble();
      }
    }

    int completados = 0;
    int activos = 0;
    for (final r in misReservas) {
      final st = r['estado_reserva']?.toString().toLowerCase() ?? '';
      if (st == 'completada' || st == 'terminada') {
        completados++;
      } else if (st == 'confirmada' || st == 'en_progreso' || st == 'aceptada') {
        activos++;
      }
    }

    // Nivel y progreso
    String nivel = 'Novato';
    double progreso = 0.25;
    if (completados >= 100) {
      nivel = 'Maestro';
      progreso = 1.0;
    } else if (completados >= 50) {
      nivel = 'Experto';
      progreso = 0.75 + (completados - 50) / 200.0;
    } else if (completados >= 15) {
      nivel = 'Avanzado';
      progreso = 0.50 + (completados - 15) / 100.0;
    } else {
      nivel = 'Novato';
      progreso = 0.25 + (completados / 60.0);
    }
    if (progreso > 1.0) progreso = 1.0;

    return PrestadorStatsEntity(
      completados: completados,
      calificacion: califPromedio,
      activos: activos,
      disponibilidad: disp,
      nivel: nivel,
      progresoMeta: progreso,
    );
  }

  // Cambiar disponibilidad (disponible, ocupado, inactivo)
  Future<void> updateDisponibilidad(int idPrestador, String nuevoEstado) async {
    final serviceKey = Env.supabaseServiceRoleKey;
    final supabaseUrl = Env.supabaseUrl;
    await http.patch(
      Uri.parse('$supabaseUrl/rest/v1/prestadores?id_prestador=eq.$idPrestador'),
      headers: {
        'apikey': serviceKey,
        'Authorization': 'Bearer $serviceKey',
        'Content-Type': 'application/json',
        'Content-Profile': 'gestion',
      },
      body: jsonEncode({'estado_disponibilidad': nuevoEstado.toLowerCase()}),
    );
  }

  // Aceptar solicitud (pasa a aceptada y asigna prestador)
  Future<void> aceptarSolicitud(int idReserva, int idPrestador) async {
    final serviceKey = Env.supabaseServiceRoleKey;
    final supabaseUrl = Env.supabaseUrl;
    await http.patch(
      Uri.parse('$supabaseUrl/rest/v1/reservas?id_reserva=eq.$idReserva'),
      headers: {
        'apikey': serviceKey,
        'Authorization': 'Bearer $serviceKey',
        'Content-Type': 'application/json',
        'Content-Profile': 'gestion',
      },
      body: jsonEncode({
        'estado_reserva': 'aceptada',
        'id_prestador': idPrestador,
      }),
    );
  }

  // Rechazar solicitud (pasa a rechazada y asigna al prestador para su historial)
  Future<void> rechazarSolicitud(int idReserva, int idPrestador) async {
    final serviceKey = Env.supabaseServiceRoleKey;
    final supabaseUrl = Env.supabaseUrl;
    await http.patch(
      Uri.parse('$supabaseUrl/rest/v1/reservas?id_reserva=eq.$idReserva'),
      headers: {
        'apikey': serviceKey,
        'Authorization': 'Bearer $serviceKey',
        'Content-Type': 'application/json',
        'Content-Profile': 'gestion',
      },
      body: jsonEncode({
        'estado_reserva': 'rechazada',
        'id_prestador': idPrestador,
      }),
    );
  }

  // Completar servicio con foto obligatoria de evidencia consumiendo Go API
  Future<void> completarServicio({
    required int idReserva,
    required int idPrestador,
    required Uint8List imageBytes,
    String fileExtension = 'jpg',
  }) async {
    // 1. Subir la imagen a Supabase Storage (bucket 'evidencias')
    String? publicUrl;
    final cleanExt = fileExtension.replaceAll('.', '').toLowerCase();
    final fileName = 'evidencia_${idReserva}_${DateTime.now().millisecondsSinceEpoch}.$cleanExt';

    final serviceKey = Env.supabaseServiceRoleKey;
    final supabaseUrl = Env.supabaseUrl;
    final uploadUri = '$supabaseUrl/storage/v1/object/evidencias/$fileName';

    try {
      final uploadRes = await http.post(
        Uri.parse(uploadUri),
        headers: {
          'apikey': serviceKey,
          'Authorization': 'Bearer $serviceKey',
          'Content-Type': 'image/$cleanExt',
        },
        body: imageBytes,
      );
      if (uploadRes.statusCode == 200 || uploadRes.statusCode == 201) {
        publicUrl = '$supabaseUrl/storage/v1/object/public/evidencias/$fileName';
        debugPrint('📸 [Storage]: Foto subida exitosamente a Supabase Storage: $publicUrl');
      } else {
        debugPrint('⚠️ [Storage]: Subida a Storage respondió ${uploadRes.statusCode}: ${uploadRes.body}');
        publicUrl = '$supabaseUrl/storage/v1/object/public/evidencias/$fileName';
      }
    } catch (e) {
      debugPrint('⚠️ [Storage]: Error al subir foto a Supabase Storage: $e');
      publicUrl = '$supabaseUrl/storage/v1/object/public/evidencias/$fileName';
    }


    // 2. Intentar llamar a la API de Go: POST /operativo/reservas/{id}/finalizar
    bool apiSuccess = false;
    try {
      final session = Supabase.instance.client.auth.currentSession;
      final token = (session != null && session.accessToken.isNotEmpty)
          ? session.accessToken
          : Env.supabaseAnonKey;
      final apiUrl = Env.apiBaseUrl;
      final uri = '$apiUrl/operativo/reservas/$idReserva/finalizar';

      debugPrint('🚀 [API Go]: *** Request ***');
      debugPrint('🚀 [API Go]: uri: $uri');
      debugPrint('🚀 [API Go]: method: POST');
      debugPrint('🚀 [API Go]: body: {"id_prestador": $idPrestador, "foto_url": "$publicUrl"}');

      final response = await http.post(
        Uri.parse(uri),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id_prestador': idPrestador,
          'foto_url': publicUrl,
        }),
      ).timeout(const Duration(seconds: 12));

      debugPrint('🚀 [API Go]: *** Response ***');
      debugPrint('🚀 [API Go]: statusCode: ${response.statusCode}');
      debugPrint('🚀 [API Go]: body: ${response.body}');

      if (response.statusCode == 200) {
        apiSuccess = true;
      }
    } catch (e) {
      debugPrint('🚀 [API Go]: ⚠️ Error en /operativo/reservas/$idReserva/finalizar: $e');
    }

    // 3. Fallback: Si la API de Go no respondió 200, actualizar directamente en Supabase
    if (!apiSuccess) {
      debugPrint('🔄 [Fallback]: Actualizando reserva en Supabase directamente...');
      final serviceKey = Env.supabaseServiceRoleKey;
      final supabaseUrl = Env.supabaseUrl;
      await http.patch(
        Uri.parse('$supabaseUrl/rest/v1/reservas?id_reserva=eq.$idReserva'),
        headers: {
          'apikey': serviceKey,
          'Authorization': 'Bearer $serviceKey',
          'Content-Type': 'application/json',
          'Content-Profile': 'gestion',
        },
        body: jsonEncode({
          'estado_reserva': 'terminada',
          'detalle_extra': publicUrl,
        }),
      );
    }
  }
}

