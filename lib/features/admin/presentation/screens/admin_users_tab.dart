import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/models/admin_user_entity.dart';
import '../controllers/admin_users_controller.dart';

class AdminUsersTab extends ConsumerStatefulWidget {
  const AdminUsersTab({super.key});

  @override
  ConsumerState<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends ConsumerState<AdminUsersTab> {
  String _search = '';
  String _roleFilter = 'todos'; // todos, usuario, prestador, admin

  @override
  Widget build(BuildContext context) {
    final usersState = ref.watch(adminUsersProvider);

    return usersState.when(
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 14),
            Text('Cargando usuarios...', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
          ],
        ),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text('Error: $e', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 13)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () => ref.read(adminUsersProvider.notifier).load(),
                icon: const Icon(Icons.refresh, color: Colors.white, size: 16),
                label: const Text('Reintentar', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
      data: (users) {
        final total = users.length;
        final totalCitas = users.fold<int>(0, (s, u) => s + u.numCitas);
        final totalResenas = users.fold<int>(0, (s, u) => s + u.numResenas);
        final totalPqrs = users.fold<int>(0, (s, u) => s + u.numPqrs);

        final filtered = users.where((u) {
          final matchesRole = _roleFilter == 'todos' || u.rol.toLowerCase() == _roleFilter.toLowerCase();
          final q = _search.toLowerCase();
          final matchesSearch = q.isEmpty ||
              u.fullName.toLowerCase().contains(q) ||
              u.correo.toLowerCase().contains(q);
          return matchesRole && matchesSearch;
        }).toList();

        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: const Color(0xFF1E1E1E),
          onRefresh: () => ref.read(adminUsersProvider.notifier).load(),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            children: [
              // ── KPI Cards en 2x2 Grid (Mobile First) ───────────────────
              Row(
                children: [
                  Expanded(child: _KpiCard(label: 'USUARIOS', value: '$total', color: const Color(0xFF6366F1), icon: Icons.people_alt_rounded)),
                  const SizedBox(width: 10),
                  Expanded(child: _KpiCard(label: 'CITAS', value: '$totalCitas', color: const Color(0xFF8B5CF6), icon: Icons.calendar_month_rounded)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _KpiCard(label: 'RESEÑAS', value: '$totalResenas', color: const Color(0xFF10B981), icon: Icons.star_rounded)),
                  const SizedBox(width: 10),
                  Expanded(child: _KpiCard(label: 'PQRs', value: '$totalPqrs', color: AppColors.primary, icon: Icons.chat_bubble_rounded)),
                ],
              ),
              const SizedBox(height: 16),

              // ── Header + Search + Botón ─────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF222222)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.manage_accounts_rounded, color: Color(0xFF6366F1), size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Gestión de Usuarios',
                                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                              Text('Control total de accesos y roles',
                                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showAddUserDialog(context),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Usuario', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Search field
                    TextField(
                      onChanged: (v) => setState(() => _search = v),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre o correo...',
                        hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280), size: 18),
                        filled: true,
                        fillColor: const Color(0xFF181818),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF262626))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF262626))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Role filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _RoleChip(label: 'Todos', isSelected: _roleFilter == 'todos', onTap: () => setState(() => _roleFilter = 'todos')),
                          const SizedBox(width: 6),
                          _RoleChip(label: 'Clientes', isSelected: _roleFilter == 'usuario', color: const Color(0xFF3B82F6), onTap: () => setState(() => _roleFilter = 'usuario')),
                          const SizedBox(width: 6),
                          _RoleChip(label: 'Prestadores', isSelected: _roleFilter == 'prestador', color: const Color(0xFFF59E0B), onTap: () => setState(() => _roleFilter = 'prestador')),
                          const SizedBox(width: 6),
                          _RoleChip(label: 'Admins', isSelected: _roleFilter == 'admin', color: const Color(0xFFEF4444), onTap: () => setState(() => _roleFilter = 'admin')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── Lista de usuarios en tarjetas móviles ─────────────────────
              if (filtered.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  child: const Text('No se encontraron usuarios.', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                )
              else
                ...filtered.map((u) => _UserCard(
                      user: u,
                      onDelete: () => _confirmDelete(context, u),
                      onEdit: () => _showEditUserDialog(context, u),
                    )),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, AdminUserEntity u) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Eliminar usuario?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(
          'Esta acción eliminará a ${u.fullName} (${u.correo}) del sistema.',
          style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Color(0xFF6B7280)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              final ok = await ref.read(adminUsersProvider.notifier).deleteUser(u.idUsuario, u.authId);
              if (mounted) {
                messenger.showSnackBar(SnackBar(
                  content: Text(ok ? '✅ Usuario eliminado' : '❌ Error al eliminar'),
                  backgroundColor: ok ? AppColors.success : AppColors.error,
                ));
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AddUserDialog(
        onCreated: (nombre, apellido, correo, password, rol, fecha) async {
          final ok = await ref.read(adminUsersProvider.notifier).createUser(
                nombre: nombre,
                apellido: apellido,
                correo: correo,
                password: password,
                rol: rol,
                fechaNacimiento: fecha,
              );
          if (mounted) {
            Navigator.pop(ctx);
            messenger.showSnackBar(SnackBar(
              content: Text(ok ? '✅ Usuario creado exitosamente' : '❌ Error al crear usuario'),
              backgroundColor: ok ? AppColors.success : AppColors.error,
            ));
          }
        },
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, AdminUserEntity u) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _EditUserDialog(
        user: u,
        onSaved: (nombre, apellido, correo, password, rol, fecha) async {
          final ok = await ref.read(adminUsersProvider.notifier).updateUser(
                idUsuario: u.idUsuario,
                authId: u.authId,
                nombre: nombre,
                apellido: apellido,
                correo: correo.trim().isEmpty ? null : correo.trim(),
                password: password.trim().isEmpty ? null : password.trim(),
                rol: rol,
                fechaNacimiento: fecha,
              );
          if (mounted) {
            Navigator.pop(ctx);
            messenger.showSnackBar(SnackBar(
              content: Text(ok ? '✅ Usuario actualizado' : '❌ Error al actualizar'),
              backgroundColor: ok ? AppColors.success : AppColors.error,
            ));
          }
        },
      ),
    );
  }
}

// ── KPI Card (Mobile Friendly) ────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _KpiCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
                Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── User Card (Diseñada especialmente para Móvil) ─────────────────────────────
class _UserCard extends StatelessWidget {
  final AdminUserEntity user;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _UserCard({required this.user, required this.onDelete, required this.onEdit});

