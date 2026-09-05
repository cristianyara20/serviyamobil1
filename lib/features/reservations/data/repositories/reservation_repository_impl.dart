import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/supabase_client.dart';
import '../../domain/models/reservation_entity.dart';
import '../../domain/repositories/i_reservation_repository.dart';
import '../datasources/reservation_remote_datasource.dart';

final reservationRemoteDataSourceProvider =
    Provider<ReservationRemoteDataSource>((ref) {
  return ReservationRemoteDataSource(
    ref.watch(supabaseClientProvider),
    ref.watch(apiClientProvider),
  );
});

final reservationRepositoryProvider =
    Provider<IReservationRepository>((ref) {
  return ReservationRepositoryImpl(
    ref.watch(reservationRemoteDataSourceProvider),
  );
});

class ReservationRepositoryImpl implements IReservationRepository {
  final ReservationRemoteDataSource _remoteDataSource;

  ReservationRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<ReservationEntity>> fetchMyReservations() {
    return _remoteDataSource.fetchReservations();
  }

  @override
  Future<ReservationEntity> createReservation({
    required int idServicio,
    required String direccion,
    required String descripcion,
    required DateTime fechaAgenda,
    int? idPrestador,
  }) {
    return _remoteDataSource.createReservation(
      idServicio: idServicio,
      direccion: direccion,
      descripcion: descripcion,
      fechaAgenda: fechaAgenda,
      idPrestador: idPrestador,
    );
  }

  @override
  Future<bool> cancelReservation(int idReserva) {
    return _remoteDataSource.cancelReservation(idReserva);
  }
}