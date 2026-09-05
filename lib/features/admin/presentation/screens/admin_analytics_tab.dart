import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/admin_analytics_controller.dart';
import '../../domain/models/admin_analytics_entity.dart';

class AdminAnalyticsTab extends ConsumerWidget {
  const AdminAnalyticsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminAnalyticsControllerProvider);
    final controller = ref.read(adminAnalyticsControllerProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: const Color(0xFF1F1F1F),
        onRefresh: () => controller.load(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, state, controller),
              const SizedBox(height: 16),
              state.data.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 16),
                        Text(
                          'Calculando métricas con el motor de Go...',
                          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
                error: (err, _) => Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7F1D1D).withAlpha(40),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF7F1D1D)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Error cargando métricas: ',
                          style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: () => controller.load(),
                      )
                    ],
                  ),
                ),
                data: (fullData) => _buildDashboardContent(context, fullData),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AdminAnalyticsState state, AdminAnalyticsController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF262626)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('📊', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analíticas y Rendimiento',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Métricas en tiempo real procesadas por el motor de Go',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF333333)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: state.mes,
                      dropdownColor: const Color(0xFF1C1C1E),
                      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9CA3AF), size: 18),
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      isExpanded: true,
                      items: List.generate(12, (i) => i + 1).map((m) {
                        return DropdownMenuItem<int>(
                          value: m,
                          child: Text('Mes $m'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) controller.setMes(val);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF333333)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: state.anio,
                      dropdownColor: const Color(0xFF1C1C1E),
                      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9CA3AF), size: 18),
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      isExpanded: true,
                      items: [2024, 2025, 2026, 2027, 2028].map((y) {
                        return DropdownMenuItem<int>(
                          value: y,
                          child: Text('$y'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) controller.setAnio(val);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Botón PDF
              InkWell(
                onTap: () async {
                  try {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                            SizedBox(width: 12),
                            Text('Descargando reporte PDF desde el servidor Go...'),
                          ],
                        ),
                        backgroundColor: Color(0xFF1F1F1F),
                        duration: Duration(seconds: 2),
                      ),
                    );

                    final path = await controller.downloadPDF();

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✅ Reporte PDF descargado y abierto correctamente: ${path.split('/').last.split('\\').last}'),
                          backgroundColor: const Color(0xFF14532D),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al descargar PDF: $e'),
                          backgroundColor: const Color(0xFF7F1D1D),
                        ),
                      );
                    }
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF262626),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF333333)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text('PDF', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Botón Refrescar
              InkWell(
                onTap: () => controller.load(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
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

  Widget _buildDashboardContent(BuildContext context, AdminAnalyticsFullData data) {
    final c = data.consolidado;
    final act = data.actividad;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMainKpiCard(c),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _buildSecondaryKpiCard('⏳ PENDIENTES', '${c.totalPendientes}', const Color(0xFFEAB308))),
            const SizedBox(width: 10),
            Expanded(child: _buildSecondaryKpiCard('✅ TERMINADAS', '${c.totalCompletadas}', const Color(0xFF22C55E))),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildSecondaryKpiCard('❌ RECHAZADAS', '${c.totalCanceladas}', const Color(0xFFEF4444))),
            const SizedBox(width: 10),
            Expanded(child: _buildSecondaryKpiCard('📩 PQRS ABIERTAS', '${c.pqrsAbiertas}', AppColors.primary)),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _buildActivityCard('👤 NUEVOS USUARIOS', '${act.usuariosNuevos}', const Color(0xFF06B6D4))),
            const SizedBox(width: 10),
            Expanded(child: _buildActivityCard('🔥 USUARIOS ACTIVOS', '${act.usuariosActivos}', const Color(0xFFA855F7))),
          ],
        ),
        const SizedBox(height: 16),
        _buildTopPrestadoresCard(c.topPrestadores),
        const SizedBox(height: 16),
        _buildDemandServicesCard(data.servicios),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildMainKpiCard(AdminReporteConsolidadoEntity c) {
    final total = c.totalReservas;
    final pPend = total > 0 ? (c.totalPendientes / total) : 0.0;
    final pAcep = total > 0 ? (c.totalAceptadas / total) : 0.0;
    final pTerm = total > 0 ? (c.totalCompletadas / total) : 0.0;
    final pRech = total > 0 ? (c.totalCanceladas / total) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withAlpha(35),
            const Color(0xFFA855F7).withAlpha(20),
            const Color(0xFF3B82F6).withAlpha(20),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📋 TOTAL RESERVAS DEL MES',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${c.totalReservas}',
                    style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildLegendItem('🟡 Pendientes: ', '${c.totalPendientes}', const Color(0xFFEAB308)),
                  const SizedBox(height: 2),
                  _buildLegendItem('🔵 Aceptadas: ', '${c.totalAceptadas}', const Color(0xFF3B82F6)),
                  const SizedBox(height: 2),
                  _buildLegendItem('🟢 Terminadas: ', '${c.totalCompletadas}', const Color(0xFF22C55E)),
                  const SizedBox(height: 2),
                  _buildLegendItem('🔴 Rechazadas: ', '${c.totalCanceladas}', const Color(0xFFEF4444)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 10,
              width: double.infinity,
              color: const Color(0xFF262626),
              child: total == 0
                  ? Container(color: const Color(0xFF333333))
                  : Row(
                      children: [
                        if (pPend > 0) Expanded(flex: (pPend * 100).toInt(), child: Container(color: const Color(0xFFEAB308))),
                        if (pAcep > 0) Expanded(flex: (pAcep * 100).toInt(), child: Container(color: const Color(0xFF3B82F6))),
                        if (pTerm > 0) Expanded(flex: (pTerm * 100).toInt(), child: Container(color: const Color(0xFF22C55E))),
                        if (pRech > 0) Expanded(flex: (pRech * 100).toInt(), child: Container(color: const Color(0xFFEF4444))),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold)),
        Text(value, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSecondaryKpiCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF262626)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF262626)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPrestadoresCard(List<PrestadorTopAnalyticsEntity> prestadores) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF262626)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('🏆', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 10),
              const Text(
                'Top 3 Prestadores',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (prestadores.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('No hay datos suficientes este mes.', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
              ),
            )
          else
            ...prestadores.asMap().entries.map((entry) {
              final idx = entry.key;
              final p = entry.value;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0D0D),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF262626)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFFA855F7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '#${idx + 1}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.nombrePrestador,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            p.correoPrestador,
                            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFEAB308), size: 16),
                            const SizedBox(width: 2),
                            Text(
                              p.calificacion.toStringAsFixed(1),
                              style: const TextStyle(color: Color(0xFFEAB308), fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Text(
                          '${p.totalServicios} SVCS',
                          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildDemandServicesCard(List<ServicioPopularEntity> servicios) {
    final maxVeces = servicios.isEmpty
        ? 1
        : servicios.map((x) => x.vecesSolicitado).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF262626)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFA855F7).withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('🔥', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 10),
              const Text(
                'Servicios Demandados',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (servicios.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('Sin datos de servicios para este periodo.', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
              ),
            )
          else
            ...servicios.take(5).map((s) {
              final percentage = maxVeces > 0 ? (s.vecesSolicitado / maxVeces) : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              s.nombreServicio,
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF262626),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                s.categoria.toUpperCase(),
                                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${s.vecesSolicitado}',
                          style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        height: 6,
                        width: double.infinity,
                        color: const Color(0xFF262626),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: percentage.clamp(0.0, 1.0),
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.primary, Color(0xFFA855F7)],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