  Color _avatarColor(String inicial) {
    const colors = [
      Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899), Color(0xFFF59E0B),
      Color(0xFF10B981), Color(0xFFEF4444), Color(0xFF3B82F6),
    ];
    return colors[inicial.codeUnitAt(0) % colors.length];
  }

  Color _roleColor(String rol) {
    switch (rol.toLowerCase()) {
      case 'admin':
        return const Color(0xFFEF4444);
      case 'prestador':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarColor = _avatarColor(user.inicial);
    final roleColor = _roleColor(user.rol);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Avatar + Name/Email + Role Badge
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: avatarColor,
                child: Text(user.inicial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      user.correo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: roleColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: roleColor.withAlpha(80)),
                ),
                child: Text(
                  user.rol.toUpperCase(),
                  style: TextStyle(color: roleColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFF1E1E1E)),
          const SizedBox(height: 10),

          // Row 2: Badges (Citas, Reseñas, PQRs) & Actions (Editar, Eliminar)
          Row(
            children: [
              _Badge(label: '${user.numCitas} citas', color: const Color(0xFF8B5CF6)),
              const SizedBox(width: 5),
              _Badge(label: '${user.numResenas} res.', color: const Color(0xFF10B981)),
              const SizedBox(width: 5),
              _Badge(label: '${user.numPqrs} PQRs', color: AppColors.primary),
              const Spacer(),

              // Botones de acción
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF262626),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.edit, size: 12, color: Color(0xFFE5E7EB)),
                      SizedBox(width: 4),
                      Text('Editar', style: TextStyle(color: Color(0xFFE5E7EB), fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF450A0A),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF7F1D1D)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.delete, size: 12, color: Color(0xFFFCA5A5)),
                      SizedBox(width: 4),
                      Text('Eliminar', style: TextStyle(color: Color(0xFFFCA5A5), fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _RoleChip({required this.label, required this.isSelected, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withAlpha(35) : const Color(0xFF181818),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? activeColor : const Color(0xFF262626)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? activeColor : const Color(0xFF9CA3AF),
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}

// ── Dialogo Añadir Usuario (Mobile Friendly) ──────────────────────────────────
class _AddUserDialog extends StatefulWidget {
  final Future<void> Function(String nombre, String apellido, String correo, String password, String rol, String? fecha) onCreated;
  const _AddUserDialog({required this.onCreated});

  @override
  State<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<_AddUserDialog> {
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _fechaCtrl = TextEditingController();
  String _rol = 'usuario';
  bool _loading = false;
  bool _obscure = true;

  final _rolOptions = ['usuario', 'prestador', 'admin'];
  final _rolLabels = {'usuario': 'Usuario / Cliente', 'prestador': 'Prestador de Servicios', 'admin': 'Administrador'};

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _correoCtrl.dispose();
    _passwordCtrl.dispose();
    _fechaCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.primary, surface: Color(0xFF1E1E1E)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      _fechaCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF141414),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Añadir Nuevo Usuario', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Color(0xFF6B7280), size: 20),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _field('Nombre', _nombreCtrl)),
              const SizedBox(width: 10),
              Expanded(child: _field('Apellido', _apellidoCtrl)),
            ]),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickDate,
              child: AbsorbPointer(
                child: _field('Fecha de Nacimiento', _fechaCtrl, hint: 'AAAA-MM-DD', suffix: const Icon(Icons.calendar_month, color: Color(0xFF6B7280), size: 18)),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Rol del Sistema', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF2E2E2E)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _rol,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1E1E1E),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  items: _rolOptions.map((r) => DropdownMenuItem(value: r, child: Text(_rolLabels[r] ?? r))).toList(),
                  onChanged: (v) => setState(() => _rol = v ?? 'usuario'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _field('Correo Electrónico', _correoCtrl, keyboard: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _field(
              'Contraseña',
              _passwordCtrl,
              obscure: _obscure,
              suffix: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF6B7280), size: 18),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF9CA3AF),
                      side: const BorderSide(color: Color(0xFF333333)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _loading
                        ? null
                        : () async {
                            if (_nombreCtrl.text.trim().isEmpty || _correoCtrl.text.trim().isEmpty || _passwordCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Por favor completa los campos obligatorios')),
                              );
                              return;
                            }
                            setState(() => _loading = true);
                            await widget.onCreated(
                              _nombreCtrl.text.trim(),
                              _apellidoCtrl.text.trim(),
                              _correoCtrl.text.trim(),
                              _passwordCtrl.text.trim(),
                              _rol,
                              _fechaCtrl.text.trim().isEmpty ? null : _fechaCtrl.text.trim(),
                            );
                          },
                    child: _loading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Guardar', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {String? hint, bool obscure = false, TextInputType? keyboard, Widget? suffix}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 5),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          keyboardType: keyboard,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF4B5563), fontSize: 12),
            suffixIcon: suffix,
            filled: true,
            fillColor: const Color(0xFF1E1E1E),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2E2E2E))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2E2E2E))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
          ),
        ),
      ],
    );
  }
}

