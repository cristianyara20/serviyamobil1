import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get supabaseUrl {
    final envVal = dotenv.env['SUPABASE_URL'] ?? dotenv.env['NEXT_PUBLIC_SUPABASE_URL'];
    if (envVal != null && envVal.isNotEmpty) return envVal;
    const defineVal = String.fromEnvironment('SUPABASE_URL');
    if (defineVal.isNotEmpty) return defineVal;
    const defineNextVal = String.fromEnvironment('NEXT_PUBLIC_SUPABASE_URL');
    if (defineNextVal.isNotEmpty) return defineNextVal;
    return 'https://lvxhporsajorgckeisna.supabase.co';
  }

  static String get supabaseAnonKey {
    final envVal = dotenv.env['SUPABASE_ANON_KEY'] ?? dotenv.env['NEXT_PUBLIC_SUPABASE_ANON_KEY'];
    if (envVal != null && envVal.isNotEmpty) return envVal;
    const defineVal = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (defineVal.isNotEmpty) return defineVal;
    const defineNextVal = String.fromEnvironment('NEXT_PUBLIC_SUPABASE_ANON_KEY');
    if (defineNextVal.isNotEmpty) return defineNextVal;
    return '';
  }

  static String get supabaseServiceRoleKey {
    final envVal = dotenv.env['SUPABASE_SERVICE_ROLE_KEY'] ?? dotenv.env['NEXT_PUBLIC_SUPABASE_SERVICE_ROLE_KEY'];
    if (envVal != null && envVal.isNotEmpty) return envVal;
    const defineVal = String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY');
    if (defineVal.isNotEmpty) return defineVal;
    const defineNextVal = String.fromEnvironment('NEXT_PUBLIC_SUPABASE_SERVICE_ROLE_KEY');
    if (defineNextVal.isNotEmpty) return defineNextVal;
    return '';
  }

  static String get apiBaseUrl {
    final envUrl = dotenv.env['API_BASE_URL'] ??
        dotenv.env['NEXT_PUBLIC_REPORTES_API_URL'] ??
        const String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8080/api/v1';
    }
    return 'https://apiserviya.onrender.com/api/v1';
  }
}
