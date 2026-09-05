import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/models/user_entity.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../home/presentation/screens/welcome_screen.dart';
import 'admin_analytics_tab.dart';
import 'admin_historial_tab.dart';
import 'admin_pqrs_tab.dart';
import 'admin_prestadores_tab.dart';
import 'admin_resenas_tab.dart';
import 'admin_users_tab.dart';

class AdminMainScreen extends ConsumerStatefulWidget {
  final UserEntity user;
  const AdminMainScreen({super.key, required this.user});

  @override
  ConsumerState<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends ConsumerState<AdminMainScreen> {
  int _tab = 0;

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('¿Deseas salir del panel de administrador?',
            style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Color(0xFF6B7280)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Icon(Icons.build_rounded, color: AppColors.primary, size: 24),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Panel Administrador', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            Text('Bienvenido, ${widget.user.nombre}', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF7F1D1D).withAlpha(60),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF7F1D1D)),
            ),
            child: const Text('ADMIN', style: TextStyle(color: Color(0xFFFCA5A5), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF6B7280)),
            onPressed: _showLogoutDialog,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),

      // Tab Bar
      body: Column(
        children: [
          Container(
            color: const Color(0xFF0D0D0D),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              child: Row(
                children: [
                  _TabBtn(label: '📊 Analíticas', index: 0, current: _tab, onTap: (i) => setState(() => _tab = i)),
                  _TabBtn(label: '👥 Gestión de Usuarios', index: 1, current: _tab, onTap: (i) => setState(() => _tab = i)),
                  _TabBtn(label: '🔧 Gestión de Prestadores', index: 2, current: _tab, onTap: (i) => setState(() => _tab = i)),
                  _TabBtn(label: '📜 Historial de Servicios', index: 3, current: _tab, onTap: (i) => setState(() => _tab = i)),
                  _TabBtn(label: '📋 Gestión de PQRs', index: 4, current: _tab, onTap: (i) => setState(() => _tab = i)),
                  _TabBtn(label: '📅 Gestión de Citas', index: 5, current: _tab, onTap: (i) => setState(() => _tab = i)),
                  _TabBtn(label: '⭐ Gestión de Reseñas', index: 6, current: _tab, onTap: (i) => setState(() => _tab = i)),
                ],
              ),
            ),
          ),
          Container(height: 1, color: const Color(0xFF1F1F1F)),
          Expanded(child: _buildTab()),
        ],
      ),
    );
  }

  Widget _buildTab() {
    switch (_tab) {
      case 0:
        return const AdminAnalyticsTab();
      case 1:
        return const AdminUsersTab();
      case 2:
        return const AdminPrestadoresTab();
      case 3:
        return const AdminHistorialTab();
      case 4:
        return const AdminPqrsTab();
      case 6:
        return const AdminResenasTab();
      default:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.construction_rounded, color: Color(0xFF374151), size: 60),
              const SizedBox(height: 16),
              const Text('Módulo en desarrollo', style: TextStyle(color: Color(0xFF6B7280), fontSize: 16)),
              const SizedBox(height: 8),
              const Text('Próximamente disponible', style: TextStyle(color: Color(0xFF4B5563), fontSize: 13)),
            ],
          ),
        );
    }
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final int index;
  final int current;
  final void Function(int) onTap;
  const _TabBtn({required this.label, required this.index, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.primary : const Color(0xFF6B7280),
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
