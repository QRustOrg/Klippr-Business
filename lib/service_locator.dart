import 'package:get_it/get_it.dart';

import 'klippr/analytics/analytics_dependencies.dart';
import 'klippr/iam/iam_dependencies.dart';
import 'klippr/profile/profile_dependencies.dart';
import 'klippr/promotions/promotions_dependencies.dart';
import 'klippr/redemption/redemption_dependencies.dart';
import 'klippr/shared/data/pref/prefs_helper.dart';
import 'klippr/shared/shared_dependencies.dart';

// author: Samuel Bonifacio
//
// Locator de servicios y raíz de composición de la aplicación. Resuelve el
// grafo global de [GetIt]: primero la infraestructura compartida, luego cada
// bounded context (cada uno solo conoce sus propios puertos).

/// Inicializa el grafo global del locator.
///
/// Debe esperarse una vez durante el bootstrap, antes de resolver cualquier
/// dependencia.
abstract final class ServiceLocator {
  /// Inicializa el grafo global del locator.
  static Future<void> init({GetIt? locator}) async {
    final sl = locator ?? GetIt.instance;

    // Infraestructura compartida transversal (caché + cliente HTTP centralizado).
    final prefs = PrefsHelper.instance;
    await prefs.init();
    SharedDependencies.register(sl, prefs);

    // Bounded contexts (cada uno depende solo de la infraestructura compartida).
    IamDependencies.register(sl);
    PromotionsDependencies.register(sl);
    RedemptionDependencies.register(sl);
    AnalyticsDependencies.register(sl);
    ProfileDependencies.register(sl);
  }
}
