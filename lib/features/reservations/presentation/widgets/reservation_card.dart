import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/reservation_entity.dart';

class ReservationCard extends StatelessWidget {
  final ReservationEntity reservation;
  final VoidCallback? onCancel;

  const ReservationCard({
    super.key,
    required this.reservation,
    this.onCancel,
  });

  String _getServiceIcon(int idServicio) {
    switch (idServicio) {
      case 1:
        return '💧';
      case 2:
        return '⚡';
      case 3:
        return '🔥';
      case 4:
        return '🪚';
      case 5:
        return '🎨';
      case 6:
        return '❄️';
      default:
        return '🔧';
    }
  }

  Color _getStatusColor(ReservaEstado estado) {
    switch (estado) {
      case ReservaEstado.pendiente:
        return const Color(0xFFF97316); // Naranja
      case ReservaEstado.aceptada:
        return const Color(0xFF38BDF8); // Azul
      case ReservaEstado.terminada:
        return const Color(0xFF22C55E); // Verde
      case ReservaEstado.cancelada:
      case ReservaEstado.rechazada:
        return const Color(0xFF94A3B8); // Gris
    }
  }

  String _formatDate(DateTime dt) {
    try {
      final local = dt.toLocal();
      final dateStr = DateFormat('dd/MM/yyyy').format(local);
      final timeStr = DateFormat('hh:mm a').format(local);
      return '$dateStr - $timeStr';
    } catch (_) {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(reservation.estadoReserva);
    final icon = _getServiceIcon(reservation.idServicio);
    final formattedDate = _formatDate(reservation.fechaAgenda);
    final isCancellable = reservation.estadoReserva == ReservaEstado.pendiente ||
        reservation.estadoReserva == ReservaEstado.aceptada;

    return Card(
      key: ValueKey(reservation.idReserva),
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF22201D),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Fila 1: ID y Estado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RESERVA #${reservation.idReserva}',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    reservation.estadoReserva.displayName.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Color(0xFF3E3B35), height: 1),
            const SizedBox(height: 12),

            // Fila 2: Icono + Servicio + Fecha
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E1A10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF97316)),
                  ),
                  alignment: Alignment.center,
                  child: Text(icon, style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reservation.nombreServicio,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 14, color: Color(0xFFFBBF24)),
                          const SizedBox(width: 4),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              color: Color(0xFFD4D4D8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Fila 3: Dirección
            if (reservation.direccion.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF141311),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Color(0xFFF97316)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Dirección: ${reservation.direccion}',
                        style: const TextStyle(color: Color(0xFFE4E4E7), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Fila 4: Descripción
            if (reservation.descripcion.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF141311),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.description, size: 16, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Detalle: ${reservation.descripcion}',
                        style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Fila: Evidencia de Trabajo (si está terminada y tiene foto)
            if (reservation.estadoReserva == ReservaEstado.terminada &&
                reservation.fotoEvidencia != null &&
                reservation.fotoEvidencia!.isNotEmpty) ...[
              const SizedBox(height: 6),
              InkWell(
                onTap: () => _showImageModal(context, reservation.fotoEvidencia!),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF38BDF8).withAlpha(128)),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          reservation.fotoEvidencia!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 48,
                            height: 48,
                            color: const Color(0xFF1E293B),
                            child: const Icon(Icons.broken_image, color: Colors.grey, size: 22),
                          ),
                          loadingBuilder: (context, child, progress) {

                            if (progress == null) return child;
                            return Container(
                              width: 48,
                              height: 48,
                              color: const Color(0xFF1E293B),
                              child: const Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.verified_rounded, color: Color(0xFF38BDF8), size: 15),
                                SizedBox(width: 4),
                                Text(
                                  'Evidencia de Trabajo Realizado',
                                  style: TextStyle(
                                    color: Color(0xFF38BDF8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Toca para ver la foto en pantalla completa',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.zoom_in_rounded, color: Color(0xFF38BDF8), size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],

            // Fila 5: Botón Cancelar
            if (isCancellable && onCancel != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: onCancel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  label: const Text(
                    'Cancelar Cita',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showImageModal(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black.withAlpha(235),
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 3.5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.broken_image, color: Colors.grey, size: 48),
                        SizedBox(height: 8),
                        Text('No se pudo cargar la imagen', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            IconButton(
              onPressed: () => Navigator.pop(ctx),
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                child: Icon(Icons.close_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}