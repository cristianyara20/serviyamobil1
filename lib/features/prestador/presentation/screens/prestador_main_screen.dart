import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';

import '../../../auth/domain/models/user_entity.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../home/presentation/screens/welcome_screen.dart';
import '../../domain/models/prestador_solicitud_entity.dart';
import '../../domain/models/prestador_stats_entity.dart';
import '../controllers/prestador_panel_controller.dart';

class PrestadorMainScreen extends ConsumerStatefulWidget {
  final UserEntity user;
  const PrestadorMainScreen({super.key, required this.user});

  @override
  ConsumerState<PrestadorMainScreen> createState() => _PrestadorMainScreenState();
}

class _PrestadorMainScreenState extends ConsumerState<PrestadorMainScreen> {
  int _currentTab = 0; // 0 = Solicitudes, 1 = En Curso, 2 = Historial
  String _sortOrder = 'recientes'; // recientes, antiguos

  String _formatFecha(String raw) {
    if (raw.isEmpty) return 'Fecha por coordinar';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('d/M/yyyy, HH:mm:ss').format(dt);
    } catch (_) {
      return raw;
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('¿Deseas salir del panel de prestador?',
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
    final idPrestador = widget.user.idUsuario ?? int.tryParse(widget.user.id) ?? 0;
    final panelState = ref.watch(prestadorPanelProvider(idPrestador));
    final controller = ref.read(prestadorPanelProvider(idPrestador).notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Icon(Icons.handyman_rounded, color: AppColors.primary, size: 24),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Panel de Prestador', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            Text('Bienvenido de nuevo, ${widget.user.nombre}', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF6B7280)),
            onPressed: _showLogoutDialog,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: panelState.isLoading && panelState.stats == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: const Color(0xFF1E1E1E),
              onRefresh: () => controller.load(),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                children: [
                  // 1. Availability Status Pill Selector (Top)
                  _buildAvailabilityBar(panelState.stats?.disponibilidad ?? 'disponible', controller),
                  const SizedBox(height: 14),

                  // 2. Summary & Level Cards (Mobile First)
                  _buildStatsAndLevel(panelState.stats),
                  const SizedBox(height: 18),

                  // 3. Tabs Bar & Sort dropdown
                  _buildTabsBar(panelState.reservas),
                  const SizedBox(height: 14),

                  // 4. Content List
                  _buildTabContent(panelState.reservas, controller),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildAvailabilityBar(String currentDisp, PrestadorPanelController controller) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFF262626)),
      ),
      child: Row(
        children: [
          _StatusPill(
            label: 'Disponible',
            isActive: currentDisp == 'disponible',
            activeColor: const Color(0xFF10B981),
            onTap: () => controller.setDisponibilidad('disponible'),
          ),
          _StatusPill(
            label: 'Ocupado',
            isActive: currentDisp == 'ocupado',
            activeColor: const Color(0xFFEA580C),
            onTap: () => controller.setDisponibilidad('ocupado'),
          ),
          _StatusPill(
            label: 'Inactivo',
            isActive: currentDisp == 'inactivo',
            activeColor: const Color(0xFFEF4444),
            onTap: () => controller.setDisponibilidad('inactivo'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsAndLevel(PrestadorStatsEntity? stats) {
    final completados = stats?.completados ?? 0;
    final calif = stats?.calificacion ?? 5.0;
    final activos = stats?.activos ?? 0;
    final nivel = stats?.nivel ?? 'Experto';
    final progreso = stats?.progresoMeta ?? 0.75;

    return Column(
      children: [
        // RESUMEN CARD
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF242424)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'RESUMEN',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SummaryItem(label: 'Completados', value: '$completados', color: const Color(0xFFF97316)),
                  Container(width: 1, height: 32, color: const Color(0xFF262626)),
                  _SummaryItem(
                    label: 'Calificación',
                    value: calif.toStringAsFixed(1),
                    color: const Color(0xFFFBBF24),
                    icon: Icons.star_rounded,
                  ),
                  Container(width: 1, height: 32, color: const Color(0xFF262626)),
                  _SummaryItem(label: 'Activos', value: '$activos', color: const Color(0xFF10B981)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // NIVEL ACTUAL CARD (Orange Gradient)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEA580C), Color(0xFFC2410C), Color(0xFF9A3412)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEA580C).withAlpha(40),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(50),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'NIVEL ACTUAL',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),
                  ),
                  const Text('🏅', style: TextStyle(fontSize: 18)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                nivel,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'PRÓXIMA META',
                    style: TextStyle(color: Color(0xFFFED7AA), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${(progreso * 100).toInt()}%',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progreso,
                  minHeight: 8,
                  backgroundColor: Colors.black.withAlpha(60),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFDE047)),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '¡Has completado servicios increíbles! Estás a muy poco de subir a rango Maestro ⭐.',
                style: TextStyle(color: Color(0xFFFFEDD5), fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabsBar(List<PrestadorSolicitudEntity> all) {
    final solicitudesCount = all.where((r) => r.isPendiente).length;
    final enCursoCount = all.where((r) => r.isEnCurso).length;
    final historialCount = all.where((r) => r.isCompletada || r.isCancelada).length;

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _TabItem(
                  label: 'Solicitudes',
                  count: solicitudesCount,
                  isSelected: _currentTab == 0,
                  onTap: () => setState(() => _currentTab = 0),
                ),
                const SizedBox(width: 8),
                _TabItem(
                  label: 'Servicios en Curso',
                  count: enCursoCount,
                  isSelected: _currentTab == 1,
                  onTap: () => setState(() => _currentTab = 1),
                ),
                const SizedBox(width: 8),
                _TabItem(
                  label: 'Historial',
                  count: historialCount,
                  isSelected: _currentTab == 2,
                  onTap: () => setState(() => _currentTab = 2),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF262626)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _sortOrder,
              dropdownColor: const Color(0xFF1A1A1A),
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF9CA3AF), size: 16),
              items: const [
                DropdownMenuItem(value: 'recientes', child: Text('Recientes primero')),
                DropdownMenuItem(value: 'antiguos', child: Text('Antiguos primero')),
              ],
              onChanged: (v) => setState(() => _sortOrder = v ?? 'recientes'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent(List<PrestadorSolicitudEntity> all, PrestadorPanelController controller) {
    List<PrestadorSolicitudEntity> list;
    if (_currentTab == 0) {
      list = all.where((r) => r.isPendiente).toList();
    } else if (_currentTab == 1) {
      list = all.where((r) => r.isEnCurso).toList();
    } else {
      list = all.where((r) => r.isCompletada || r.isCancelada).toList();
    }

    if (_sortOrder == 'recientes') {
      list.sort((a, b) => b.fechaAgenda.compareTo(a.fechaAgenda));
    } else {
      list.sort((a, b) => a.fechaAgenda.compareTo(b.fechaAgenda));
    }

    if (list.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(
              _currentTab == 0
                  ? Icons.inbox_rounded
                  : (_currentTab == 1 ? Icons.work_outline_rounded : Icons.history_rounded),
              size: 46,
              color: const Color(0xFF374151),
            ),
            const SizedBox(height: 10),
            Text(
              _currentTab == 0
                  ? 'No tienes solicitudes pendientes.'
                  : (_currentTab == 1
                      ? 'No tienes servicios activos en este momento.'
                      : 'No hay servicios registrados en tu historial.'),
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (final r in list) ...[
          _SolicitudCard(
            solicitud: r,
            formattedFecha: _formatFecha(r.fechaAgenda),
            currentTab: _currentTab,
            onAceptar: () => _handleAceptar(r, controller),
            onRechazar: () => _handleRechazar(r, controller),
            onCompletar: () => _handleCompletar(r, controller),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  void _handleAceptar(PrestadorSolicitudEntity r, PrestadorPanelController controller) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await controller.aceptarSolicitud(r.idReserva);
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? '✅ Solicitud aceptada y asignada' : '❌ Error al aceptar solicitud'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  void _handleRechazar(PrestadorSolicitudEntity r, PrestadorPanelController controller) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await controller.rechazarSolicitud(r.idReserva);
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? '🚫 Solicitud rechazada' : '❌ Error al rechazar solicitud'),
        backgroundColor: ok ? const Color(0xFFEF4444) : AppColors.error,
      ),
    );
  }

  void _handleCompletar(PrestadorSolicitudEntity r, PrestadorPanelController controller) {
    _showFinalizarConEvidenciaModal(r, controller);
  }

  void _showFinalizarConEvidenciaModal(PrestadorSolicitudEntity r, PrestadorPanelController controller) {
    Uint8List? selectedImageBytes;
    String fileExtension = 'jpg';
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final hasPhoto = selectedImageBytes != null;

            Future<void> pickImage(ImageSource source) async {
              try {
                final picker = ImagePicker();
                final picked = await picker.pickImage(
                  source: source,
                  imageQuality: 85,
                  maxWidth: 1280,
                  maxHeight: 1280,
                );
                if (picked != null) {
                  final bytes = await picked.readAsBytes();
                  final ext = picked.name.contains('.')
                      ? picked.name.split('.').last.toLowerCase()
                      : 'jpg';
                  setModalState(() {
                    selectedImageBytes = bytes;
                    fileExtension = ext;
                  });
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al capturar imagen: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF141414),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF262626)),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Evidencia de Finalización',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Reserva #${r.idReserva} • ${r.nombreCliente}',
                          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1917),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFEA580C).withAlpha(80)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded, color: Color(0xFFFB923C), size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Por política de calidad y seguridad, es obligatorio tomar una fotografía del servicio terminado antes de finalizarlo.',
                                style: TextStyle(color: Color(0xFFFDBA74), fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Preview or Placeholder
                      if (hasPhoto) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            alignment: Alignment.topRight,
                            children: [
                              Image.memory(
                                selectedImageBytes!,
                                width: double.infinity,
                                height: 220,
                                fit: BoxFit.cover,
                              ),
                              Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(180),
                                  borderRadius: BorderRadius.circular(8),
                                ),

                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 14),
                                    SizedBox(width: 4),
                                    Text('Foto cargada', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Color(0xFF3B3B3B)),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: isSubmitting ? null : () => pickImage(ImageSource.camera),
                                icon: const Icon(Icons.photo_camera_rounded, size: 16),
                                label: const Text('Repetir Foto', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Color(0xFF3B3B3B)),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: isSubmitting ? null : () => pickImage(ImageSource.gallery),
                                icon: const Icon(Icons.photo_library_rounded, size: 16),
                                label: const Text('De Galería', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Container(
                          width: double.infinity,
                          height: 170,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D0D0D),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF2A2A2A), width: 1.5),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.camera_alt_outlined, size: 42, color: Color(0xFF6B7280)),
                              const SizedBox(height: 8),
                              const Text(
                                'Aún no has capturado la evidencia',
                                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () => pickImage(ImageSource.camera),
                                    icon: const Icon(Icons.camera_alt_rounded, size: 16),
                                    label: const Text('Cámara', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 10),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(color: Color(0xFF3F3F46)),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () => pickImage(ImageSource.gallery),
                                    icon: const Icon(Icons.photo_library_rounded, size: 16),
                                    label: const Text('Galería', style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Cancelar', style: TextStyle(color: Color(0xFF9CA3AF))),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasPhoto ? const Color(0xFF10B981) : const Color(0xFF262626),
                    foregroundColor: hasPhoto ? Colors.white : const Color(0xFF6B7280),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: (!hasPhoto || isSubmitting)
                      ? null
                      : () async {
                          setModalState(() => isSubmitting = true);
                          final ok = await controller.completarServicio(
                            idReserva: r.idReserva,
                            imageBytes: selectedImageBytes!,
                            fileExtension: fileExtension,
                          );
                          if (context.mounted) {
                            Navigator.pop(dialogCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ok
                                    ? '🎉 ¡Servicio finalizado con éxito y evidencia guardada en API de Go!'
                                    : '❌ Error al finalizar servicio'),
                                backgroundColor: ok ? AppColors.success : AppColors.error,
                              ),
                            );
                          }
                        },
                  icon: isSubmitting
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_rounded, size: 16),
                  label: Text(
                    isSubmitting ? 'Finalizando en API...' : 'Finalizar Servicio',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

}

// ── Status Pill ───────────────────────────────────────────────────────────────
class _StatusPill extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _StatusPill({
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : const Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Summary Item ─────────────────────────────────────────────────────────────
class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData? icon;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
            ],
            Text(
              value,
              style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Tab Item ─────────────────────────────────────────────────────────────────
class _TabItem extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFFEA580C) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFEA580C) : const Color(0xFF262626),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Solicitud Card ───────────────────────────────────────────────────────────
class _SolicitudCard extends StatelessWidget {
  final PrestadorSolicitudEntity solicitud;
  final String formattedFecha;
  final int currentTab;
  final VoidCallback onAceptar;
  final VoidCallback onRechazar;
  final VoidCallback onCompletar;

  const _SolicitudCard({
    required this.solicitud,
    required this.formattedFecha,
    required this.currentTab,
    required this.onAceptar,
    required this.onRechazar,
    required this.onCompletar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila Superior: Icono + Servicio & Cliente
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Box
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF262626),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.move_to_inbox_rounded, color: Color(0xFFFB923C), size: 20),
              ),
              const SizedBox(width: 10),

              // Title & Client
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      solicitud.nombreServicio,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.person_rounded, color: Color(0xFF818CF8), size: 13),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            solicitud.nombreCliente,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFFE5E7EB), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    if (solicitud.correoCliente.isNotEmpty)
                      Text(
                        solicitud.correoCliente,
                        style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Fecha
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, color: Color(0xFF93C5FD), size: 13),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Para el: $formattedFecha',
                  style: const TextStyle(color: Color(0xFFFB923C), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          if (solicitud.direccion.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, color: Color(0xFF6B7280), size: 13),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    solicitud.direccion,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // Actions
          if (currentTab == 0) // Solicitudes
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: onAceptar,
                    child: const Text('Aceptar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF262626),
                      foregroundColor: const Color(0xFF9CA3AF),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: onRechazar,
                    child: const Text('Rechazar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ],
            )
          else if (currentTab == 1) // En Curso
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: onCompletar,
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: const Text('Marcar como Completado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            )
          else // Historial
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (solicitud.isCompletada ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withAlpha(30),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                solicitud.estadoReserva.toUpperCase(),
                style: TextStyle(
                  color: solicitud.isCompletada ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
