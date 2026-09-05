import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/env.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/home/presentation/screens/home_dashboard_screen.dart';
import 'features/home/presentation/screens/welcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Cargar variables de entorno (.env)
  await dotenv.load(fileName: ".env");

  // 2. Inicializar Supabase Client
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );

  runApp(
    const ProviderScope(
      child: ServiYaApp(),
    ),
  );
}

class ServiYaApp extends ConsumerWidget {
  const ServiYaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(currentUserProvider);

    return MaterialApp(
      title: 'ServiYa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: authState.when(
        data: (user) {
          if (user != null) {
            return HomeDashboardScreen(user: user);
          }
          return const WelcomeScreen();
        },
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              color: Color(0xFFF97316),
            ),
          ),
        ),
        error: (error, stack) => const WelcomeScreen(),
      ),
    );
  }
}