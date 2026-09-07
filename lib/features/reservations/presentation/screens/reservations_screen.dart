import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_pagination.dart';
import '../../domain/models/reservation_entity.dart';
import '../controllers/reservations_controller.dart';
import '../widgets/reservation_card.dart';
import 'create_reservation_screen.dart';

class ReservationsScreen extends ConsumerStatefulWidget {
  const ReservationsScreen({super.key});

  @override
  ConsumerState<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends ConsumerState<ReservationsScreen> {
  String _sortBy = 'recientes';
  int _currentPage = 1;
  static const int _itemsPerPage = 6;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reservationsListProvider.notifier).load();
    });
  }

  void _openCreateScreen([int? serviceId]) async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateReservationScreen(initialServiceId: serviceId),
      ),
    );
    if (created == true) {
      ref.read(reservationsListProvider.notifier).load();
    }
  }

  void _showCancelDialog(int idReserva) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F1E1B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '¿Cancelar Cita?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Esta acción marcará tu reserva como cancelada en la base de datos.',
          style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Volver', style: TextStyle(color: Color(0xFF71717A))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref
                  .read(reservationsListProvider.notifier)
                  .cancel(idReserva);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? '✅ Cita #$idReserva cancelada con éxito.'
                          : 'No se pudo cancelar la cita.',
                    ),
                    backgroundColor: success ? const Color(0xFF18181B) : AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Confirmar Cancelación'),
          ),
        ],
      ),
    );
  }

  List<ReservationEntity> _getSortedList(List<ReservationEntity> list) {
    final sorted = List<ReservationEntity>.from(list);
    if (_sortBy == 'recientes') {
      sorted.sort((a, b) => b.fechaAgenda.compareTo(a.fechaAgenda));
    } else {
      sorted.sort((a, b) => a.fechaAgenda.compareTo(b.fechaAgenda));
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final reservationsState = ref.watch(reservationsListProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await ref.read(reservationsListProvider.notifier).load();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabecera responsiva
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 600;
                        final titleWidget = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'MIS CITAS',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Historial de Reservas',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );

                        final actionsWidget = Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // Selector de orden
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
                              onPressed: () => _openCreateScreen(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text(
                                'Nueva',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        );

                        if (isMobile) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              titleWidget,
                              const SizedBox(height: 12),
                              actionsWidget,
                            ],
                          );
                        }

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            titleWidget,
                            actionsWidget,
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Contenido
                    reservationsState.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      ),
                      error: (err, _) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 48, color: AppColors.error),
                              const SizedBox(height: 12),
                              const Text(
                                'Error al cargar las reservas',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () =>
                                    ref.read(reservationsListProvider.notifier).load(),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary),
                                child: const Text('Reintentar',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      data: (reservas) {
                        if (reservas.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2E1A10),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.primary),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text('🗓️',
                                        style: TextStyle(fontSize: 36)),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No tienes citas registradas',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Agenda tu primer servicio para tu hogar de forma rápida y segura.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFFA1A1AA),
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton.icon(
                                    onPressed: () => _openCreateScreen(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: const Icon(Icons.add_circle_outline),
                                    label: const Text(
                                      'Agendar mi primer servicio',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final sorted = _getSortedList(reservas);
                        final totalPages = ((sorted.length - 1) / _itemsPerPage).floor() + 1;
                        if (_currentPage > totalPages) {
                          _currentPage = totalPages;
                        }

                        final paginated = sorted
                            .skip((_currentPage - 1) * _itemsPerPage)
                            .take(_itemsPerPage)
                            .toList();

                        return Column(
                          children: [
                            ...paginated.map((r) {
                              return ReservationCard(
                                reservation: r,
                                onCancel: () => _showCancelDialog(r.idReserva),
                              );
                            }),
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
