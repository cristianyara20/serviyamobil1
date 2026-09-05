import '../../domain/models/admin_analytics_entity.dart';

abstract class IAdminAnalyticsRepository {
  Future<AdminAnalyticsFullData> fetchAnalytics({required int mes, required int anio});
  Future<List<int>> downloadReportePDF({required int mes, required int anio});
}
