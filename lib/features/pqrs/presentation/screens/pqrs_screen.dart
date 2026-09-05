import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_pagination.dart';
import '../../../reservations/domain/models/reservation_entity.dart';
import '../../../reservations/presentation/controllers/reservations_controller.dart';
import '../../domain/models/pqrs_entity.dart';
import '../controllers/pqrs_controller.dart';

class PqrsScreen extends ConsumerStatefulWidget {
  const PqrsScreen({super.key});
  @override
  ConsumerState<PqrsScreen> createState() => _PqrsScreenState();
}

class _PqrsScreenState extends ConsumerState<PqrsScreen> {
  TipoPqr _selectedTipo = TipoPqr.peticion;
  int? _selectedReservaId;
  final _descripcionCtrl = TextEditingController();
  bool _isSubmitting = false;
  bool _showForm = false;
  int _currentPage = 1;
  static const int _itemsPerPage = 6;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reservationsListProvider.notifier).load();
      ref.read(pqrsListProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSendPqrs() async {
    if (_selectedReservaId == null) { _showSnack('Selecciona una reserva primero.', isError: true); return; }
    if (_descripcionCtrl.text.trim().isEmpty) { _showSnack('Escribe una descripcion.', isError: true); return; }
    setState(() => _isSubmitting = true);
    final success = await ref.read(pqrsListProvider.notifier).sendPqrs(idReserva: _selectedReservaId!, tipoPqr: _selectedTipo, descripcion: _descripcionCtrl.text.trim());
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (success) { _showSnack('PQRS enviada correctamente.'); setState(() { _showForm = false; _descripcionCtrl.clear(); _selectedTipo = TipoPqr.peticion; _selectedReservaId = null; }); }
    else { _showSnack('Error al enviar. Intentalo de nuevo.', isError: true); }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: isError ? AppColors.error : const Color(0xFF22C55E)));
  }

  String _formatReservaOption(ReservationEntity r) {
    final date = DateFormat('dd/MM/yyyy').format(r.fechaAgenda.toLocal());
    return 'Reserva #${r.idReserva} - ${r.nombreServicio} - $date';
  }

  Color _estadoColor(String estado) {
    if (estado == 'En Proceso') return const Color(0xFFFBBF24);
    if (estado == 'Cerrado') return const Color(0xFF64748B);
    return const Color(0xFFF97316);
  }

  Widget _buildTipoGrid() {
    return GridView.count(
      crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 3.2,
      children: TipoPqr.values.map((tipo) {
        final isSelected = _selectedTipo == tipo;
        return GestureDetector(
          onTap: () => setState(() => _selectedTipo = tipo),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(color: isSelected ? AppColors.primary : const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(10), border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFF3A3A3A), width: 1.5)),
            alignment: Alignment.center,
            child: Text('${tipo.icon}  ${tipo.displayName}', style: TextStyle(color: isSelected ? Colors.white : const Color(0xFFA1A1AA), fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDropdown(List<ReservationEntity> reservas) {
    final hasValid = reservas.any((r) => r.idReserva == _selectedReservaId);
    final currentVal = hasValid
        ? _selectedReservaId
        : (reservas.isNotEmpty ? reservas.first.idReserva : null);
    if (currentVal != _selectedReservaId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedReservaId = currentVal);
      });
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF97316), width: 1.5)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: currentVal, isExpanded: true, dropdownColor: const Color(0xFF1E1E1E),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFF97316)),
          items: reservas.map((r) => DropdownMenuItem<int>(value: r.idReserva, child: Text(_formatReservaOption(r), style: const TextStyle(color: Colors.white, fontSize: 13), overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (val) { if (val != null) setState(() => _selectedReservaId = val); },
        ),
      ),
    );
  }

  String _sortBy = 'recientes';

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1609),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E1E0A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  List<PqrsEntity> _getSortedList(List<PqrsEntity> list) {
    final sorted = List<PqrsEntity>.from(list);
    if (_sortBy == 'recientes') {
      sorted.sort((a, b) => b.idPqr.compareTo(a.idPqr));
    } else if (_sortBy == 'antiguos') {
      sorted.sort((a, b) => a.idPqr.compareTo(b.idPqr));
    } else if (_sortBy == 'az') {
      sorted.sort((a, b) => a.tipoPqr.compareTo(b.tipoPqr));
    } else if (_sortBy == 'za') {
      sorted.sort((a, b) => b.tipoPqr.compareTo(a.tipoPqr));
    }
    return sorted;
  }

  Color _getTipoColor(String tipo) {
    final t = tipo.toLowerCase().trim();
    if (t == 'peticion' || t == 'petición') return const Color(0xFF60A5FA);
    if (t == 'queja') return const Color(0xFFF97316);
    if (t == 'reclamo') return const Color(0xFFEF4444);
    return const Color(0xFFFBBF24); // Sugerencia
  }

  @override
  Widget build(BuildContext context) {
    final pqrsState = ref.watch(pqrsListProvider);
    final reservasState = ref.watch(reservationsListProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PANEL DE GESTION', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                          SizedBox(height: 2),
                          Text('PQRS', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (!_showForm)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F1609),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF2E1E0A)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _sortBy,
                                  dropdownColor: const Color(0xFF1F1609),
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                  icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.primary),
                                  items: const [
                                    DropdownMenuItem(value: 'recientes', child: Text('Más recientes')),
                                    DropdownMenuItem(value: 'antiguos', child: Text('Más antiguos')),
                                    DropdownMenuItem(value: 'az', child: Text('A - Z')),
                                    DropdownMenuItem(value: 'za', child: Text('Z - A')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _sortBy = val;
                                        _currentPage = 1;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ElevatedButton.icon(
                            onPressed: () => setState(() => _showForm = !_showForm),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _showForm ? const Color(0xFF2E2E2E) : AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            icon: Icon(_showForm ? Icons.list_rounded : Icons.add, size: 18),
                            label: Text(_showForm ? 'Ver Mis PQRS' : '+ Nueva PQRS', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (!_showForm) ...[
                    pqrsState.maybeWhen(
                      data: (list) {
                        final total = list.length;
                        final abiertos = list.where((p) => p.estadoPqr.toLowerCase() == 'abierto' || p.estadoPqr.isEmpty).length;
                        final enProceso = list.where((p) => p.estadoPqr.toLowerCase() == 'en proceso').length;
                        final cerrados = list.where((p) => p.estadoPqr.toLowerCase() == 'cerrado' || p.estadoPqr.toLowerCase() == 'cerrada').length;

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final isSmall = constraints.maxWidth < 600;
                            return GridView.count(
                              crossAxisCount: isSmall ? 2 : 4,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: isSmall ? 2.2 : 2.0,
                              children: [
                                _buildStatCard('TOTAL', '$total', Colors.white),
                                _buildStatCard('ABIERTOS', '$abiertos', const Color(0xFFF97316)),
                                _buildStatCard('EN PROCESO', '$enProceso', const Color(0xFFFBBF24)),
                                _buildStatCard('CERRADOS', '$cerrados', const Color(0xFF94A3B8)),
                              ],
                            );
                          },
                        );
                      },
                      orElse: () => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (_showForm) ...[
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(color: const Color(0xFF161717), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF2A2A2A))),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        const Text('TIPO DE SOLICITUD', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                        const SizedBox(height: 10),
                        _buildTipoGrid(),
                        const SizedBox(height: 20),
                        const Text('RESERVA ASOCIADA', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                        const SizedBox(height: 8),
                        reservasState.when(
                          loading: () => const Text('Cargando...', style: TextStyle(color: Color(0xFF64748B))),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (reservas) => reservas.isEmpty ? const Text('Sin reservas disponibles', style: TextStyle(color: Color(0xFF94A3B8))) : _buildDropdown(reservas),
                        ),
                        const SizedBox(height: 20),
                        const Text('DESCRIPCION', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _descripcionCtrl, maxLines: 5,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Describe tu peticion, queja o sugerencia...',
                            hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                            filled: true, fillColor: const Color(0xFF1A1A1A), contentPadding: const EdgeInsets.all(14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3A3A3A))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3A3A3A))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF97316), width: 1.5)),
                          ),
                        ),
                        const SizedBox(height: 22),
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _handleSendPqrs,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF97316), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: _isSubmitting ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : const Text('ENVIAR PQRS ->', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.5)),
                        ),
                        TextButton(onPressed: () => setState(() => _showForm = false), child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B)))),
                      ]),
                    ),
                  ] else ...[
                    pqrsState.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                      ),
                      error: (_, _) => const Center(
                        child: Text('Error al cargar las PQRS.', style: TextStyle(color: AppColors.error)),
                      ),
                      data: (pqrsList) {
                        if (pqrsList.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: const Color(0xFF161717),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF2A2A2A)),
                            ),
                            child: Column(
                              children: [
                                const Text('📋', style: TextStyle(fontSize: 48)),
                                const SizedBox(height: 14),
                                const Text(
                                  'No tienes PQRS registradas',
                                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Si deseas radicar una solicitud, queja o sugerencia sobre tus servicios, puedes crear una fácilmente.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: () => setState(() => _showForm = true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Crear primera PQRS', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                        }

                        final sortedList = _getSortedList(pqrsList);
                        final totalPages = ((sortedList.length - 1) / _itemsPerPage).floor() + 1;
                        if (_currentPage > totalPages) {
                          _currentPage = totalPages;
                        }

                        final paginatedList = sortedList
                            .skip((_currentPage - 1) * _itemsPerPage)
                            .take(_itemsPerPage)
                            .toList();

                        return Column(
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isSingleColumn = constraints.maxWidth < 650;

                                if (isSingleColumn) {
                                  return Column(
                                    children: paginatedList.map((p) => _buildPqrsCard(p)).toList(),
                                  );
                                }

                                final crossAxisCount = constraints.maxWidth < 950 ? 2 : 3;
                                final itemWidth = (constraints.maxWidth - (crossAxisCount - 1) * 14) / crossAxisCount;

                                return Wrap(
                                  spacing: 14,
                                  runSpacing: 14,
                                  children: paginatedList.map((p) {
                                    return SizedBox(
                                      width: itemWidth,
                                      child: _buildPqrsCard(p),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                            AppPagination(
                              currentPage: _currentPage,
                              totalPages: totalPages,
                              onPageChange: (page) {
                                setState(() => _currentPage = page);
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPqrsCard(PqrsEntity p) {
    final estadoColor = _estadoColor(p.estadoPqr);
    final tipoColor = _getTipoColor(p.tipoPqr);
    final tipo = TipoPqr.fromString(p.tipoPqr);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1609),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E1E0A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PQRS #${p.idPqr}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E1E0A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: estadoColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: estadoColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      p.estadoPqr.toUpperCase(),
                      style: TextStyle(
                        color: estadoColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'TIPO',
                style: TextStyle(
                  color: Color(0xFF71717A),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              Text(
                '${tipo.icon} ${p.tipoPqr}',
                style: TextStyle(
                  color: tipoColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'DESC.',
                style: TextStyle(
                  color: Color(0xFF71717A),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  p.descripcion,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Color(0xFFD4D4D8),
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'RESERVA',
                style: TextStyle(
                  color: Color(0xFF71717A),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              Text(
                '#${p.idReserva}',
                style: const TextStyle(
                  color: Color(0xFFE4E4E7),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),

          if (p.respuestaAdmin != null && p.respuestaAdmin!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0D2818),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF15803D)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.check_box_outlined, size: 13, color: Color(0xFF22C55E)),
                      SizedBox(width: 5),
                      Text(
                        'RESPUESTA DE SOPORTE',
                        style: TextStyle(
                          color: Color(0xFF22C55E),
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.respuestaAdmin!,
                    style: const TextStyle(
                      color: Color(0xFFDCFCE7),
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}