import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/models/prestador_operativo_entity.dart';
import '../../domain/models/reserva_historial_entity.dart';
import '../controllers/prestadores_controller.dart';

class AdminPrestadoresTab extends ConsumerStatefulWidget {
  const AdminPrestadoresTab({super.key});

  @override
  ConsumerState<AdminPrestadoresTab> createState() => _AdminPrestadoresTabState();
}

class _AdminPrestadoresTabState extends ConsumerState<AdminPrestadoresTab> {
  String _filter = 'todos'; // todos, disponible, ocupado, inactivo
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final prestadoresState = ref.watch(prestadoresListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: prestadoresState.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 14),
              Text(
                'Consultando API de Go...',
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
              ),
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
                Text(
                  'Error al consultar API: $err',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () => ref.read(prestadoresListProvider.notifier).load(),
                  icon: const Icon(Icons.refresh, color: Colors.white, size: 16),
                  label: const Text('Reintentar', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
        data: (allPrestadores) {
          // Filtrado
          final filtered = allPrestadores.where((p) {
            final matchesFilter = _filter == 'todos' ||
                p.estadoDisponibilidad.toLowerCase() == _filter.toLowerCase();
            final query = _search.toLowerCase();
            final matchesSearch = query.isEmpty ||
                p.fullName.toLowerCase().contains(query) ||
                p.correo.toLowerCase().contains(query) ||
                p.experiencia.toLowerCase().contains(query);
            return matchesFilter && matchesSearch;
          }).toList();

          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: const Color(0xFF1E1E1E),
            onRefresh: () => ref.read(prestadoresListProvider.notifier).load(),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              children: [
                // Header (Mobile First)
                _buildHeader(context, allPrestadores.length),
                const SizedBox(height: 14),

                // Search & Filter
                _buildSearchAndFilters(),
                const SizedBox(height: 14),

                // List of Prestadores
                if (filtered.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        const Icon(Icons.build_circle_outlined, size: 46, color: Color(0xFF374151)),
                        const SizedBox(height: 10),
                        Text(
                          _search.isNotEmpty || _filter != 'todos'
                              ? 'No se encontraron prestadores con esos filtros.'
                              : 'No hay prestadores registrados en el sistema.',
                          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                        ),
                      ],
                    ),
                  )
                else
                  for (final p in filtered) ...[
                    _PrestadorCard(
                      prestador: p,
                      onVerReservas: () => _showReservasModal(context, p),
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
              const Icon(Icons.handyman_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Prestadores',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(35),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$total total',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.refresh, size: 18, color: Color(0xFF93C5FD)),
                tooltip: 'Refrescar',
                onPressed: () => ref.read(prestadoresListProvider.notifier).load(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Disponibilidad y estado en tiempo real consultado mediante la API de Go',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        // Search bar
        TextField(
          style: const TextStyle(color: Colors.white, fontSize: 13),
          onChanged: (v) => setState(() => _search = v),
          decoration: InputDecoration(
            hintText: 'Buscar por nombre, correo o especialidad...',
            hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280), size: 18),
            filled: true,
            fillColor: const Color(0xFF141414),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF262626)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF262626)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: 'Todos',
                isSelected: _filter == 'todos',
                onTap: () => setState(() => _filter = 'todos'),
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: 'Disponibles',
                isSelected: _filter == 'disponible',
                color: const Color(0xFF10B981),
                onTap: () => setState(() => _filter = 'disponible'),
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: 'Ocupados',
                isSelected: _filter == 'ocupado',
                color: const Color(0xFFF59E0B),
                onTap: () => setState(() => _filter = 'ocupado'),
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: 'Inactivos',
                isSelected: _filter == 'inactivo',
                color: const Color(0xFFEF4444),
                onTap: () => setState(() => _filter = 'inactivo'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showReservasModal(BuildContext context, PrestadorOperativoEntity p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ReservasAtendidasModal(prestador: p),
    );
  }
}

// ── Tarjeta de Prestador (Mobile First) ───────────────────────────────────────
class _PrestadorCard extends StatelessWidget {
  final PrestadorOperativoEntity prestador;
  final VoidCallback onVerReservas;

  const _PrestadorCard({
    required this.prestador,
    required this.onVerReservas,
  });

  @override
  Widget build(BuildContext context) {
    // Status styles
    Color statusColor;
    String statusText;
    if (prestador.isDisponible) {
      statusColor = const Color(0xFF10B981);
      statusText = '• DISPONIBLE';
    } else if (prestador.isOcupado) {
      statusColor = const Color(0xFFF59E0B);
      statusText = '• OCUPADO';
    } else {
      statusColor = const Color(0xFFEF4444);
      statusText = '• INACTIVO';
    }

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Avatar + Name + ID & Status Badge
          Row(
            children: [
              // Avatar
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF2B1408),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEA580C).withAlpha(120)),
                ),
                child: Text(
                  prestador.inicial,
                  style: const TextStyle(
                    color: Color(0xFFFB923C),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Name + ID
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prestador.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'ID: #${prestador.idPrestador}',
                      style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
                    ),
                  ],
                ),
              ),

              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: statusColor.withAlpha(100)),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFF1E1E1E)),
          const SizedBox(height: 10),

          // Detail rows
          _buildInfoRow('Correo:', prestador.correo),
          const SizedBox(height: 6),
          _buildRatingRow('Calificación:', prestador.calificacionPromedio),
          const SizedBox(height: 6),
          _buildInfoRow('Experiencia:', prestador.experiencia, isItalic: true),

          const SizedBox(height: 12),

          // Ver Reservas Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2B1408),
                foregroundColor: const Color(0xFFFB923C),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFF7C2D12)),
                ),
              ),
              onPressed: onVerReservas,
              child: const Text(
                'Ver Reservas Atendidas',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isItalic = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFFE5E7EB),
              fontSize: 12,
              fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingRow(String label, double rating) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
        ),
        Row(
          children: [
            const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 15),
            const SizedBox(width: 3),
            Text(
              rating.toStringAsFixed(1),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
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

// ── Modal de Reservas Atendidas ───────────────────────────────────────────────
class _ReservasAtendidasModal extends ConsumerStatefulWidget {
  final PrestadorOperativoEntity prestador;
  const _ReservasAtendidasModal({required this.prestador});

  @override
  ConsumerState<_ReservasAtendidasModal> createState() => _ReservasAtendidasModalState();
}

class _ReservasAtendidasModalState extends ConsumerState<_ReservasAtendidasModal> {
  late Future<List<ReservaHistorialEntity>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(prestadoresListProvider.notifier).getHistorial(widget.prestador.idPrestador);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scrollController) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF333333),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reservas de ${widget.prestador.fullName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Historial de citas asignadas y completadas',
                        style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Color(0xFF9CA3AF), size: 20),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFF262626)),
            const SizedBox(height: 10),

            // Future list
            Expanded(
              child: FutureBuilder<List<ReservaHistorialEntity>>(
                future: _future,
                builder: (ctx, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error al cargar historial: ${snapshot.error}',
                        style: const TextStyle(color: AppColors.error, fontSize: 12),
                      ),
                    );
                  }
                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, color: Color(0xFF4B5563), size: 40),
                          SizedBox(height: 10),
                          Text(
                            'No hay reservas registradas para este prestador.',
                            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    controller: scrollController,
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, idx) {
                      final r = items[idx];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF181818),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF2A2A2A)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    r.nombreServicio,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _getEstadoColor(r.estadoReserva).withAlpha(30),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    r.estadoReserva.toUpperCase(),
                                    style: TextStyle(
                                      color: _getEstadoColor(r.estadoReserva),
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Cliente: ${r.nombreCliente}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                            ),
                            if (r.fechaAgenda.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                'Fecha: ${r.fechaAgenda}',
                                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
                              ),
                            ],
                            if (r.direccion.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                'Dirección: ${r.direccion}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'completada':
        return const Color(0xFF10B981);
      case 'en_progreso':
      case 'confirmada':
        return const Color(0xFF3B82F6);
      case 'cancelada':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }
}
