import 'package:get_it/get_it.dart';

import '../shared/data/network/api_client.dart';
import 'application/bloc/redemption_bloc.dart';
import 'data/network/redemption_web_service.dart';
import 'data/stores/http_redemption_store.dart';
import 'domain/stores/redemption_store.dart';

// author: Samuel Bonifacio
//
// Composition root del bounded context Redemption. Cablea el grafo de
// objetos del feature en [GetIt], respetando la dirección de dependencia
// hexagonal: el [RedemptionBloc] depende solo del puerto [RedemptionStore].

/// Registra las dependencias de Redemption en [sl].
abstract final class RedemptionDependencies {
  /// Registra el servicio web, el store y el bloc de Redemption en [sl].
  ///
  /// Debe ejecutarse después de las dependencias compartidas (que provee
  /// [ApiClient]).
  static void register(GetIt sl) {
    sl
      ..registerLazySingleton<RedemptionWebService>(
        () => RedemptionWebService(sl<ApiClient>()),
      )
      ..registerLazySingleton<RedemptionStore>(
        () => HttpRedemptionStore(sl<RedemptionWebService>()),
      )
      ..registerFactory<RedemptionBloc>(
        () => RedemptionBloc(sl<RedemptionStore>()),
      );
  }
}
