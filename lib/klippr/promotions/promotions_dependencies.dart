import 'package:get_it/get_it.dart';

import '../shared/data/network/api_client.dart';
import 'application/bloc/promotions_bloc.dart';
import 'data/network/promotions_web_service.dart';
import 'data/stores/http_promotions_store.dart';
import 'domain/stores/promotions_store.dart';

// author: Samuel Bonifacio
//
// Composition root del bounded context Promotions. Cablea el grafo de
// objetos del feature en [GetIt], respetando la dirección de dependencia
// hexagonal: el [PromotionsBloc] depende solo del puerto [PromotionsStore].

/// Registra las dependencias de Promotions en [sl].
abstract final class PromotionsDependencies {
  /// Registra el servicio web, el store y el bloc de Promotions en [sl].
  ///
  /// Debe ejecutarse después de las dependencias compartidas (que provee
  /// [ApiClient]).
  static void register(GetIt sl) {
    sl
      ..registerLazySingleton<PromotionsWebService>(
        () => PromotionsWebService(sl<ApiClient>()),
      )
      ..registerLazySingleton<PromotionsStore>(
        () => HttpPromotionsStore(sl<PromotionsWebService>()),
      )
      ..registerFactory<PromotionsBloc>(
        () => PromotionsBloc(sl<PromotionsStore>()),
      );
  }
}
