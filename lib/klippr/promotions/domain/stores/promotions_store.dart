// NOTA: [Result]/[ApiException] viven en shared/data/network por decision
// consciente (se mantuvo Result<T> en vez de migrar a excepciones); es la
// unica concesion a la pureza hexagonal estricta en este puerto.

import '../../../shared/data/network/result.dart';
import '../models/promotion.dart';

// author: Samuel Bonifacio
//
// Puerto (hexagonal) que describe las capacidades de gestión de promociones
// que necesita la capa de aplicación. Agnóstico del origen de datos concreto;
// el adaptador HTTP vive en `data/stores/`.

/// Puerto de promociones del bounded context Promotions.
abstract interface class PromotionsStore {
  /// Carga todas las promociones del negocio autenticado.
  Future<Result<List<Promotion>>> loadMine();

  /// Lista promociones de un negocio: GET /api/promotions/businesses/{businessId}.
  Future<Result<List<Promotion>>> loadByBusiness(String businessId);

  /// Carga solo las promociones activas del negocio autenticado.
  Future<Result<List<Promotion>>> loadActiveMine();

  /// Carga las promociones activas de todos los negocios.
  Future<Result<List<Promotion>>> loadActive();

  /// Obtiene una promoción fresca por id (usado antes de abrir edición).
  Future<Result<Promotion>> getById(String id);

  /// Crea una promoción nueva y devuelve su id.
  Future<Result<String>> create({
    required String title,
    required String description,
    required double discountAmount,
    required DiscountType discountType,
    required DateTime startDate,
    required DateTime endDate,
    required String imageKey,
    int? redemptionCap,
  });

  /// Actualiza una promoción existente.
  Future<Result<void>> update(
    String id, {
    required String title,
    required String description,
    required double discountAmount,
    required DiscountType discountType,
    required DateTime startDate,
    required DateTime endDate,
    required String imageKey,
    int? redemptionCap,
  });

  /// Elimina una promoción.
  Future<Result<void>> delete(String id);

  /// Publica una promoción.
  Future<Result<void>> publish(String id);

  /// Cancela una promoción.
  Future<Result<void>> cancel(String id);
}
