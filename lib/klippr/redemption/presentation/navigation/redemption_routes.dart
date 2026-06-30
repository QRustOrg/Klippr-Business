// author: Samuel Bonifacio
//
// Catálogo canónico de los nombres de ruta del bounded context Redemption.

/// Nombres simbólicos de las rutas de Redemption.
abstract final class RedemptionRoutes {
  /// Escaneo de código QR para canjear.
  static const String scan = 'redemption-scan';

  /// Ingreso manual del token de canje.
  static const String manual = 'redemption-manual';

  /// Historial agregado, agrupado por promoción.
  static const String historyList = 'redemption-history-list';

  /// Historial de una promoción específica.
  static const String historyForPromotion = 'redemption-history-for-promotion';
}
