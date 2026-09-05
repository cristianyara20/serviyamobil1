import 'package:flutter/material.dart';
import '../../../auth/domain/models/user_entity.dart';
import '../../../admin/presentation/screens/admin_main_screen.dart';
import '../../../prestador/presentation/screens/prestador_main_screen.dart';
import 'client_main_screen.dart';

class HomeDashboardScreen extends StatelessWidget {
  final UserEntity user;

  const HomeDashboardScreen({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    if (user.rol == UserRole.admin) {
      return AdminMainScreen(user: user);
    }
    if (user.rol == UserRole.prestador) {
      return PrestadorMainScreen(user: user);
    }
    return ClientMainScreen(user: user);
  }
}