// ── Dialogo Editar Usuario (Mobile Friendly) ──────────────────────────────────
class _EditUserDialog extends StatefulWidget {
  final AdminUserEntity user;
  final Future<void> Function(String nombre, String apellido, String correo, String password, String rol, String? fecha) onSaved;
  const _EditUserDialog({required this.user, required this.onSaved});

  @override
  State<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<_EditUserDialog> {
  late final TextEditingController _nombreCtrl = TextEditingController(text: widget.user.nombre);
  late final TextEditingController _apellidoCtrl = TextEditingController(text: widget.user.apellido);
  late final TextEditingController _correoCtrl = TextEditingController(text: widget.user.correo);
  late final TextEditingController _passwordCtrl = TextEditingController();
  late final TextEditingController _fechaCtrl = TextEditingController(text: widget.user.fechaNacimiento ?? '');
  late String _rol = widget.user.rol;
  bool _loading = false;

  final _rolOptions = ['usuario', 'prestador', 'admin'];
  final _rolLabels = {'usuario': 'Usuario / Cliente', 'prestador': 'Prestador de Servicios', 'admin': 'Administrador'};

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _correoCtrl.dispose();
    _passwordCtrl.dispose();
    _fechaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF141414),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Editar Usuario', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Color(0xFF6B7280), size: 20),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Nombre + Apellido
            Row(children: [
              Expanded(child: _field('Nombre', _nombreCtrl)),
              const SizedBox(width: 10),
              Expanded(child: _field('Apellido', _apellidoCtrl)),
            ]),
            const SizedBox(height: 12),
            // Correo
            _field('Correo electrónico', _correoCtrl, hint: 'usuario@ejemplo.com', keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            // Contraseña
            _field('Nueva Contraseña', _passwordCtrl, hint: 'Dejar vacío para no cambiar', obscure: true),
            const SizedBox(height: 12),
            // Fecha nacimiento
            _field('Fecha de Nacimiento', _fechaCtrl, hint: 'AAAA-MM-DD'),
            const SizedBox(height: 12),
            // Rol
            const Text('Rol del Sistema', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF2E2E2E)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _rol,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1E1E1E),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  items: _rolOptions.map((r) => DropdownMenuItem(value: r, child: Text(_rolLabels[r] ?? r))).toList(),
                  onChanged: (v) => setState(() => _rol = v ?? 'usuario'),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF9CA3AF),
                      side: const BorderSide(color: Color(0xFF333333)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _loading
                        ? null
                        : () async {
                            setState(() => _loading = true);
                            await widget.onSaved(
                              _nombreCtrl.text.trim(),
                              _apellidoCtrl.text.trim(),
                              _correoCtrl.text.trim(),
                              _passwordCtrl.text.trim(),
                              _rol,
                              _fechaCtrl.text.trim().isEmpty ? null : _fechaCtrl.text.trim(),
                            );
                          },
                    child: _loading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Guardar', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {String? hint, TextInputType? keyboardType, bool obscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 5),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF4B5563), fontSize: 12),
            filled: true,
            fillColor: const Color(0xFF1E1E1E),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2E2E2E))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2E2E2E))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
          ),
        ),
      ],
    );
  }
}
