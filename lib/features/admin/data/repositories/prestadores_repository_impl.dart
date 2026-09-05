import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/prestador_operativo_entity.dart';
import '../../domain/models/reserva_historial_entity.dart';
import '../datasources/prestadores_remote_datasource.dart';

abstract class PrestadoresRepository {
  Future<List<PrestadorOperativoEntity>> fetchPrestadores();
  Future<List<ReservaHistorialEntity>> fetchHistorialServicios({int? idPrestador});
}

class PrestadoresRepositoryImpl implements PrestadoresRepository {
  final PrestadoresRemoteDataSource _dataSource;

  PrestadoresRepositoryImpl(this._dataSource);

  @override
  Future<List<PrestadorOperativoEntity>> fetchPrestadores() {
    return _dataSource.fetchPrestadores();
  }

  @override
  Future<List<ReservaHistorialEntity>> fetchHistorialServicios({int? idPrestador}) {
    return _dataSource.fetchHistorialServicios(idPrestador: idPrestador);
  }
}

final prestadoresDataSourceProvider = Provider<PrestadoresRemoteDataSource>((ref) {
  final dio = ref.watch(apiClientProvider);
  return PrestadoresRemoteDataSource(dio);
});

final prestadoresRepositoryProvider = Provider<PrestadoresRepository>((ref) {
  final ds = ref.watch(prestadoresDataSourceProvider);
  return PrestadoresRepositoryImpl(ds);
});
