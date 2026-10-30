import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Clase de configuración central que expone las variables de entorno.
/// Soporta tanto archivos `.env` locales como variables de entorno inyectadas
/// y fallbacks seguros para producción web.
class Env {
  /// Obtiene de forma segura el valor de una variable de entorno de dotenv.
  /// Si dotenv no se cargó (por ejemplo, en despliegues estáticos en la web),
  /// no lanza una excepción y permite que se usen los valores predeterminados (fallbacks).
  static String? _getEnv(String key) {
    try {
      if (dotenv.isInitialized) {
        return dotenv.env[key];
      }
    } catch (_) {
      // Si dotenv no está inicializado, capturar y continuar
    }
    return null;
  }

  /// URL del proyecto en la nube de Supabase (Base de datos PostgreSQL y Storage)
  static String get supabaseUrl {
    final envVal = _getEnv('SUPABASE_URL') ?? _getEnv('NEXT_PUBLIC_SUPABASE_URL');
    if (envVal != null && envVal.isNotEmpty) return envVal;
    const defineVal = String.fromEnvironment('SUPABASE_URL');
    if (defineVal.isNotEmpty) return defineVal;
    const defineNextVal = String.fromEnvironment('NEXT_PUBLIC_SUPABASE_URL');
    if (defineNextVal.isNotEmpty) return defineNextVal;
    return 'https://lvxhporsajorgckeisna.supabase.co';
  }

  /// Llave pública anónima de Supabase para consultas públicas y validación inicial
  static String get supabaseAnonKey {
    final envVal = _getEnv('SUPABASE_ANON_KEY') ?? _getEnv('NEXT_PUBLIC_SUPABASE_ANON_KEY');
    if (envVal != null && envVal.isNotEmpty) return envVal;
    const defineVal = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (defineVal.isNotEmpty) return defineVal;
    const defineNextVal = String.fromEnvironment('NEXT_PUBLIC_SUPABASE_ANON_KEY');
    if (defineNextVal.isNotEmpty) return defineNextVal;
    return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx2eGhwb3JzYWpvcmdja2Vpc25hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM0MjUyMzUsImV4cCI6MjA4OTAwMTIzNX0.51KF-wU4K-vJp6J00eu75OByMtrTQ0dFNMjvwdfLccs';
  }

  /// Llave de servicio (Service Role)
  static String get supabaseServiceRoleKey {
    final envVal = _getEnv('SUPABASE_SERVICE_ROLE_KEY') ?? _getEnv('NEXT_PUBLIC_SUPABASE_SERVICE_ROLE_KEY');
    if (envVal != null && envVal.isNotEmpty) return envVal;
    const defineVal = String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY');
    if (defineVal.isNotEmpty) return defineVal;
    const defineNextVal = String.fromEnvironment('NEXT_PUBLIC_SUPABASE_SERVICE_ROLE_KEY');
    if (defineNextVal.isNotEmpty) return defineNextVal;
    return '';
  }

  /// URL Base de la API Backend en Go:
  /// - Prioridad 1: Si está definida en `.env` mediante `API_BASE_URL` o `NEXT_PUBLIC_REPORTES_API_URL`.
  /// - Prioridad 2: En emuladores Android locales apunta al host `10.0.2.2:8080`.
  /// - Prioridad 3: Por defecto apunta al microservicio desplegado en Render en producción.
  static String get apiBaseUrl {
    final envUrl = _getEnv('API_BASE_URL') ??
        _getEnv('NEXT_PUBLIC_REPORTES_API_URL') ??
        const String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }
    // En emulador Android, 10.0.2.2 mapea a localhost del PC
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8080/api/v1';
    }
    // Microservicio en producción en Render
    return 'https://apiserviya.onrender.com/api/v1';
  }
}
