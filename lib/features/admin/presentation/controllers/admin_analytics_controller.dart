import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;
import '../../data/repositories/admin_analytics_repository_impl.dart';
import '../../domain/models/admin_analytics_entity.dart';
import '../../domain/repositories/i_admin_analytics_repository.dart';

class AdminAnalyticsState {
  final int mes;
  final int anio;
  final AsyncValue<AdminAnalyticsFullData> data;

  AdminAnalyticsState({
    required this.mes,
    required this.anio,
    required this.data,
  });

  AdminAnalyticsState copyWith({
    int? mes,
    int? anio,
    AsyncValue<AdminAnalyticsFullData>? data,
  }) {
    return AdminAnalyticsState(
      mes: mes ?? this.mes,
      anio: anio ?? this.anio,
      data: data ?? this.data,
    );
  }
}

final adminAnalyticsControllerProvider =
    StateNotifierProvider<AdminAnalyticsController, AdminAnalyticsState>((ref) {
  final repo = ref.watch(adminAnalyticsRepositoryProvider);
  final now = DateTime.now();
  return AdminAnalyticsController(repo, initialMes: now.month, initialAnio: now.year)..load();
});

class AdminAnalyticsController extends StateNotifier<AdminAnalyticsState> {
  final IAdminAnalyticsRepository _repository;

  AdminAnalyticsController(
    this._repository, {
    required int initialMes,
    required int initialAnio,
  }) : super(AdminAnalyticsState(
          mes: initialMes,
          anio: initialAnio,
          data: const AsyncValue.loading(),
        ));

  Future<void> load() async {
    state = state.copyWith(data: const AsyncValue.loading());
    try {
      final res = await _repository.fetchAnalytics(mes: state.mes, anio: state.anio);
      state = state.copyWith(data: AsyncValue.data(res));
    } catch (e, st) {
      state = state.copyWith(data: AsyncValue.error(e, st));
    }
  }

  void setMes(int mes) {
    if (state.mes == mes) return;
    state = state.copyWith(mes: mes);
    load();
  }

  void setAnio(int anio) {
    if (state.anio == anio) return;
    state = state.copyWith(anio: anio);
    load();
  }

  Future<String> downloadPDF() async {
    final bytes = await _repository.downloadReportePDF(mes: state.mes, anio: state.anio);
    final fileName = 'reporte_general_${state.mes}_${state.anio}.pdf';

    // 1. Navegador Web (Chrome / Edge): Descarga directa via Blob de JavaScript
    if (kIsWeb) {
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = fileName;
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
      return fileName;
    }

    // 2. Dispositivo Móvil / Desktop (Android, iOS, Windows): Guarda archivo local y lo abre
    io.Directory? dir;
    try {
      dir = await getApplicationDocumentsDirectory();
    } catch (_) {
      try {
        dir = await getTemporaryDirectory();
      } catch (_) {
        dir = io.Directory.systemTemp;
      }
    }

    final file = io.File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);

    try {
      await OpenFilex.open(file.path);
    } catch (_) {}

    return file.path;
  }
}
