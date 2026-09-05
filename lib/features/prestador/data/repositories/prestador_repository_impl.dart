import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/prestador_solicitud_entity.dart';
import '../../domain/models/prestador_stats_entity.dart';
import '../datasources/prestador_remote_datasource.dart';

final prestadorRemoteDataSourceProvider = Provider<PrestadorRemoteDataSource>((ref) {
  return PrestadorRemoteDataSource();
});

final prestadorRepositoryProvider = Provider<PrestadorRepository>((ref) {
  return PrestadorRepositoryImpl(ref.watch(prestadorRemoteDataSourceProvider));
});

abstract class PrestadorRepository {
  Future<List<PrestadorSolicitudEntity>> fetchReservas(int idPrestador);
  Future<PrestadorStatsEntity> fetchStats(int idPrestador);
  Future<void> updateDisponibilidad(int idPrestador, String nuevoEstado);
  Future<void> aceptarSolicitud(int idReserva, int idPrestador);
  Future<void> rechazarSolicitud(int idReserva, int idPrestador);
  Future<void> completarServicio({
    required int idReserva,
    required int idPrestador,
    required Uint8List imageBytes,
    String fileExtension = 'jpg',
  });
}

class PrestadorRepositoryImpl implements PrestadorRepository {
  final PrestadorRemoteDataSource _ds;

  PrestadorRepositoryImpl(this._ds);

  @override
  Future<List<PrestadorSolicitudEntity>> fetchReservas(int idPrestador) =>
      _ds.fetchReservas(idPrestador);

  @override
  Future<PrestadorStatsEntity> fetchStats(int idPrestador) =>
      _ds.fetchStats(idPrestador);

  @override
  Future<void> updateDisponibilidad(int idPrestador, String nuevoEstado) =>
      _ds.updateDisponibilidad(idPrestador, nuevoEstado);

  @override
  Future<void> aceptarSolicitud(int idReserva, int idPrestador) =>
      _ds.aceptarSolicitud(idReserva, idPrestador);

  @override
  Future<void> rechazarSolicitud(int idReserva, int idPrestador) =>
      _ds.rechazarSolicitud(idReserva, idPrestador);

  @override
  Future<void> completarServicio({
    required int idReserva,
    required int idPrestador,
    required Uint8List imageBytes,
    String fileExtension = 'jpg',
  }) =>
      _ds.completarServicio(
        idReserva: idReserva,
        idPrestador: idPrestador,
        imageBytes: imageBytes,
        fileExtension: fileExtension,
      );
}

