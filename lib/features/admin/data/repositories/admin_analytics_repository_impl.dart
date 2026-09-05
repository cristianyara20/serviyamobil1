import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/admin_analytics_entity.dart';
import '../../domain/repositories/i_admin_analytics_repository.dart';
import '../datasources/admin_analytics_remote_datasource.dart';

final adminAnalyticsDataSourceProvider = Provider<AdminAnalyticsRemoteDataSource>((ref) {
  final dio = ref.watch(apiClientProvider);
  return AdminAnalyticsRemoteDataSource(dio);
});

final adminAnalyticsRepositoryProvider = Provider<IAdminAnalyticsRepository>((ref) {
  final dataSource = ref.watch(adminAnalyticsDataSourceProvider);
  return AdminAnalyticsRepositoryImpl(dataSource);
});

class AdminAnalyticsRepositoryImpl implements IAdminAnalyticsRepository {
  final AdminAnalyticsRemoteDataSource _dataSource;

  AdminAnalyticsRepositoryImpl(this._dataSource);

  @override
  Future<AdminAnalyticsFullData> fetchAnalytics({required int mes, required int anio}) {
    return _dataSource.fetchAnalytics(mes: mes, anio: anio);
  }

  @override
  Future<List<int>> downloadReportePDF({required int mes, required int anio}) {
    return _dataSource.downloadReportePDF(mes: mes, anio: anio);
  }
}
