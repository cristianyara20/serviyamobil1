import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/models/admin_resena_entity.dart';
import '../controllers/admin_resenas_controller.dart';

class AdminResenasTab extends ConsumerStatefulWidget {
  const AdminResenasTab({super.key});

  @override
  ConsumerState<AdminResenasTab> createState() => _AdminResenasTabState();
}

class _AdminResenasTabState extends ConsumerState<AdminResenasTab> {
  String _search = '';
  String _sortOrder = 'recientes'; // recientes, antiguos, mayor, menor
  int _scoreFilter = 0; // 0 = todas, 5, 4, 3, 2, 1

  String _formatFecha(String raw) {
    if (raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      // Formato ej: 30 de agosto de 2026
      return DateFormat("d 'de' MMMM 'de' yyyy", 'es_ES').format(dt);
    } catch (_) {
      try {
        final dt = DateTime.parse(raw).toLocal();
        return DateFormat("d 'de' MMMM 'de' yyyy").format(dt);
      } catch (_) {
        return raw;
      }
    }
  }

  void _confirmDelete(BuildContext context, AdminResenaEntity r) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF181818),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 22),
            SizedBox(width: 8),
            Text('Eliminar Reseña', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar la reseña de "${r.nombreCliente}" para el servicio de "${r.nombreServicio}"?',
          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              final ok = await ref.read(adminResenasProvider.notifier).deleteResena(r.idCalificacion);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(ok ? '✅ Reseña eliminada con éxito' : '❌ Error al eliminar reseña'),
                  backgroundColor: ok ? AppColors.success : AppColors.error,
                ),
              );
            },
            child: const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resenasState = ref.watch(adminResenasProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: resenasState.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 14),
              Text('Cargando valoraciones y reseñas...', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
            ],
          ),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                const SizedBox(height: 12),
                Text('Error al cargar reseñas: $err', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 13)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () => ref.read(adminResenasProvider.notifier).load(),
                  icon: const Icon(Icons.refresh, color: Colors.white, size: 16),
                  label: const Text('Reintentar', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
        data: (allResenas) {
          // Filtrado
          var filtered = allResenas.where((r) {
            final matchesScore = _scoreFilter == 0 || r.puntuacion.toInt() == _scoreFilter;
            final q = _search.toLowerCase();
            final matchesSearch = q.isEmpty ||
                r.nombreCliente.toLowerCase().contains(q) ||
                r.nombrePrestador.toLowerCase().contains(q) ||
                r.nombreServicio.toLowerCase().contains(q) ||
                r.comentario.toLowerCase().contains(q);
            return matchesScore && matchesSearch;
          }).toList();

          // Ordenamiento
          if (_sortOrder == 'recientes') {
            filtered.sort((a, b) => b.fechaCalificacion.compareTo(a.fechaCalificacion));
          } else if (_sortOrder == 'antiguos') {
            filtered.sort((a, b) => a.fechaCalificacion.compareTo(b.fechaCalificacion));
          } else if (_sortOrder == 'mayor') {
            filtered.sort((a, b) => b.puntuacion.compareTo(a.puntuacion));
          } else if (_sortOrder == 'menor') {
            filtered.sort((a, b) => a.puntuacion.compareTo(b.puntuacion));
          }

          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: const Color(0xFF1E1E1E),
            onRefresh: () => ref.read(adminResenasProvider.notifier).load(),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              children: [
                // Header (Mobile First)
                _buildHeader(context, allResenas.length),
                const SizedBox(height: 14),

                // Controls (Sort & Search & Chips)
                _buildControls(),
                const SizedBox(height: 14),

                // Reseñas List
                if (filtered.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        const Icon(Icons.star_outline_rounded, size: 48, color: Color(0xFF374151)),
                        const SizedBox(height: 10),
                        Text(
                          _search.isNotEmpty || _scoreFilter != 0
                              ? 'No se encontraron reseñas con esos filtros.'
                              : 'No hay valoraciones registradas.',
                          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                        ),
                      ],
                    ),
                  )
                else
                  for (final r in filtered) ...[
                    _ResenaCard(
                      resena: r,
                      formattedFecha: _formatFecha(r.fechaCalificacion),
                      onDelete: () => _confirmDelete(context, r),
                    ),
                    const SizedBox(height: 12),
                  ],
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int total) {
    return Container(
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
              const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Valoraciones y Reseñas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF78350F).withAlpha(120),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFF59E0B).withAlpha(140)),
                ),
                child: Text(
                  '$total reseñas',
                  style: const TextStyle(
                    color: Color(0xFFFDE68A),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => ref.read(adminResenasProvider.notifier).load(),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.refresh, size: 13, color: Color(0xFF93C5FD)),
                      SizedBox(width: 4),
                      Text('Refrescar', style: TextStyle(color: Color(0xFF93C5FD), fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Feedback directo de los clientes',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Column(
      children: [
        // Sort & Search
        Row(
          children: [
            // Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF262626)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _sortOrder,
                  dropdownColor: const Color(0xFF1A1A1A),
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF9CA3AF), size: 18),
                  items: const [
                    DropdownMenuItem(value: 'recientes', child: Text('Recientes primero')),
                    DropdownMenuItem(value: 'antiguos', child: Text('Antiguos primero')),
                    DropdownMenuItem(value: 'mayor', child: Text('Mejor puntuación')),
                    DropdownMenuItem(value: 'menor', child: Text('Menor puntuación')),
                  ],
                  onChanged: (v) => setState(() => _sortOrder = v ?? 'recientes'),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Search
            Expanded(
              child: TextField(
                style: const TextStyle(color: Colors.white, fontSize: 13),
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Buscar cliente o servicio...',
                  hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280), size: 16),
                  filled: true,
                  fillColor: const Color(0xFF141414),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF262626))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF262626))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Filter chips (Todas, 5 stars, 4 stars, 3 stars, 2 stars, 1 star)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(label: 'Todas', isSelected: _scoreFilter == 0, onTap: () => setState(() => _scoreFilter = 0)),
              const SizedBox(width: 6),
              _FilterChip(label: '⭐ 5 estrellas', isSelected: _scoreFilter == 5, color: const Color(0xFFF59E0B), onTap: () => setState(() => _scoreFilter = 5)),
              const SizedBox(width: 6),
              _FilterChip(label: '⭐ 4 estrellas', isSelected: _scoreFilter == 4, color: const Color(0xFFF59E0B), onTap: () => setState(() => _scoreFilter = 4)),
              const SizedBox(width: 6),
              _FilterChip(label: '⭐ 3 estrellas', isSelected: _scoreFilter == 3, color: const Color(0xFFF59E0B), onTap: () => setState(() => _scoreFilter = 3)),
              const SizedBox(width: 6),
              _FilterChip(label: '⭐ 2 estrellas', isSelected: _scoreFilter == 2, color: const Color(0xFFF59E0B), onTap: () => setState(() => _scoreFilter = 2)),
              const SizedBox(width: 6),
              _FilterChip(label: '⭐ 1 estrella', isSelected: _scoreFilter == 1, color: const Color(0xFFEF4444), onTap: () => setState(() => _scoreFilter = 1)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Tarjeta de Reseña (Diseño Exacto Mobile-First) ───────────────────────────
class _ResenaCard extends StatelessWidget {
  final AdminResenaEntity resena;
  final String formattedFecha;
  final VoidCallback onDelete;

  const _ResenaCard({
    required this.resena,
    required this.formattedFecha,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF242424)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila 1: Avatar + Nombre Cliente + Servicio & Puntuación Grande
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar círculo dorado
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF332005),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD97706).withAlpha(150)),
                ),
                child: Text(
                  resena.inicialCliente,
                  style: const TextStyle(
                    color: Color(0xFFFBBF24),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Cliente + Servicio
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resena.nombreCliente,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Servicio: ${resena.nombreServicio}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
                    ),
                  ],
                ),
              ),

              // Big Rating score (5.0)
              Text(
                resena.puntuacion.toStringAsFixed(1),
                style: const TextStyle(
                  color: Color(0xFF4A4020),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Prestador Badge (morado)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF28103F),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF6B21A8).withAlpha(120)),
            ),
            child: Text(
              'Prestador: ${resena.nombrePrestador}',
              style: const TextStyle(
                color: Color(0xFFC084FC),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Estrellas doradas + score
          Row(
            children: [
              for (int i = 1; i <= 5; i++)
                Icon(
                  i <= resena.puntuacion.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: const Color(0xFFFBBF24),
                  size: 16,
                ),
              const SizedBox(width: 6),
              Text(
                '${resena.puntuacion.round()}/5',
                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Comentario del cliente
          if (resena.comentario.isNotEmpty)
            Text(
              '"${resena.comentario}"',
              style: const TextStyle(
                color: Color(0xFFE5E7EB),
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),

          const SizedBox(height: 10),

          // Footer: Fecha + Botón Eliminar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formattedFecha,
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
              ),
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D1010),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF7F1D1D).withAlpha(140)),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFF87171),
                    size: 16,
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

// ── Filter Chip ───────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withAlpha(35) : const Color(0xFF141414),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFF262626),
          ),
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
