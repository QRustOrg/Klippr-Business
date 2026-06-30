import 'package:get_it/get_it.dart';

import '../shared/data/network/api_client.dart';
import 'data/network/analytics_web_service.dart';
import 'data/stores/http_analytics_store.dart';
import 'domain/stores/analytics_store.dart';

// author: Samuel Bonifacio
//
// Composition root del bounded context Analytics. Cablea el grafo de
// objetos del feature en [GetIt], respetando la dirección de dependencia
// hexagonal: cualquier consumidor depende solo del puerto [AnalyticsStore].

/// Registra las dependencias de Analytics en [sl].
abstract final class AnalyticsDependencies {
  /// Registra el servicio web y el store de Analytics en [sl].
  ///
  /// Debe ejecutarse después de las dependencias compartidas (que provee
  /// [ApiClient]).
  static void register(GetIt sl) {
    sl
      ..registerLazySingleton<AnalyticsWebService>(
        () => AnalyticsWebService(sl<ApiClient>()),
      )
      ..registerLazySingleton<AnalyticsStore>(
        () => HttpAnalyticsStore(sl<AnalyticsWebService>()),
      );
  }
}
