import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/admin_analytics_entity.dart';

class AdminAnalyticsRemoteDataSource {
  final Dio _dio;
  final SupabaseClient _supabase = Supabase.instance.client;

  AdminAnalyticsRemoteDataSource(this._dio);

  Future<AdminAnalyticsFullData> fetchAnalytics({required int mes, required int anio}) async {
    // 1. Intentar SIEMPRE primero consumir la API de Go (con timeout de 6s)
    try {
      final query = '?mes=$mes&anio=$anio';
      final results = await Future.wait([
        _dio.get(
          '/reportes/admin$query',
          options: Options(receiveTimeout: const Duration(seconds: 6), sendTimeout: const Duration(seconds: 6)),
        ),
        _dio.get(
          '/reportes/servicios-populares$query',
          options: Options(receiveTimeout: const Duration(seconds: 6), sendTimeout: const Duration(seconds: 6)),
        ),
        _dio.get(
          '/reportes/actividad-usuarios$query',
          options: Options(receiveTimeout: const Duration(seconds: 6), sendTimeout: const Duration(seconds: 6)),
        ),
      ]);

      final resAdmin = results[0];
      final resServicios = results[1];
      final resActividad = results[2];

      if (resAdmin.statusCode == 200 && resServicios.statusCode == 200 && resActividad.statusCode == 200) {
        final consolidado = AdminReporteConsolidadoEntity.fromJson(resAdmin.data as Map<String, dynamic>);
        
        final serviciosList = (resServicios.data is List)
            ? (resServicios.data as List)
                .map((x) => ServicioPopularEntity.fromJson(x as Map<String, dynamic>))
                .toList()
            : <ServicioPopularEntity>[];

        final actividad = ActividadUsuariosEntity.fromJson(resActividad.data as Map<String, dynamic>);

        return AdminAnalyticsFullData(
          consolidado: consolidado,
          servicios: serviciosList,
          actividad: actividad,
        );
      }
    } catch (_) {
      // Si la API de Go está arrancando o falla la red, procedemos al cálculo local resiliente
    }

    // 2. Fallback de contingencia a Supabase (Garantiza disponibilidad 100% en caso de falla de red del microservicio)
    return await _calculateSupabaseFallback(mes: mes, anio: anio);
  }

