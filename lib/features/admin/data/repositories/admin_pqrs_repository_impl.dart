import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/supabase_client.dart';
import '../../domain/models/admin_pqr_entity.dart';
import '../../domain/repositories/i_admin_pqrs_repository.dart';
import '../datasources/admin_pqrs_remote_datasource.dart';

final adminPqrsRemoteDataSourceProvider = Provider<AdminPqrsRemoteDataSource>((ref) {
  final dio = ref.watch(apiClientProvider);
  final supabase = ref.watch(supabaseClientProvider);
  return AdminPqrsRemoteDataSource(dio, supabase);
});

final adminPqrsRepositoryProvider = Provider<IAdminPqrsRepository>((ref) {
  final ds = ref.watch(adminPqrsRemoteDataSourceProvider);
  return AdminPqrsRepositoryImpl(ds);
});

class AdminPqrsRepositoryImpl implements IAdminPqrsRepository {
  final AdminPqrsRemoteDataSource _dataSource;

  AdminPqrsRepositoryImpl(this._dataSource);

  @override
  Future<List<AdminPqrEntity>> fetchPqrs() => _dataSource.fetchPqrs();

  @override
  Future<bool> responderPqr({required int idPqr, required String respuestaAdmin}) =>
      _dataSource.responderPqr(idPqr: idPqr, respuestaAdmin: respuestaAdmin);
}
