import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/models/user_entity.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../pqrs/presentation/screens/pqrs_screen.dart';
import '../../../reservations/presentation/screens/reservations_screen.dart';
import '../../../reviews/presentation/screens/reviews_screen.dart';
import 'services_home_tab.dart';
import 'welcome_screen.dart';

class ClientMainScreen extends ConsumerStatefulWidget {
  final UserEntity user;

  const ClientMainScreen({
    super.key,
    required this.user,
  });

  @override
  ConsumerState<ClientMainScreen> createState() => _ClientMainScreenState();
}

class _ClientMainScreenState extends ConsumerState<ClientMainScreen> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '¿Cerrar Sesión?',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          '¿Estás seguro de que deseas salir de tu cuenta en ServiYa?',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authControllerProvider.notifier).logout();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }

  void _showSosDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Text('🚨', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text(
              'Línea de Emergencia SOS',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: const Text(
          'En caso de urgencia o fuga grave, contáctanos inmediatamente a nuestra línea 24/7:\n\n📞 (+57) 300 912 3456\n🚑 Emergencias Nacionales: 123',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      ServicesHomeTab(
        user: widget.user,
        onNavigateToReservations: () => _onTabSelected(1),
      ),
      const ReservationsScreen(),
      const ReviewsScreen(),
      const PqrsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Text('🏠', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'SERVIYA',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: AppColors.primary,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  'CLIENTE',
                  style: TextStyle(
                    fontSize: 8.5,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Botón SOS
          InkWell(
            onTap: _showSosDialog,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('🚨', style: TextStyle(fontSize: 11)),
                  SizedBox(width: 4),
                  Text(
                    'SOS',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Botón Salir
          IconButton(
            tooltip: 'Cerrar Sesión',
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary, size: 20),
            onPressed: _showLogoutDialog,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border, width: 0.8)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabSelected,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              activeIcon: Icon(Icons.home_rounded, color: AppColors.primary),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_rounded),
              activeIcon: Icon(Icons.calendar_month_rounded, color: AppColors.primary),
              label: 'Reservas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.star_rounded),
              activeIcon: Icon(Icons.star_rounded, color: AppColors.primary),
              label: 'Calificaciones',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.mark_email_read_rounded),
              activeIcon: Icon(Icons.mark_email_read_rounded, color: AppColors.primary),
              label: 'PQRS',
            ),
          ],
        ),
      ),
    );
  }
}