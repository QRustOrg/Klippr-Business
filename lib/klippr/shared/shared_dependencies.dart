import 'package:get_it/get_it.dart';

import 'data/network/api_client.dart';
import 'data/pref/prefs_helper.dart';

// author: Samuel Bonifacio
//
// Composition root de la capa compartida fundacional. Registra la
// infraestructura transversal consumida por todos los bounded contexts: el
// caché clave-valor y el [ApiClient] centralizado.

/// Registra las dependencias compartidas en [sl].
abstract final class SharedDependencies {
  /// Registra las dependencias compartidas en [sl].
  ///
  /// [prefs] debe estar ya resuelto (ver [PrefsHelper.init]) antes de llamar
  /// a este método durante el bootstrap.
  static void register(GetIt sl, PrefsHelper prefs) {
    sl
      ..registerSingleton<PrefsHelper>(prefs)
      ..registerLazySingleton<ApiClient>(() => ApiClient(prefs: prefs));
  }
}
