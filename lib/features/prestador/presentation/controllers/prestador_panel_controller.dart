import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/prestador_solicitud_entity.dart';
import '../../domain/models/prestador_stats_entity.dart';
import '../../data/repositories/prestador_repository_impl.dart';


class PrestadorDashboardState {
  final List<PrestadorSolicitudEntity> reservas;
  final PrestadorStatsEntity? stats;
  final bool isLoading;
  final String? error;

  PrestadorDashboardState({
    required this.reservas,
    this.stats,
    this.isLoading = false,
    this.error,
  });

  PrestadorDashboardState copyWith({
    List<PrestadorSolicitudEntity>? reservas,
    PrestadorStatsEntity? stats,
    bool? isLoading,
    String? error,
  }) {
    return PrestadorDashboardState(
      reservas: reservas ?? this.reservas,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final prestadorPanelProvider = StateNotifierProvider.family<
    PrestadorPanelController, PrestadorDashboardState, int>((ref, idPrestador) {
  return PrestadorPanelController(
    ref.watch(prestadorRepositoryProvider),
    idPrestador,
  );
});

class PrestadorPanelController extends StateNotifier<PrestadorDashboardState> {
  final PrestadorRepository _repo;
  final int _idPrestador;

  PrestadorPanelController(this._repo, this._idPrestador)
      : super(PrestadorDashboardState(reservas: [], isLoading: true)) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _repo.fetchReservas(_idPrestador),
        _repo.fetchStats(_idPrestador),
      ]);

      state = PrestadorDashboardState(
        reservas: results[0] as List<PrestadorSolicitudEntity>,
        stats: results[1] as PrestadorStatsEntity,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> setDisponibilidad(String estado) async {
    try {
      await _repo.updateDisponibilidad(_idPrestador, estado);
      if (state.stats != null) {
        final newStats = PrestadorStatsEntity(
          completados: state.stats!.completados,
          calificacion: state.stats!.calificacion,
          activos: state.stats!.activos,
          disponibilidad: estado.toLowerCase(),
          nivel: state.stats!.nivel,
          progresoMeta: state.stats!.progresoMeta,
        );
        state = state.copyWith(stats: newStats);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> aceptarSolicitud(int idReserva) async {
    try {
      await _repo.aceptarSolicitud(idReserva, _idPrestador);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> rechazarSolicitud(int idReserva) async {
    try {
      await _repo.rechazarSolicitud(idReserva, _idPrestador);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> completarServicio({
    required int idReserva,
    required Uint8List imageBytes,
    String fileExtension = 'jpg',
  }) async {
    try {
      await _repo.completarServicio(
        idReserva: idReserva,
        idPrestador: _idPrestador,
        imageBytes: imageBytes,
        fileExtension: fileExtension,
      );
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }
}

