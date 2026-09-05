import '../models/admin_pqr_entity.dart';

abstract class IAdminPqrsRepository {
  Future<List<AdminPqrEntity>> fetchPqrs();
  Future<bool> responderPqr({required int idPqr, required String respuestaAdmin});
}
