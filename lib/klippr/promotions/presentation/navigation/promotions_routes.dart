// author: Samuel Bonifacio
//
// Catálogo canónico de los nombres de ruta del bounded context Promotions.

/// Nombres simbólicos de las rutas de Promotions.
abstract final class PromotionsRoutes {
  /// Dashboard principal del negocio (home post-login).
  static const String home = 'promotions-home';

  /// Listado de promociones activas.
  static const String active = 'promotions-active';

  /// Formulario de creación/edición de una promoción.
  static const String create = 'promotions-create';
}
