// NOTA: [Result]/[ApiException] viven en shared/data/network por decision
// consciente (se mantuvo Result<T> en vez de migrar a excepciones); es la
// unica concesion a la pureza hexagonal estricta en este puerto.

import '../../../shared/data/network/result.dart';

// author: Samuel Bonifacio
//
// Puerto (hexagonal) que describe las capacidades de analítica que necesita
// la capa de aplicación. Agnóstico del origen de datos concreto; el
// adaptador HTTP vive en `data/stores/`.

/// Puerto de analítica del bounded context Analytics.
abstract interface class AnalyticsStore {
  /// Cuenta las redenciones confirmadas de una promoción de un negocio.
  Future<Result<int>> loadPromotionRedemptions(
    String businessId,
    String promotionId,
  );
}