  Future<AdminAnalyticsFullData> _calculateSupabaseFallback({required int mes, required int anio}) async {
    try {
      final results = await Future.wait([
        _supabase.schema('gestion').from('reservas').select('*'),
        _supabase.schema('soporte').from('pqrs').select('*'),
        _supabase.schema('gestion').from('prestadores').select('id_prestador, calificacion_promedio'),
        _supabase.schema('seguridad').from('usuarios').select('id_usuario, nombre, apellido, correo'),
        _supabase.schema('gestion').from('servicios').select('id_servicio, nombre_servicio, categoria'),
        _supabase.schema('gestion').from('clientes').select('id_cliente, fecha_registro'),
      ]);

      final allReservas = results[0] as List<dynamic>;
      final allPqrs = results[1] as List<dynamic>;
      final prestadores = results[2] as List<dynamic>;
      final usuarios = results[3] as List<dynamic>;
      final serviciosDb = results[4] as List<dynamic>;
      final clientesDb = results[5] as List<dynamic>;

      // Filtrar reservas por mes y año
      final mesReservas = allReservas.where((r) {
        final fechaStr = r['fecha_agenda']?.toString();
        if (fechaStr == null) return false;
        final d = DateTime.tryParse(fechaStr);
        if (d == null) return false;
        return d.month == mes && d.year == anio;
      }).toList();

      int pendientes = 0;
      int aceptadas = 0;
      int completadas = 0;
      int canceladas = 0;

      for (final r in mesReservas) {
        final estado = (r['estado_reserva']?.toString() ?? '').toLowerCase();
        if (estado == 'pendiente') {
          pendientes++;
        } else if (estado == 'aceptada' || estado == 'confirmada') {
          aceptadas++;
        } else if (estado == 'terminada' || estado == 'completada') {
          completadas++;
        } else if (estado == 'rechazada' || estado == 'cancelada') {
          canceladas++;
        }
      }

      final pqrsAbiertas = allPqrs.where((p) {
        final est = (p['estado_pqr']?.toString() ?? p['estado']?.toString() ?? '').toLowerCase();
        return !est.contains('resuelto') && !est.contains('cerrado');
      }).length;

      // Top Prestadores
      final Map<int, Map<String, dynamic>> userMap = {};
      for (final u in usuarios) {
        final id = u['id_usuario'] as int?;
        if (id != null) userMap[id] = u as Map<String, dynamic>;
      }

      final List<PrestadorTopAnalyticsEntity> topList = [];
      for (final p in prestadores) {
        final idPres = p['id_prestador'] as int?;
        if (idPres == null) continue;
        final u = userMap[idPres];
        
        final svcs = allReservas.where((r) {
          final estado = (r['estado_reserva']?.toString() ?? '').toLowerCase();
          return r['id_prestador'] == idPres && (estado == 'terminada' || estado == 'completada');
        }).length;

        topList.add(PrestadorTopAnalyticsEntity(
          idPrestador: idPres,
          nombrePrestador: ' '.trim().isNotEmpty
              ? ' '.trim()
              : 'Prestador #',
          correoPrestador: u?['correo']?.toString() ?? '',
          calificacion: (p['calificacion_promedio'] as num?)?.toDouble() ?? 5.0,
          totalServicios: svcs,
        ));
      }

      topList.sort((a, b) {
        final cmp = b.totalServicios.compareTo(a.totalServicios);
        if (cmp != 0) return cmp;
        return b.calificacion.compareTo(a.calificacion);
      });

      // Servicios Populares
      final Map<int, int> svcCount = {};
      for (final r in mesReservas) {
        final idS = r['id_servicio'] as int?;
        if (idS != null) {
          svcCount[idS] = (svcCount[idS] ?? 0) + 1;
        }
      }

      final List<ServicioPopularEntity> svcPopulares = [];
      for (final s in serviciosDb) {
        final idS = s['id_servicio'] as int?;
        if (idS == null) continue;
        final count = svcCount[idS] ?? 0;
        if (count > 0) {
          svcPopulares.add(ServicioPopularEntity(
            idServicio: idS,
            nombreServicio: s['nombre_servicio']?.toString() ?? 'Servicio #',
            categoria: s['categoria']?.toString() ?? 'Hogar',
            vecesSolicitado: count,
          ));
        }
      }
      svcPopulares.sort((a, b) => b.vecesSolicitado.compareTo(a.vecesSolicitado));

      // Actividad Usuarios
      int nuevos = 0;
      for (final c in clientesDb) {
        final regStr = c['fecha_registro']?.toString();
        if (regStr != null) {
          final d = DateTime.tryParse(regStr);
          if (d != null && d.month == mes && d.year == anio) nuevos++;
        }
      }

      final Set<int> activos = {};
      for (final r in mesReservas) {
        final idC = r['id_cliente'] as int?;
        if (idC != null) activos.add(idC);
      }

      return AdminAnalyticsFullData(
        consolidado: AdminReporteConsolidadoEntity(
          mes: mes,
          anio: anio,
          totalReservas: mesReservas.length,
          totalPendientes: pendientes,
          totalAceptadas: aceptadas,
          totalCompletadas: completadas,
          totalCanceladas: canceladas,
          pqrsAbiertas: pqrsAbiertas,
          topPrestadores: topList.take(3).toList(),
        ),
        servicios: svcPopulares,
        actividad: ActividadUsuariosEntity(
          mes: mes,
          anio: anio,
          usuariosNuevos: nuevos,
          usuariosActivos: activos.length,
        ),
      );
    } catch (e) {
      throw Exception('Error al cargar analíticas: $e');
    }
  }

  Future<List<int>> downloadReportePDF({required int mes, required int anio}) async {
    final response = await _dio.get<List<int>>(
      '/reportes/admin/pdf?mes=$mes&anio=$anio',
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      return response.data!;
    }
    throw Exception('No se pudo descargar el archivo PDF desde el servidor');
  }
}
