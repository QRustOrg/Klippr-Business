// NOTA: [Result]/[ApiException] viven en shared/data/network por decision
// consciente (se mantuvo Result<T> en vez de migrar a excepciones); es la
// unica concesion a la pureza hexagonal estricta en este puerto.

import '../../../shared/data/network/result.dart';
import '../models/redemption.dart';

// author: Samuel Bonifacio
//
// Puerto (hexagonal) que describe las capacidades de redención que necesita
// la capa de aplicación. Agnóstico del origen de datos concreto; el
// adaptador HTTP vive en `data/stores/`.

/// Puerto de redenciones del bounded context Redemption.
abstract interface class RedemptionStore {
  /// Busca una redención por su token único entre las del negocio actual.
  Future<Result<Redemption>> lookupToken(String uniqueToken);

  /// Confirma una redención identificada por su token único.
  Future<Result<Redemption>> confirmToken(String uniqueToken);

  /// Carga el historial de redenciones de una promoción.
  Future<Result<List<Redemption>>> loadHistory(String promotionId);
}
