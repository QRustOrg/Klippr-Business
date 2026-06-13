import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight key-value persistence wrapper over [SharedPreferences].
///
/// Holds the session token plus generic helpers for small flags/preferences.
/// NOT for structured/heavy data — that belongs in the future `db` cache layer.
///
/// Usage: call [init] once at app startup (before runApp) so [token] and the
/// synchronous getters work without awaiting.
class PrefsHelper {
  PrefsHelper._();

  /// Shared singleton. A custom instance can still be constructed in tests
  /// via [PrefsHelper.test].
  static final PrefsHelper instance = PrefsHelper._();

  /// Test constructor allowing a pre-seeded [SharedPreferences].
  PrefsHelper.test(SharedPreferences prefs) : _prefs = prefs;

  SharedPreferences? _prefs;

  // Storage keys.
  static const String _kToken = 'session_token';

  /// Loads the underlying store. Safe to call multiple times.
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _store {
    final store = _prefs;
    if (store == null) {
      throw StateError('PrefsHelper.init() must be called before use.');
    }
    return store;
  }

  // --- Session token -------------------------------------------------------

  /// Current bearer token, or null if not signed in.
  String? get token => _store.getString(_kToken);

  Future<void> setToken(String token) => _store.setString(_kToken, token);

  Future<void> clearToken() => _store.remove(_kToken);

  // --- Generic helpers -----------------------------------------------------

  String? getString(String key) => _store.getString(key);
  Future<void> setString(String key, String value) =>
      _store.setString(key, value);

  bool? getBool(String key) => _store.getBool(key);
  Future<void> setBool(String key, bool value) => _store.setBool(key, value);

  Future<void> remove(String key) => _store.remove(key);
}
