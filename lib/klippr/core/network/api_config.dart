// author: Samuel Bonifacio
//
// Configuración central de red: URLs base por entorno, timeouts y construcción
// de URIs. Acepta paths arbitrarios porque la API de Klippr no es consistente
// (`/api/...`, `/api/v1/Favorites`, casing mixto); el llamador pasa el path
// completo y esta clase solo antepone el host.

/// Entorno de backend objetivo.
enum Environment { dev, staging, prod }

/// Configuración de red de la aplicación.
class ApiConfig {
  const ApiConfig._();

  /// Entorno activo.
  ///
  /// Para sobreescribir en tiempo de build sin editar código, cambiar a:
  ///   `--dart-define=ENV=dev|staging|prod` y leerlo con
  ///   `String.fromEnvironment('ENV')`.
  static const Environment current = Environment.prod;

  static const Map<Environment, String> _baseUrls = {
    // Loopback del emulador Android hacia la máquina host.
    Environment.dev: 'http://10.0.2.2:5000',
    Environment.staging: 'https://klippr-backend-staging.up.railway.app',
    Environment.prod: 'https://klippr-backend-production.up.railway.app',
  };

  /// Host base (esquema + autoridad) para el entorno activo.
  static String get baseUrl => _baseUrls[current]!;

  /// Timeout por request aplicado por el cliente.
  static const Duration timeout = Duration(seconds: 30);

  /// Construye un [Uri] a partir de un [path] arbitrario
  /// (ej. `/api/promotions/active`) más [query] params opcionales. Los valores
  /// del query se convierten a string; los valores null se descartan.
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
