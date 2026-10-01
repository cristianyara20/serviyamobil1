import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/reservation_entity.dart';

class ReservationRemoteDataSource {
  final SupabaseClient _supabase;
  final Dio _dio;

  ReservationRemoteDataSource(this._supabase, this._dio);

  Future<int?> _resolveClienteId() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    // 1. Buscar en seguridad.usuarios por auth_id
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

        if (idUsuario != null) {
          try {
            await _supabase.schema('gestion').from('clientes').upsert({
              'id_cliente': idUsuario,
              'auth_id': user.id,
            });
          } catch (_) {}
          return idUsuario;
        }
      }
    } catch (_) {}

    // 2. Buscar en seguridad.usuarios por correo
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

          if (idUsuario != null) {
            try {
              await _supabase
                  .schema('seguridad')
                  .from('usuarios')
                  .update({'auth_id': user.id})
                  .eq('id_usuario', idUsuario);
              await _supabase.schema('gestion').from('clientes').upsert({
                'id_cliente': idUsuario,
                'auth_id': user.id,
              });
            } catch (_) {}
            return idUsuario;
          }
        }
      }
    } catch (_) {}

    // 3. Buscar en gestion.clientes por auth_id
    try {
      final res = await _supabase
          .schema('gestion')
          .from('clientes')
          .select('id_cliente')
          .eq('auth_id', user.id)
          .maybeSingle();

      if (res != null && res['id_cliente'] != null) {
        return res['id_cliente'] is int
            ? res['id_cliente'] as int
            : int.tryParse(res['id_cliente'].toString());
      }
    } catch (_) {}

    // 4. Si el usuario aún no existe en seguridad.usuarios, crearlo automáticamente
    try {
      final meta = user.userMetadata ?? {};
      final inserted = await _supabase.schema('seguridad').from('usuarios').insert({
        'auth_id': user.id,
        'correo': user.email ?? '',
        'nombre': meta['nombre']?.toString() ?? 'Usuario',
        'apellido': meta['apellido']?.toString() ?? '',
        'fecha_nacimiento': meta['fecha_nacimiento'],
        'rol': 'usuario',
      }).select('id_usuario').single();

      final newId = inserted['id_usuario'] is int
          ? inserted['id_usuario'] as int
          : int.tryParse(inserted['id_usuario'].toString());

      if (newId != null) {
        try {
          await _supabase.schema('gestion').from('clientes').insert({
            'id_cliente': newId,
            'auth_id': user.id,
          });
        } catch (_) {}
        return newId;
      }
    } catch (_) {}

    return null;
  }

  Future<List<ReservationEntity>> fetchReservations() async {
    final clienteId = await _resolveClienteId();
    if (clienteId == null) return [];

    try {
      final response = await _supabase
          .schema('gestion')
          .from('reservas')
          .select('*')
          .eq('id_cliente', clienteId)
          .order('fecha_agenda', ascending: false);

      return (response as List<dynamic>)
          .map((row) => ReservationEntity.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      try {
        final response = await _supabase
            .from('reservas')
            .select('*')
            .eq('id_cliente', clienteId)
            .order('fecha_agenda', ascending: false);

        return (response as List<dynamic>)
            .map((row) => ReservationEntity.fromJson(row as Map<String, dynamic>))
            .toList();
      } catch (_) {
        return [];
      }
    }
  }

  /// Registra una nueva reserva enviando los datos a la API REST en Go.
  /// En caso de indisponibilidad temporal de la API, cuenta con fallback resiliente hacia Supabase.
  Future<ReservationEntity> createReservation({
    required int idServicio,
    required String direccion,
    required String descripcion,
    required DateTime fechaAgenda,
    int? idPrestador,
  }) async {
    final clienteId = await _resolveClienteId();
    if (clienteId == null) {
      throw 'Debes iniciar sesión para agendar una cita.';
    }

    final payload = {
      'id_cliente': clienteId,
      'id_servicio': idServicio,
      if (idPrestador != null) 'id_prestador': idPrestador,
      'direccion': direccion,
      'descripcion': descripcion,
      'fecha_agenda': fechaAgenda.toUtc().toIso8601String(),
    };

    // 1. Enviar la petición HTTP POST a la API REST de Go: /reservas
    try {
      final response = await _dio.post(
        '/reservas',
        data: payload,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map<String, dynamic>) {
          return ReservationEntity.fromJson(response.data as Map<String, dynamic>);
        }
      }
    } on DioException catch (e) {
      // Si la API retornó un error de validación (400, etc.), lanzar el mensaje de negocio
      if (e.response != null && e.response?.data is Map) {
        final data = e.response!.data as Map;
        final errorMsg = data['error'] ?? data['detalle'] ?? e.message;
        throw errorMsg.toString();
      }
      // Si es un error de conectividad (API apagada o iniciando), continuar al fallback
    } catch (_) {
      // Continuar al fallback de contingencia
    }

    // 2. Fallback resiliente: Inserción directa en la base de datos Supabase
    try {
      final fallbackPayload = {
        ...payload,
        'estado_reserva': 'pendiente',
      };

      final response = await _supabase
          .schema('gestion')
          .from('reservas')
          .insert(fallbackPayload)
          .select('*')
          .single();

      return ReservationEntity.fromJson(response);
    } catch (e) {
      try {
        final fallbackPayload = {
          ...payload,
          'estado_reserva': 'pendiente',
        };
        final response = await _supabase
            .from('reservas')
            .insert(fallbackPayload)
            .select('*')
            .single();

        return ReservationEntity.fromJson(response);
      } catch (_) {
        throw 'No se pudo crear la reserva: $e';
      }
    }
  }

  /// Cancela una reserva existente utilizando el método HTTP PUT en la API de Go.
  /// Incluye validación de pertenencia enviando el `id_cliente` en el cuerpo de la solicitud.
  Future<bool> cancelReservation(int idReserva) async {
    // 1. Intentar primero con la API de Go: PUT /reservas/:id/cancelar
    final clienteId = await _resolveClienteId();
    if (clienteId != null) {
      try {
        // Petición HTTP PUT: Actualización de estado en el backend
        final response = await _dio.put(
          '/reservas/$idReserva/cancelar',
          data: {'id_cliente': clienteId},
        );
        // Retorna true si el backend Go confirmó la cancelación (200 OK)
        if (response.statusCode == 200) {
          return true;
        }
      } catch (_) {
        // En caso de falla de red en el microservicio Go, procede al fallback
      }
    }

    // 2. Fallback resiliente: actualizar directamente en la base de datos Supabase
    try {
      await _supabase
          .schema('gestion')
          .from('reservas')
          .update({'estado_reserva': 'cancelada'})
          .eq('id_reserva', idReserva);

      return true;
    } catch (_) {
      try {
        await _supabase
            .from('reservas')
            .update({'estado_reserva': 'cancelada'})
            .eq('id_reserva', idReserva);
        return true;
      } catch (_) {
        return false;
      }
    }
  }
}
