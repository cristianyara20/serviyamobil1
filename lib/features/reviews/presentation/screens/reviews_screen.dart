import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../reservations/domain/models/reservation_entity.dart';
import '../../../reservations/presentation/controllers/reservations_controller.dart';
import '../controllers/calificaciones_controller.dart';

class ReviewsScreen extends ConsumerStatefulWidget {
  const ReviewsScreen({super.key});

  @override
  ConsumerState<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends ConsumerState<ReviewsScreen> {
  int? _selectedReservaId;
  int _rating = 5;
  final _comentarioCtrl = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _ratingLabels = [
    '',
    'Muy malo (1/5)',
    'Malo (2/5)',
    'Regular (3/5)',
    'Bueno (4/5)',
    'Excelente (5/5)',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reservationsListProvider.notifier).load();
      ref.read(calificacionesListProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _comentarioCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSendReview() async {
    if (_selectedReservaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una cita primero.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Elige una calificación de 1 a 5 estrellas.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await ref
        .read(calificacionesListProvider.notifier)
        .sendCalificacion(
          idReserva: _selectedReservaId!,
          puntuacion: _rating,
          comentario: _comentarioCtrl.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⭐ ¡Calificación enviada con éxito!'),
          backgroundColor: Color(0xFF22C55E),
        ),
      );
      setState(() {
        _comentarioCtrl.clear();
        _rating = 5;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al enviar la calificación. Inténtalo de nuevo.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _formatReservationOption(ReservationEntity r) {
    final dateStr = DateFormat('dd/MM/yyyy').format(r.fechaAgenda.toLocal());
    return 'Reserva #${r.idReserva} - ${r.nombreServicio} - $dateStr';
  }

  @override
  Widget build(BuildContext context) {
    final reservationsState = ref.watch(reservationsListProvider);
    final reviewsState = ref.watch(calificacionesListProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Formulario: ⭐ Califica tu servicio (Diseño exacto al de la web)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161922),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF2E384D),
                        width: 1.2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Título
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              '⭐ Califica tu servicio',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),

                        // 1. Selector de Cita
                        const Text(
                          'Seleccionar Cita',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        reservationsState.when(
                          loading: () => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E2230),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF334155)),
                            ),
                            child: const Text(
                              'Cargando tus citas...',
                              style: TextStyle(
                                  color: Color(0xFF64748B), fontSize: 13),
                            ),
                          ),
                          error: (_, __) => Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E2230),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Error al cargar citas.',
                              style: TextStyle(
                                  color: Color(0xFFEF4444), fontSize: 13),
                            ),
                          ),
                          data: (reservas) {
                            if (reservas.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E2230),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFF334155)),
                                ),
                                child: const Text(
                                  'No tienes citas registradas para calificar',
                                  style: TextStyle(
                                      color: Color(0xFF94A3B8), fontSize: 13),
                                ),
                              );
                            }

                            final hasValidSelection =
                                reservas.any((r) => r.idReserva == _selectedReservaId);
                            final currentVal = hasValidSelection
                                ? _selectedReservaId
                                : (reservas.isNotEmpty
                                    ? reservas.first.idReserva
                                    : null);
                            if (currentVal != _selectedReservaId) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) setState(() => _selectedReservaId = currentVal);
                              });
                            }

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E2230),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFF97316),
                                  width: 1.5,
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: currentVal,
                                  isExpanded: true,
                                  dropdownColor: const Color(0xFF1E2230),
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Color(0xFFF97316),
                                  ),
                                  items: reservas.map((r) {
                                    return DropdownMenuItem<int>(
                                      value: r.idReserva,
                                      child: Text(
                                        _formatReservationOption(r),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedReservaId = val);
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        // 2. Estrellas Interactivas
                        const Text(
                          'Calificación',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final starNumber = index + 1;
                            final isFilled = starNumber <= _rating;
                            return InkWell(
                              onTap: () => setState(() => _rating = starNumber),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                child: Icon(
                                  isFilled
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  color: isFilled
                                      ? const Color(0xFFF97316)
                                      : const Color(0xFF475569),
                                  size: 38,
                                ),
                              ),
                            );
                          }),
                        ),
                        if (_rating > 0) ...[
                          const SizedBox(height: 6),
                          Text(
                            _ratingLabels[_rating],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFF97316),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),

                        // 3. Campo Reseña / Comentario
                        const Text(
                          'Reseña',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _comentarioCtrl,
                          maxLines: 4,
                          style: const TextStyle(color: Colors.white, fontSize: 13.5),
                          decoration: InputDecoration(
                            hintText: 'Cuéntanos cómo fue tu experiencia...',
                            hintStyle: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                            ),
                            filled: true,
                            fillColor: const Color(0xFF1E2230),
                            contentPadding: const EdgeInsets.all(14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFF334155)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFF334155)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFFF97316), width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 4. Botón Enviar Calificación
                        ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _handleSendReview,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF97316),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('⭐', style: TextStyle(fontSize: 16)),
                          label: Text(
                            _isSubmitting
                                ? 'Enviando...'
                                : 'Enviar Calificación',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Historial de Calificaciones del Cliente
                  const Text(
                    'Mis Calificaciones Recientes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  reviewsState.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                            color: Color(0xFFF97316)),
                      ),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (califs) {
                      if (califs.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1D1A),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF383530)),
                          ),
                          child: const Text(
                            'No has calificado ninguna de tus citas todavía.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Color(0xFFA1A1AA), fontSize: 13),
                          ),
                        );
                      }

                      return Column(
                        children: califs.take(6).map((c) {
                          final dateFormatted =
                              DateFormat('dd/MM/yyyy').format(c.fechaCalificacion.toLocal());

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1D1A),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFF383530)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Reserva #${c.idReserva}',
                                      style: const TextStyle(
                                        color: Color(0xFFF97316),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      dateFormatted,
                                      style: const TextStyle(
                                        color: Color(0xFF71717A),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: List.generate(
                                    5,
                                    (i) => Icon(
                                      i < c.puntuacion
                                          ? Icons.star_rounded
                                          : Icons.star_outline_rounded,
                                      color: const Color(0xFFF97316),
                                      size: 16,
                                    ),
                                  ),
                                ),
                                if (c.comentario.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    c.comentario,
                                    style: const TextStyle(
                                      color: Color(0xFFE4E4E7),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}