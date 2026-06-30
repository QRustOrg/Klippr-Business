import 'package:get_it/get_it.dart';

import '../shared/data/network/api_client.dart';
import 'application/bloc/auth_bloc.dart';
import 'data/network/iam_web_service.dart';
import 'data/stores/http_authentication_store.dart';
import 'domain/stores/authentication_store.dart';

// author: Samuel Bonifacio
//
// Composition root del bounded context IAM. Cablea el grafo de objetos del
// feature en [GetIt], respetando la dirección de dependencia hexagonal: el
// [AuthBloc] depende solo del puerto [AuthenticationStore].

/// Registra las dependencias de IAM en [sl].
abstract final class IamDependencies {
  /// Registra el servicio web, el store y el bloc de IAM en [sl].
  ///
  /// Debe ejecutarse después de las dependencias compartidas (que provee
  /// [ApiClient]).
  static void register(GetIt sl) {
    sl
      ..registerLazySingleton<IamWebService>(
        () => IamWebService(sl<ApiClient>()),
      )
      ..registerLazySingleton<AuthenticationStore>(
        () => HttpAuthenticationStore(sl<IamWebService>()),
      )
      ..registerFactory<AuthBloc>(
        () => AuthBloc(sl<AuthenticationStore>()),
      );
  }
}
