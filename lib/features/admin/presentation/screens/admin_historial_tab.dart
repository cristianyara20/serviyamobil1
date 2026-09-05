import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/models/reserva_historial_entity.dart';
import '../controllers/historial_servicios_controller.dart';

class AdminHistorialTab extends ConsumerStatefulWidget {
  const AdminHistorialTab({super.key});

  @override
  ConsumerState<AdminHistorialTab> createState() => _AdminHistorialTabState();
}

class _AdminHistorialTabState extends ConsumerState<AdminHistorialTab> {
  String _search = '';
  String _statusFilter = 'todos'; // todos, terminada, cancelada, confirmada, pendiente
  String _sortOrder = 'recientes'; // recientes, antiguos

  String _formatFecha(String raw) {
    if (raw.isEmpty) return 'No especificada';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('yyyy-MM-dd HH:mm').format(dt);
    } catch (_) {
      return raw;
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'terminada':
      case 'completada':
        return const Color(0xFF10B981); // Verde
      case 'en_progreso':
      case 'confirmada':
        return const Color(0xFF3B82F6); // Azul
      case 'cancelada':
        return const Color(0xFFEF4444); // Rojo
      default:
        return const Color(0xFFF59E0B); // Ámbar
    }
  }

  @override
  Widget build(BuildContext context) {
    final historialState = ref.watch(historialServiciosProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: historialState.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 14),
              Text('Consultando historial en API de Go...', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
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
                Text('Error al consultar historial: $err', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 13)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () => ref.read(historialServiciosProvider.notifier).load(),
                  icon: const Icon(Icons.refresh, color: Colors.white, size: 16),
                  label: const Text('Reintentar', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
        data: (allReservas) {
          // Filtrado
          var filtered = allReservas.where((r) {
            final matchesStatus = _statusFilter == 'todos' ||
                r.estadoReserva.toLowerCase() == _statusFilter.toLowerCase() ||
                (_statusFilter == 'terminada' && r.estadoReserva.toLowerCase() == 'completada');

            final q = _search.toLowerCase();
            final matchesSearch = q.isEmpty ||
                r.nombreServicio.toLowerCase().contains(q) ||
                r.nombreCliente.toLowerCase().contains(q) ||
                r.direccion.toLowerCase().contains(q) ||
                '#${r.idReserva}'.contains(q) ||
                '#${r.idCliente}'.contains(q);

            return matchesStatus && matchesSearch;
          }).toList();

          // Ordenamiento
          if (_sortOrder == 'recientes') {
            filtered.sort((a, b) => b.fechaAgenda.compareTo(a.fechaAgenda));
          } else {
            filtered.sort((a, b) => a.fechaAgenda.compareTo(b.fechaAgenda));
          }

          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: const Color(0xFF1E1E1E),
            onRefresh: () => ref.read(historialServiciosProvider.notifier).load(),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              children: [
                // Header
                _buildHeader(context, allReservas.length),
                const SizedBox(height: 14),

                // Controls: Sort dropdown & search & filters
                _buildControls(),
                const SizedBox(height: 14),

                // List of services
                if (filtered.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        const Icon(Icons.history_toggle_off_rounded, size: 48, color: Color(0xFF374151)),
                        const SizedBox(height: 10),
                        Text(
                          _search.isNotEmpty || _statusFilter != 'todos'
                              ? 'No se encontraron servicios con esos filtros.'
                              : 'No hay servicios registrados en el historial.',
                          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                        ),
                      ],
                    ),
                  )
                else
                  for (final r in filtered) ...[
                    _ReservaHistorialCard(
                      reserva: r,
                      formattedFecha: _formatFecha(r.fechaAgenda),
                      estadoColor: _getEstadoColor(r.estadoReserva),
                    ),
                    const SizedBox(height: 10),
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
              const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Historial de Servicios',
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
                onPressed: () => ref.read(historialServiciosProvider.notifier).load(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Lista consolidada de servicios consultados mediante la API de Go',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sort Dropdown & Search Bar
        Row(
          children: [
            // Order dropdown
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
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF9CA3AF), size: 16),
                  items: const [
                    DropdownMenuItem(value: 'recientes', child: Text('Recientes')),
                    DropdownMenuItem(value: 'antiguos', child: Text('Antiguos')),
                  ],
                  onChanged: (v) => setState(() => _sortOrder = v ?? 'recientes'),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Search
            Expanded(
              child: TextField(
                style: const TextStyle(color: Colors.white, fontSize: 12),
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Buscar servicio...',
                  hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280), size: 16),
                  filled: true,
                  fillColor: const Color(0xFF141414),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF262626))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF262626))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Status Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(label: 'Todos', isSelected: _statusFilter == 'todos', onTap: () => setState(() => _statusFilter = 'todos')),
              const SizedBox(width: 6),
              _FilterChip(label: 'Terminadas', isSelected: _statusFilter == 'terminada', color: const Color(0xFF10B981), onTap: () => setState(() => _statusFilter = 'terminada')),
              const SizedBox(width: 6),
              _FilterChip(label: 'Canceladas', isSelected: _statusFilter == 'cancelada', color: const Color(0xFFEF4444), onTap: () => setState(() => _statusFilter = 'cancelada')),
              const SizedBox(width: 6),
              _FilterChip(label: 'Pendientes', isSelected: _statusFilter == 'pendiente', color: const Color(0xFFF59E0B), onTap: () => setState(() => _statusFilter = 'pendiente')),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Tarjeta de Historial de Servicio (Mobile First) ───────────────────────────
class _ReservaHistorialCard extends StatelessWidget {
  final ReservaHistorialEntity reserva;
  final String formattedFecha;
  final Color estadoColor;

  const _ReservaHistorialCard({
    required this.reserva,
    required this.formattedFecha,
    required this.estadoColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: ID Reserva + Servicio + Estado Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF262626),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#${reserva.idReserva}',
                  style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  reserva.nombreServicio,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: estadoColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: estadoColor.withAlpha(80)),
                ),
                child: Text(
                  reserva.estadoReserva.toUpperCase(),
                  style: TextStyle(color: estadoColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFF1E1E1E)),
          const SizedBox(height: 8),

          // Row 2: Cliente + Fecha
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 13, color: Color(0xFF6B7280)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            reserva.nombreCliente,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFFE5E7EB), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 17),
                      child: Text('ID Cliente: #${reserva.idCliente}', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 10)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today, size: 11, color: Color(0xFF6B7280)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        formattedFecha,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (reserva.direccion.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF6B7280)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    reserva.direccion,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                  ),
                ),
              ],
            ),
          ],

          if (reserva.nombrePrestador != null && reserva.nombrePrestador!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.handyman_outlined, size: 13, color: Color(0xFFF97316)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Prestador: ${reserva.nombrePrestador}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFFFB923C), fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ],
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
