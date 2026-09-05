import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/supabase_client.dart';
import '../../domain/models/calificacion_entity.dart';
import '../../domain/repositories/i_calificacion_repository.dart';
import '../datasources/calificacion_remote_datasource.dart';

final calificacionRemoteDataSourceProvider =
    Provider<CalificacionRemoteDataSource>((ref) {
  return CalificacionRemoteDataSource(ref.watch(supabaseClientProvider));
});

final calificacionRepositoryProvider =
    Provider<ICalificacionRepository>((ref) {
  return CalificacionRepositoryImpl(
    ref.watch(calificacionRemoteDataSourceProvider),
  );
});

class CalificacionRepositoryImpl implements ICalificacionRepository {
  final CalificacionRemoteDataSource _dataSource;

  CalificacionRepositoryImpl(this._dataSource);

  @override
  Future<List<CalificacionEntity>> fetchCalificaciones() {
    return _dataSource.fetchCalificaciones();
  }

  @override
  Future<bool> createCalificacion({
    required int idReserva,
    required int puntuacion,
    required String comentario,
  }) {
    return _dataSource.createCalificacion(
      idReserva: idReserva,
      puntuacion: puntuacion,
      comentario: comentario,
    );
  }
}