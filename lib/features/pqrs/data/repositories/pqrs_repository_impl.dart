import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/supabase_client.dart';
import '../../domain/models/pqrs_entity.dart';
import '../../domain/repositories/i_pqrs_repository.dart';
import '../datasources/pqrs_remote_datasource.dart';

final pqrsRemoteDataSourceProvider = Provider<PqrsRemoteDataSource>((ref) {
  return PqrsRemoteDataSource(ref.watch(supabaseClientProvider));
});

final pqrsRepositoryProvider = Provider<IPqrsRepository>((ref) {
  return PqrsRepositoryImpl(ref.watch(pqrsRemoteDataSourceProvider));
});

class PqrsRepositoryImpl implements IPqrsRepository {
  final PqrsRemoteDataSource _dataSource;

  PqrsRepositoryImpl(this._dataSource);

  @override
  Future<List<PqrsEntity>> fetchPqrs() => _dataSource.fetchPqrs();

  @override
  Future<bool> createPqrs({
    required int idReserva,
    required TipoPqr tipoPqr,
    required String descripcion,
  }) =>
      _dataSource.createPqrs(
        idReserva: idReserva,
        tipoPqr: tipoPqr,
        descripcion: descripcion,
      );
}