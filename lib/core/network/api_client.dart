import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/env.dart';
import 'supabase_client.dart';

final apiClientProvider = Provider<Dio>((ref) {
  final supabase = ref.watch(supabaseClientProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final session = supabase.auth.currentSession;
        if (session != null && session.accessToken.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer ${session.accessToken}';
        } else {
          options.headers['Authorization'] = 'Bearer ${Env.supabaseAnonKey}';
        }
        return handler.next(options);
      },
    ),
  );

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
