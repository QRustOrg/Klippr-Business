// author: Samuel Bonifacio
//
// Wrapper ligero de persistencia clave-valor sobre [SharedPreferences].
//
// Guarda el token de sesión más helpers genéricos para flags/preferencias
// pequeñas. NO es para datos estructurados/pesados — eso corresponde a la
// futura capa de cache `db`.
//
// Uso: llamar [init] una vez al iniciar la app (antes de runApp) para que
// [token] y los getters síncronos funcionen sin await.

import 'package:shared_preferences/shared_preferences.dart';

/// Wrapper de persistencia ligera basado en [SharedPreferences].
class PrefsHelper {
  PrefsHelper._();

  /// Singleton compartido. En tests se puede construir una instancia propia
  /// con [PrefsHelper.test].
  static final PrefsHelper instance = PrefsHelper._();

  /// Constructor para tests que permite inyectar un [SharedPreferences].
  PrefsHelper.test(SharedPreferences prefs) : _prefs = prefs;

  SharedPreferences? _prefs;

  // Claves de almacenamiento.
  static const String _kToken = 'session_token';

  /// Carga el almacén subyacente. Seguro llamarlo varias veces.
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _store {
    final store = _prefs;
    if (store == null) {
      throw StateError('Debe llamarse PrefsHelper.init() antes de usarlo.');
    }
    return store;
  }

  // --- Token de sesión -----------------------------------------------------

  /// Token bearer actual, o null si no hay sesión iniciada.
  String? get token => _store.getString(_kToken);

  Future<void> setToken(String token) => _store.setString(_kToken, token);

  Future<void> clearToken() => _store.remove(_kToken);

  // --- Helpers genéricos ---------------------------------------------------

  String? getString(String key) => _store.getString(key);
  Future<void> setString(String key, String value) =>
      _store.setString(key, value);

  bool? getBool(String key) => _store.getBool(key);
  Future<void> setBool(String key, bool value) => _store.setBool(key, value);

  Future<void> remove(String key) => _store.remove(key);
}
