import '../../domain/models/admin_resena_entity.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../config/env.dart';
import '../../domain/models/admin_user_entity.dart';

class AdminRemoteDataSource {
  // Consulta genérica de administración usando service_role key (bypasea RLS)
  Future<List<dynamic>> _queryAdmin(String schema, String table, String select, {String? order}) async {
    try {
      final serviceKey = Env.supabaseServiceRoleKey;
      final supabaseUrl = Env.supabaseUrl;
      final orderParam = order != null ? '&order=$order' : '';
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/$table?select=$select$orderParam'),
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

  // Obtener todos los usuarios con conteos optimizados en paralelo (Admin Service Role)
  Future<List<AdminUserEntity>> fetchAllUsers() async {
    // 1. Ejecutar las 4 consultas en paralelo con service_role key (1 solo viaje de red)
    final results = await Future.wait([
      _queryAdmin('seguridad', 'usuarios', 'id_usuario,auth_id,nombre,apellido,correo,rol,fecha_nacimiento', order: 'id_usuario.desc'),
      _queryAdmin('gestion', 'reservas', 'id_reserva,id_cliente'),
      _queryAdmin('gestion', 'calificaciones', 'id_calificacion,id_reserva'),
      _queryAdmin('soporte', 'pqrs', 'id_pqr,id_cliente,id_reserva'),
    ]);

    final userRows = results[0];
    final reservaRows = results[1];
    final califRows = results[2];
    final pqrRows = results[3];

    int? parseInt(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString().trim());
    }

    // 2. Pre-calcular conteos en memoria (O(N) ultra rápido y seguro)
    final Map<int, int> citasCount = {};
    final Map<int, int> reservaToCliente = {};
    for (final r in reservaRows) {
      final idCliente = parseInt(r['id_cliente']);
      final idReserva = parseInt(r['id_reserva']);
      if (idCliente != null) {
        citasCount[idCliente] = (citasCount[idCliente] ?? 0) + 1;
        if (idReserva != null) {
          reservaToCliente[idReserva] = idCliente;
        }
      }
    }

    final Map<int, int> resenasCount = {};
    for (final c in califRows) {
      final idReserva = parseInt(c['id_reserva']);
      if (idReserva != null && reservaToCliente.containsKey(idReserva)) {
        final idCliente = reservaToCliente[idReserva]!;
        resenasCount[idCliente] = (resenasCount[idCliente] ?? 0) + 1;
      }
    }

    final Map<int, int> pqrsCount = {};
    for (final p in pqrRows) {
      int? idCliente = parseInt(p['id_cliente']);
      final idReserva = parseInt(p['id_reserva']);

      // Si id_cliente viene nulo pero tiene id_reserva, asociarlo al cliente de la reserva
      if (idCliente == null && idReserva != null && reservaToCliente.containsKey(idReserva)) {
        idCliente = reservaToCliente[idReserva];
      }

      if (idCliente != null) {
        pqrsCount[idCliente] = (pqrsCount[idCliente] ?? 0) + 1;
      }
    }

    // 3. Mapear a entidades
    return userRows.map((row) {
      final idUsuario = parseInt(row['id_usuario']) ?? 0;
      return AdminUserEntity(
        idUsuario: idUsuario,
        authId: row['auth_id']?.toString() ?? '',
        nombre: row['nombre']?.toString() ?? '',
        apellido: row['apellido']?.toString() ?? '',
        correo: row['correo']?.toString() ?? '',
        rol: row['rol']?.toString() ?? 'usuario',
        fechaNacimiento: row['fecha_nacimiento']?.toString(),
        fechaRegistro: null,
        numCitas: citasCount[idUsuario] ?? 0,
        numResenas: resenasCount[idUsuario] ?? 0,
        numPqrs: pqrsCount[idUsuario] ?? 0,
      );
    }).toList();
  }

  // Crear usuario via Supabase Admin API con service_role key
  Future<void> createUser({
    required String nombre,
    required String apellido,
    required String correo,
    required String password,
    required String rol,
    String? fechaNacimiento,
  }) async {
    final serviceKey = Env.supabaseServiceRoleKey;
    final supabaseUrl = Env.supabaseUrl;

    // 1. Crear en Supabase Auth Admin
    final authResp = await http.post(
      Uri.parse('$supabaseUrl/auth/v1/admin/users'),
      headers: {
        'apikey': serviceKey,
        'Authorization': 'Bearer $serviceKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': correo,
        'password': password,
        'email_confirm': true,
        'user_metadata': {
          'nombre': nombre,
          'apellido': apellido,
          'rol': rol,
        },
      }),
    );

    if (authResp.statusCode != 200 && authResp.statusCode != 201) {
      final body = jsonDecode(authResp.body);
      throw Exception(body['msg'] ?? body['message'] ?? 'Error al crear usuario en Auth');
    }

    final authData = jsonDecode(authResp.body);
    final authId = authData['id'] as String;

    // 2. Verificar si el trigger de Supabase ya creó el registro en seguridad.usuarios
    final existingCheck = await _queryAdmin('seguridad', 'usuarios', 'id_usuario,auth_id,correo');
    final existingUser = existingCheck.where((u) => u['auth_id'] == authId || u['correo'] == correo).toList();

    int idUsuario;
    if (existingUser.isNotEmpty) {
      idUsuario = existingUser.first['id_usuario'] as int;
      // Actualizar con datos completos
      await http.patch(
        Uri.parse('$supabaseUrl/rest/v1/usuarios?id_usuario=eq.$idUsuario'),
        headers: {
          'apikey': serviceKey,
          'Authorization': 'Bearer $serviceKey',
          'Content-Type': 'application/json',
          'Content-Profile': 'seguridad',
        },
        body: jsonEncode({
          'nombre': nombre,
          'apellido': apellido,
          'rol': rol,
          if (fechaNacimiento != null && fechaNacimiento.isNotEmpty) 'fecha_nacimiento': fechaNacimiento,
        }),
      );
    } else {
      // Insertar explícitamente en seguridad.usuarios
      final insertResp = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/usuarios'),
        headers: {
          'apikey': serviceKey,
          'Authorization': 'Bearer $serviceKey',
          'Content-Type': 'application/json',
          'Content-Profile': 'seguridad',
          'Prefer': 'return=representation',
        },
        body: jsonEncode({
          'auth_id': authId,
          'nombre': nombre,
          'apellido': apellido,
          'correo': correo,
          'rol': rol,
          if (fechaNacimiento != null && fechaNacimiento.isNotEmpty) 'fecha_nacimiento': fechaNacimiento,
        }),
      );
      if (insertResp.statusCode == 201 || insertResp.statusCode == 200) {
        final inserted = jsonDecode(insertResp.body) as List;
        idUsuario = inserted.first['id_usuario'] as int;
      } else {
        idUsuario = 0;
      }
    }

