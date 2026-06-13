/// Target backend environment.
enum Environment { dev, staging, prod }

/// Central network configuration: base URLs per environment, timeouts and
/// URI building. Accepts arbitrary paths because the Klippr API is not
/// consistent (`/api/...`, `/api/v1/Favorites`, mixed casing), so callers pass
/// the full path and this class only prepends the host.
class ApiConfig {
  const ApiConfig._();

  /// Active environment.
  ///
  /// To override at build time without editing code, switch to:
  ///   `--dart-define=ENV=dev|staging|prod` and read it via
  ///   `String.fromEnvironment('ENV')`.
  static const Environment current = Environment.prod;

  static const Map<Environment, String> _baseUrls = {
    // Android emulator loopback to host machine.
    Environment.dev: 'http://10.0.2.2:5000',
    Environment.staging: 'https://klippr-backend-staging.up.railway.app',
    Environment.prod: 'https://klippr-backend-production.up.railway.app',
  };

  /// Base host (scheme + authority) for the active environment.
  static String get baseUrl => _baseUrls[current]!;

  /// Per-request timeout applied by the client.
  static const Duration timeout = Duration(seconds: 30);

  /// Builds a [Uri] from an arbitrary [path] (e.g. `/api/promotions/active`)
  /// plus optional [query] params. Query values are stringified; null values
  /// are dropped.
  static Uri uri(String path, [Map<String, dynamic>? query]) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final base = Uri.parse('$baseUrl$normalizedPath');

    if (query == null || query.isEmpty) return base;

    final params = <String, String>{};
    query.forEach((key, value) {
      if (value != null) params[key] = '$value';
    });

    return base.replace(queryParameters: {...base.queryParameters, ...params});
  }
}
