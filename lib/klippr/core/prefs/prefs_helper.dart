import 'package:shared_preferences/shared_preferences.dart';

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
  static const String _kUserId = 'user_id';
  static const String _kRememberMe = 'remember_me';
  static const String _kRememberedEmail = 'remembered_email';

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

  // --- Id de usuario / negocio --------------------------------------------

  /// Id del usuario autenticado (usado como businessId en Promotions).
  String? get userId => _store.getString(_kUserId);

  Future<void> setUserId(String id) => _store.setString(_kUserId, id);

  Future<void> clearUserId() => _store.remove(_kUserId);

  // --- Usuario recordado ---------------------------------------------------

  bool get rememberMe => _store.getBool(_kRememberMe) ?? false;

  String? get rememberedEmail => _store.getString(_kRememberedEmail);

  Future<void> setRememberedUser({required String email}) async {
    await _store.setBool(_kRememberMe, true);
    await _store.setString(_kRememberedEmail, email.trim());
  }

  Future<void> clearRememberedUser() async {
    await _store.setBool(_kRememberMe, false);
    await _store.remove(_kRememberedEmail);
  }

  // --- Helpers genéricos ---------------------------------------------------

  String? getString(String key) => _store.getString(key);
  Future<void> setString(String key, String value) =>
      _store.setString(key, value);

  bool? getBool(String key) => _store.getBool(key);
  Future<void> setBool(String key, bool value) => _store.setBool(key, value);

  Future<void> remove(String key) => _store.remove(key);
}