    // 3. Si el rol es prestador, registrar en gestion.prestadores
    if (rol == 'prestador' && idUsuario > 0) {
      try {
        await http.post(
          Uri.parse('$supabaseUrl/rest/v1/prestadores'),
          headers: {
            'apikey': serviceKey,
            'Authorization': 'Bearer $serviceKey',
            'Content-Type': 'application/json',
            'Content-Profile': 'gestion',
            'Prefer': 'resolution=merge-duplicates',
          },
          body: jsonEncode({
            'id_prestador': idUsuario,
            'experiencia': 'Nuevo prestador registrado',
            'calificacion_promedio': 5.0,
            'estado_disponibilidad': 'disponible',
          }),
        );
      } catch (_) {}
    } else if (rol == 'usuario' && idUsuario > 0) {
      try {
        await http.post(
          Uri.parse('$supabaseUrl/rest/v1/clientes'),
          headers: {
            'apikey': serviceKey,
            'Authorization': 'Bearer $serviceKey',
            'Content-Type': 'application/json',
            'Content-Profile': 'gestion',
            'Prefer': 'resolution=merge-duplicates',
          },
          body: jsonEncode({
            'id_cliente': idUsuario,
            'auth_id': authId,
          }),
        );
      } catch (_) {}
    }
  }

  // Eliminar usuario
  Future<void> deleteUser(int idUsuario, String authId) async {
    final serviceKey = Env.supabaseServiceRoleKey;
    final supabaseUrl = Env.supabaseUrl;

    // 1. Eliminar de tablas relacionadas
    try {
      await http.delete(
        Uri.parse('$supabaseUrl/rest/v1/prestadores?id_prestador=eq.$idUsuario'),
        headers: {'apikey': serviceKey, 'Authorization': 'Bearer $serviceKey', 'Content-Profile': 'gestion'},
      );
    } catch (_) {}

    try {
      await http.delete(
        Uri.parse('$supabaseUrl/rest/v1/clientes?id_cliente=eq.$idUsuario'),
        headers: {'apikey': serviceKey, 'Authorization': 'Bearer $serviceKey', 'Content-Profile': 'gestion'},
      );
    } catch (_) {}

    // 2. Eliminar de seguridad.usuarios
    try {
      await http.delete(
        Uri.parse('$supabaseUrl/rest/v1/usuarios?id_usuario=eq.$idUsuario'),
        headers: {'apikey': serviceKey, 'Authorization': 'Bearer $serviceKey', 'Content-Profile': 'seguridad'},
      );
    } catch (_) {}

    // 3. Eliminar de Supabase Auth
    if (authId.isNotEmpty) {
      try {
        await http.delete(
          Uri.parse('$supabaseUrl/auth/v1/admin/users/$authId'),
          headers: {
            'apikey': serviceKey,
            'Authorization': 'Bearer $serviceKey',
          },
        );
      } catch (_) {}
    }
  }

  // Actualizar usuario
  Future<void> updateUser({
    required int idUsuario,
    required String authId,
    required String nombre,
    required String apellido,
    required String rol,
    String? correo,
    String? password,
    String? fechaNacimiento,
  }) async {
    final serviceKey = Env.supabaseServiceRoleKey;
    final supabaseUrl = Env.supabaseUrl;

    // 1. Actualizar en seguridad.usuarios con service_role
    final Map<String, dynamic> userUpdate = {
      'nombre': nombre,
      'apellido': apellido,
      'rol': rol,
      if (correo != null && correo.isNotEmpty) 'correo': correo,
      if (fechaNacimiento != null && fechaNacimiento.isNotEmpty)
        'fecha_nacimiento': fechaNacimiento,
    };

    await http.patch(
      Uri.parse('$supabaseUrl/rest/v1/usuarios?id_usuario=eq.$idUsuario'),
      headers: {
        'apikey': serviceKey,
        'Authorization': 'Bearer $serviceKey',
        'Content-Type': 'application/json',
        'Content-Profile': 'seguridad',
      },
      body: jsonEncode(userUpdate),
    );

    // 2. Si se cambió el correo o la contraseña, actualizarlos en Supabase Auth
    if (authId.isNotEmpty) {
      final Map<String, dynamic> authUpdate = {};
      if (correo != null && correo.isNotEmpty) authUpdate['email'] = correo;
      if (password != null && password.isNotEmpty) authUpdate['password'] = password;

      if (authUpdate.isNotEmpty) {
        try {
          await http.put(
            Uri.parse('$supabaseUrl/auth/v1/admin/users/$authId'),
            headers: {
              'apikey': serviceKey,
              'Authorization': 'Bearer $serviceKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(authUpdate),
          );
        } catch (_) {}
      }
    }
  }

  // Obtener todas las calificaciones con detalles — consumiendo API de Go
  Future<List<AdminResenaEntity>> fetchResenas() async {
    // 1. Intentar primero con la API de Go: GET /reportes/calificaciones
    try {
      final session = Supabase.instance.client.auth.currentSession;
      final token = (session != null && session.accessToken.isNotEmpty)
          ? session.accessToken
          : Env.supabaseAnonKey;
      final apiUrl = Env.apiBaseUrl;
      final uri = '$apiUrl/reportes/calificaciones';

      debugPrint('🚀 [API Go]: *** Request ***');
      debugPrint('🚀 [API Go]: uri: $uri');
      debugPrint('🚀 [API Go]: method: GET');

      final response = await http.get(
        Uri.parse(uri),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('🚀 [API Go]: *** Response ***');
      debugPrint('🚀 [API Go]: statusCode: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> rows = jsonDecode(response.body) as List<dynamic>;
        debugPrint('🚀 [API Go]: Reseñas obtenidas desde Go API: ${rows.length} registros');
        return rows
            .map((c) => AdminResenaEntity.fromJson(c as Map<String, dynamic>))
            .toList();
      } else {
        debugPrint('🚀 [API Go]: Error HTTP ${response.statusCode} — activando fallback Supabase');
      }
    } catch (e) {
      debugPrint('🚀 [API Go]: ⚠️ Timeout/Error en /reportes/calificaciones — fallback a Supabase: $e');
    }

    // 2. Fallback: consultar Supabase directamente si la API de Go no responde
    final results = await Future.wait([
      _queryAdmin('gestion', 'calificaciones', 'id_calificacion,id_reserva,puntuacion,comentario,fecha_calificacion', order: 'fecha_calificacion.desc'),
      _queryAdmin('gestion', 'reservas', 'id_reserva,id_cliente,id_prestador,id_servicio'),
      _queryAdmin('seguridad', 'usuarios', 'id_usuario,nombre,apellido'),
      _queryAdmin('gestion', 'servicios', 'id_servicio,nombre_servicio'),
    ]);

    final califRows = results[0];
    final reservaRows = results[1];
    final userRows = results[2];
    final servicioRows = results[3];

    int? parseInt(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString().trim());
    }

    final Map<int, String> userNames = {};
    for (final u in userRows) {
      final id = parseInt(u['id_usuario']);
      if (id != null) {
        userNames[id] = '${u['nombre'] ?? ''} ${u['apellido'] ?? ''}'.trim();
      }
    }

    final Map<int, String> serviceNames = {};
    for (final s in servicioRows) {
      final id = parseInt(s['id_servicio']);
      if (id != null) {
        serviceNames[id] = s['nombre_servicio']?.toString() ?? 'Servicio #$id';
      }
    }

    final Map<int, Map<String, dynamic>> reservaMap = {};
    for (final r in reservaRows) {
      final id = parseInt(r['id_reserva']);
      if (id != null) {
        reservaMap[id] = r as Map<String, dynamic>;
      }
    }

    return califRows.map((c) {
      final idCalificacion = parseInt(c['id_calificacion']) ?? 0;
      final idReserva = parseInt(c['id_reserva']) ?? 0;
      final r = reservaMap[idReserva];

      final idCliente = r != null ? parseInt(r['id_cliente']) : null;
      final idPrestador = r != null ? parseInt(r['id_prestador']) : null;
      final idServicio = r != null ? parseInt(r['id_servicio']) : null;

      final nombreCliente = (idCliente != null && userNames.containsKey(idCliente) && userNames[idCliente]!.isNotEmpty)
          ? userNames[idCliente]!
          : 'Cliente';

      final nombrePrestador = (idPrestador != null && userNames.containsKey(idPrestador) && userNames[idPrestador]!.isNotEmpty)
          ? userNames[idPrestador]!
          : 'Prestador';

      final nombreServicio = (idServicio != null && serviceNames.containsKey(idServicio))
          ? serviceNames[idServicio]!
          : 'Servicio';

      final double puntuacion = (c['puntuacion'] is num)
          ? (c['puntuacion'] as num).toDouble()
          : (double.tryParse(c['puntuacion']?.toString() ?? '5.0') ?? 5.0);

      return AdminResenaEntity(
        idCalificacion: idCalificacion,
        idReserva: idReserva,
        puntuacion: puntuacion,
        comentario: c['comentario']?.toString() ?? '',
        fechaCalificacion: c['fecha_calificacion']?.toString() ?? '',
        nombreCliente: nombreCliente,
        nombrePrestador: nombrePrestador,
        nombreServicio: nombreServicio,
      );
    }).toList();
  }

  // Eliminar calificación
  Future<void> deleteResena(int idCalificacion) async {
    final serviceKey = Env.supabaseServiceRoleKey;
    final supabaseUrl = Env.supabaseUrl;
    await http.delete(
      Uri.parse('$supabaseUrl/rest/v1/calificaciones?id_calificacion=eq.$idCalificacion'),
      headers: {
        'apikey': serviceKey,
        'Authorization': 'Bearer $serviceKey',
        'Content-Profile': 'gestion',
      },
    );
  }
}
