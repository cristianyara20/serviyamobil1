import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/models/admin_pqr_entity.dart';
import '../controllers/admin_pqrs_controller.dart';

class AdminPqrsTab extends ConsumerStatefulWidget {
  const AdminPqrsTab({super.key});

  @override
  ConsumerState<AdminPqrsTab> createState() => _AdminPqrsTabState();
}

class _AdminPqrsTabState extends ConsumerState<AdminPqrsTab> {
  String _search = '';
  String _statusFilter = 'todos'; // todos, abiertas, cerradas, peticion, queja, reclamo, sugerencia
  String _sortOrder = 'recientes'; // recientes, antiguos

  String _formatFecha(String raw) {
    if (raw.isEmpty) return 'Fecha no registrada';
    try {
      final dt = DateTime.parse(raw).toLocal();
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

  void _showResponderDialog(BuildContext context, AdminPqrEntity pqr) {
    final responseController = TextEditingController(text: pqr.respuestaAdmin ?? '');
    bool isSending = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
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
                  child: const Icon(Icons.mark_chat_unread_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Responder PQR #${pqr.idPqr}',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Cliente: ${pqr.nombreCliente}',
                        style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Detalle de la PQR
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF2A2A2A)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: pqr.tipoColor.withAlpha(30),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: pqr.tipoColor.withAlpha(100)),
                                ),
                                child: Text(
                                  pqr.tipoPqr.toUpperCase(),
                                  style: TextStyle(color: pqr.tipoColor, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (pqr.idReserva != null)
                                Text(
                                  'Reserva #${pqr.idReserva}',
                                  style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'DESCRIPCION DEL CLIENTE:',
                            style: TextStyle(color: Color(0xFF6B7280), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            pqr.descripcion.isNotEmpty ? pqr.descripcion : 'Sin descripcion detallada',
                            style: const TextStyle(color: Color(0xFFE5E7EB), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Plantillas rapidas
                    const Text(
                      'Plantillas de respuesta rapida:',
                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _QuickTemplateChip(
                            label: 'Solicitud Resuelta',
                            onTap: () {
                              setModalState(() {
                                responseController.text =
                                    'Estimado/a ${pqr.nombreCliente}, hemos revisado y gestionado su solicitud con el equipo correspondiente. Su caso ha sido resuelto satisfactoriamente.';
                              });
                            },
                          ),
                          const SizedBox(width: 6),
                          _QuickTemplateChip(
                            label: 'Gracias por tu opinion',
                            onTap: () {
                              setModalState(() {
                                responseController.text =
                                    'Estimado/a ${pqr.nombreCliente}, agradecemos sus comentarios y sugerencias para seguir mejorando la calidad de ServiYa. Hemos tomado nota de sus observaciones.';
                              });
                            },
                          ),
                          const SizedBox(width: 6),
                          _QuickTemplateChip(
                            label: 'En revision tecnica',
                            onTap: () {
                              setModalState(() {
                                responseController.text =
                                    'Estimado/a ${pqr.nombreCliente}, su reporte esta en proceso de verificacion por nuestro equipo operativo y tomaremos las medidas correctivas.';
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Campo de texto para la respuesta
                    const Text(
                      'Tu respuesta oficial (sera visible para el cliente):',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: responseController,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Escribe aqui la respuesta que se enviara al cliente...',
                        hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFF0A0A0A),
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF333333)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF333333)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSending ? null : () => Navigator.pop(ctx),
                child: const Text('Cancelar', style: TextStyle(color: Color(0xFF9CA3AF))),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: isSending
                    ? null
                    : () async {
                        final text = responseController.text.trim();
                        if (text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Por favor ingresa una respuesta para el cliente.'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }

                        setModalState(() => isSending = true);
                        final ok = await ref.read(adminPqrsProvider.notifier).responderPqr(
                              idPqr: pqr.idPqr,
                              respuestaAdmin: text,
                            );

                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok
                                  ? 'PQRS #${pqr.idPqr} respondida con exito y enviada al cliente'
                                  : 'Error al enviar respuesta a la API de Go'),
                              backgroundColor: ok ? const Color(0xFF14532D) : AppColors.error,
                            ),
                          );
                        }
                      },
                icon: isSending
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, size: 16),
                label: Text(
                  isSending ? 'Enviando a API...' : 'Enviar Respuesta',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pqrsState = ref.watch(adminPqrsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: pqrsState.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 14),
              Text('Consultando buzon de PQRs en API de Go...', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
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
                Text('Error al consultar PQRs: $err', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 13)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () => ref.read(adminPqrsProvider.notifier).load(),
                  icon: const Icon(Icons.refresh, color: Colors.white, size: 16),
                  label: const Text('Reintentar', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
        data: (allPqrs) {
          // Filtrado
          var filtered = allPqrs.where((p) {
            final f = _statusFilter.toLowerCase();
            bool matchesFilter = true;
            if (f == 'abiertas') {
              matchesFilter = p.isAbierto;
            } else if (f == 'cerradas') {
              matchesFilter = p.isCerrado;
            } else if (f != 'todos') {
              matchesFilter = p.tipoPqr.toLowerCase() == f;
            }

            final q = _search.toLowerCase().trim();
            final matchesSearch = q.isEmpty ||
                p.nombreCliente.toLowerCase().contains(q) ||
                p.descripcion.toLowerCase().contains(q) ||
                p.tipoPqr.toLowerCase().contains(q) ||
                '#${p.idPqr}'.contains(q) ||
                (p.idReserva != null && '#${p.idReserva}'.contains(q));

            return matchesFilter && matchesSearch;
          }).toList();

          // Ordenamiento
          if (_sortOrder == 'recientes') {
            filtered.sort((a, b) => b.idPqr.compareTo(a.idPqr));
          } else {
            filtered.sort((a, b) => a.idPqr.compareTo(b.idPqr));
          }

          final totalAbiertas = allPqrs.where((p) => p.isAbierto).length;

          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: const Color(0xFF1E1E1E),
            onRefresh: () => ref.read(adminPqrsProvider.notifier).load(),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              children: [
                // Encabezado
                _buildHeader(context, allPqrs.length, totalAbiertas),
                const SizedBox(height: 14),

                // Controles de busqueda y filtros
                _buildControls(totalAbiertas),
                const SizedBox(height: 14),

                // Lista de PQRs
                if (filtered.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        const Icon(Icons.inbox_outlined, size: 48, color: Color(0xFF374151)),
                        const SizedBox(height: 10),
                        Text(
                          _search.isNotEmpty || _statusFilter != 'todos'
                              ? 'No se encontraron PQRs con esos filtros.'
                              : 'No hay PQRs registradas en el sistema.',
                          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                        ),
                      ],
                    ),
                  )
                else
                  for (final p in filtered) ...[
                    _PqrCard(
                      pqr: p,
                      formattedFecha: _formatFecha(p.fechaPqr),
                      formattedFechaRespuesta: p.fechaRespuesta != null ? _formatFecha(p.fechaRespuesta!) : null,
                      onResponder: () => _showResponderDialog(context, p),
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

  Widget _buildHeader(BuildContext context, int total, int totalAbiertas) {
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
              const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Buzon de PQRs',
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(35),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$total total ($totalAbiertas pendientes)',
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
                onPressed: () => ref.read(adminPqrsProvider.notifier).load(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Gestion de Peticiones, Quejas y Reclamos — consultado mediante la API de Go',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(int totalAbiertas) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Orden y Busqueda
        Row(
          children: [
            // Dropdown de orden
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
                    DropdownMenuItem(value: 'recientes', child: Text('Recientes primero')),
                    DropdownMenuItem(value: 'antiguos', child: Text('Antiguos primero')),
                  ],
                  onChanged: (v) => setState(() => _sortOrder = v ?? 'recientes'),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Barra de busqueda
            Expanded(
              child: TextField(
                style: const TextStyle(color: Colors.white, fontSize: 12),
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Buscar por cliente, texto o #ID...',
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

        // Chips de Filtrado por Estado y Tipo
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(label: 'Todas', isSelected: _statusFilter == 'todos', onTap: () => setState(() => _statusFilter = 'todos')),
              const SizedBox(width: 6),
              _FilterChip(
                label: 'Abiertas ($totalAbiertas)',
                isSelected: _statusFilter == 'abiertas',
                color: const Color(0xFFF97316),
                onTap: () => setState(() => _statusFilter = 'abiertas'),
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: 'Cerradas / Respondidas',
                isSelected: _statusFilter == 'cerradas',
                color: const Color(0xFF10B981),
                onTap: () => setState(() => _statusFilter = 'cerradas'),
              ),
              const SizedBox(width: 6),
              _FilterChip(label: 'Peticion', isSelected: _statusFilter == 'peticion', color: const Color(0xFF38BDF8), onTap: () => setState(() => _statusFilter = 'peticion')),
              const SizedBox(width: 6),
              _FilterChip(label: 'Queja', isSelected: _statusFilter == 'queja', color: const Color(0xFFFB923C), onTap: () => setState(() => _statusFilter = 'queja')),
              const SizedBox(width: 6),
              _FilterChip(label: 'Reclamo', isSelected: _statusFilter == 'reclamo', color: const Color(0xFFF87171), onTap: () => setState(() => _statusFilter = 'reclamo')),
              const SizedBox(width: 6),
              _FilterChip(label: 'Sugerencia', isSelected: _statusFilter == 'sugerencia', color: const Color(0xFFA78BFA), onTap: () => setState(() => _statusFilter = 'sugerencia')),
            ],
          ),
        ),
      ],
    );
  }
}

// Tarjeta de PQR
class _PqrCard extends StatelessWidget {
  final AdminPqrEntity pqr;
  final String formattedFecha;
  final String? formattedFechaRespuesta;
  final VoidCallback onResponder;

  const _PqrCard({
    required this.pqr,
    required this.formattedFecha,
    this.formattedFechaRespuesta,
    required this.onResponder,
  });

  @override
  Widget build(BuildContext context) {
    final isResponded = pqr.isCerrado;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isResponded ? const Color(0xFF262626) : const Color(0xFFF97316).withAlpha(120),
          width: isResponded ? 1 : 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila 1: Avatar + Nombre + Badges
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF2B1408),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEA580C).withAlpha(140)),
                ),
                child: Text(
                  pqr.inicial,
                  style: const TextStyle(
                    color: Color(0xFFFB923C),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Nombre y Subtitulo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pqr.nombreCliente,
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
                      'PQR #${pqr.idPqr} • ${pqr.idReserva != null ? "Reserva #${pqr.idReserva}" : "General"}',
                      style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Badges de Tipo y Estado
              Wrap(
                spacing: 6,
                runSpacing: 4,
                alignment: WrapAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: pqr.tipoColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: pqr.tipoColor.withAlpha(90)),
                    ),
                    child: Text(
                      pqr.tipoPqr,
                      style: TextStyle(color: pqr.tipoColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: pqr.estadoColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: pqr.estadoColor.withAlpha(90)),
                    ),
                    child: Text(
                      pqr.estadoPqr.toUpperCase(),
                      style: TextStyle(color: pqr.estadoColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFF1E1E1E)),
          const SizedBox(height: 8),

          // Descripcion del cliente
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DESCRIPCION: ',
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: Text(
                  pqr.descripcion.isNotEmpty ? pqr.descripcion : 'Sin descripcion',
                  style: const TextStyle(color: Color(0xFFE5E7EB), fontSize: 12),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Fecha de creacion de la PQR
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 12, color: Color(0xFF6B7280)),
              const SizedBox(width: 4),
              Text(
                formattedFecha,
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
              ),
            ],
          ),

          // Respuesta del Administrador (si ya fue respondida)
          if (pqr.respuestaAdmin != null && pqr.respuestaAdmin!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F291E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF166534)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF4ADE80)),
                      const SizedBox(width: 6),
                      const Text(
                        'Respuesta del Administrador:',
                        style: TextStyle(color: Color(0xFF4ADE80), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      if (formattedFechaRespuesta != null) ...[
                        const Spacer(),
                        Text(
                          formattedFechaRespuesta!,
                          style: const TextStyle(color: Color(0xFF86EFAC), fontSize: 10),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pqr.respuestaAdmin!,
                    style: const TextStyle(color: Color(0xFFDCFCE7), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Boton de Responder
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isResponded ? const Color(0xFF1E293B) : AppColors.primary,
                foregroundColor: isResponded ? const Color(0xFF93C5FD) : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isResponded ? const Color(0xFF334155) : AppColors.primary,
                  ),
                ),
              ),
              onPressed: onResponder,
              icon: Icon(isResponded ? Icons.edit_note_rounded : Icons.reply_rounded, size: 16),
              label: Text(
                isResponded ? 'Modificar Respuesta' : 'Responder',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Quick Template Chip
class _QuickTemplateChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickTemplateChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF262626),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF3B3B3B)),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 11),
        ),
      ),
    );
  }
}

// Filter Chip
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
