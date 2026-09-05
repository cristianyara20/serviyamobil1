import '../models/pqrs_entity.dart';

abstract class IPqrsRepository {
  Future<List<PqrsEntity>> fetchPqrs();
  Future<bool> createPqrs({
    required int idReserva,
    required TipoPqr tipoPqr,
    required String descripcion,
  });
}