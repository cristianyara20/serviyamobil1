import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/env.dart';
import 'supabase_client.dart';

/// Provider global de Riverpod que expone una instancia única (Singleton) de [Dio]
/// configurada para comunicarse con la API Backend en Go.
/// Centraliza la URL base, tiempos de espera (timeouts) e interceptores de seguridad.
final apiClientProvider = Provider<Dio>((ref) {
  // Observa el cliente de Supabase para extraer el Token JWT de la sesión activa
  final supabase = ref.watch(supabaseClientProvider);

  // 1. Configuración de BaseOptions de Dio:
  // Define los parámetros globales por defecto para cada petición HTTP saliente.
  final dio = Dio(
    BaseOptions(
      // URL base del backend Go (ej: https://apiserviya.onrender.com/api/v1)
      baseUrl: Env.apiBaseUrl,
      
      // Tiempos máximos de espera para evitar bloqueos en la interfaz de usuario
      connectTimeout: const Duration(seconds: 35), // Permite margen de conexión
      receiveTimeout: const Duration(seconds: 35), // Permite margen de respuesta
      
      // Encabezados HTTP estándar enviados en cada solicitud
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // 2. Interceptor de Autenticación y Seguridad:
  // Se ejecuta automáticamente antes de enviar cualquier petición HTTP.
  // Inyecta el Token JWT en la cabecera Authorization (Bearer Token).
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final session = supabase.auth.currentSession;
        if (session != null && session.accessToken.isNotEmpty) {
          // Si el usuario tiene sesión activa, inyecta su token de acceso individual
          options.headers['Authorization'] = 'Bearer ${session.accessToken}';
        } else {
          // Fallback con la llave anónima pública si el usuario no se ha autenticado
          options.headers['Authorization'] = 'Bearer ${Env.supabaseAnonKey}';
        }
        // Continúa con la ejecución de la petición HTTP hacia el backend
        return handler.next(options);
      },
    ),
  );

  // 3. Interceptor de Logging / Auditoría:
  // Imprime en consola de depuración el tráfico de red de la API Go
  dio.interceptors.add(
    LogInterceptor(
      requestHeader: false,
      responseHeader: false,
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => debugPrint('🚀 [API Go]: $obj'),
    ),
  );

  return dio;
});
