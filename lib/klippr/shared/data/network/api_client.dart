import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../pref/prefs_helper.dart';
import 'result.dart';
import 'api_config.dart';
import 'api_exceptions.dart';

// author: Samuel Bonifacio
//
// Cliente HTTP central que envuelve `package:http`.
//
// - Construye URIs vía [ApiConfig] (soporta paths arbitrarios).
// - Inyecta headers JSON y, cuando [auth] es true y existe token,
//   `Authorization: Bearer <token>`.
// - Decodifica cuerpos JSON y devuelve un [Result] tipado: [Success] con el
//   payload decodificado (Map/List/null) en 2xx, [Failure] con un
//   [ApiException] en caso contrario.
//
// Tanto [http.Client] como [PrefsHelper] son inyectables para tests.

/// Verbos HTTP soportados por [ApiClient].
enum _Method { get, post, put, delete }

/// Cliente HTTP central de la aplicación.
class ApiClient {
  ApiClient({http.Client? client, PrefsHelper? prefs})
      : _client = client ?? http.Client(),
        _prefs = prefs ?? PrefsHelper.instance;

  final http.Client _client;
  final PrefsHelper _prefs;

  Future<Result<dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
    bool auth = true,
  }) =>
      _send(_Method.get, path, query: query, auth: auth);

  Future<Result<dynamic>> post(
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    bool auth = true,
  }) =>
      _send(_Method.post, path, query: query, body: body, auth: auth);

  Future<Result<dynamic>> put(
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    bool auth = true,
  }) =>
      _send(_Method.put, path, query: query, body: body, auth: auth);

  Future<Result<dynamic>> delete(
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    bool auth = true,
  }) =>
      _send(_Method.delete, path, query: query, body: body, auth: auth);

  /// Centraliza el armado de headers, el envío, el manejo de errores y el
  /// decodificado de la respuesta.
  Future<Result<dynamic>> _send(
    _Method method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    bool auth = true,
  }) async {
    final uri = ApiConfig.uri(path, query);
    final headers = _buildHeaders(auth: auth);
    final encodedBody = body == null ? null : jsonEncode(body);

    try {
      final response = await _dispatch(method, uri, headers, encodedBody)
          .timeout(ApiConfig.timeout);
      return _handleResponse(response);
    } on TimeoutException {
      return const Failure(TimeoutApiException());
    } on SocketException {
      return const Failure(NetworkException());
    } on http.ClientException {
      return const Failure(NetworkException());
    }
  }

  Map<String, String> _buildHeaders({required bool auth}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = _prefs.token;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<http.Response> _dispatch(
    _Method method,
    Uri uri,
    Map<String, String> headers,
    String? body,
  ) {
    return switch (method) {
      _Method.get => _client.get(uri, headers: headers),
      _Method.post => _client.post(uri, headers: headers, body: body),
      _Method.put => _client.put(uri, headers: headers, body: body),
      _Method.delete => _client.delete(uri, headers: headers, body: body),
    };
  }

  Result<dynamic> _handleResponse(http.Response response) {
    final code = response.statusCode;
    final raw = response.body;
    final decoded = _tryDecode(raw);

    // El cuerpo no estaba vacío pero no era JSON válido -> error de parseo.
    if (decoded is _DecodeError) {
      return const Failure(ParseException());
    }

    if (code >= 200 && code < 300) {
      return Success<dynamic>(decoded);
    }

    return Failure(ApiException.fromStatus(code, _extractMessage(decoded, code)));
  }

  /// Decodifica JSON; devuelve null para cuerpos vacíos, [_DecodeError] si el
  /// JSON es inválido, o el valor decodificado en otro caso.
  Object? _tryDecode(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      return jsonDecode(raw);
    } on FormatException {
      return const _DecodeError();
    }
  }

  /// Extrae un mensaje legible de un cuerpo de error decodificado cuando es
  /// posible.
  String _extractMessage(Object? decoded, int code) {
    if (decoded is Map<String, dynamic>) {
      final msg = decoded['message'] ?? decoded['title'] ?? decoded['error'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    return 'Error HTTP $code.';
  }

  /// Libera el cliente subyacente. Llamar al cerrar la app.
  void close() => _client.close();
}

/// Centinela que marca un decode de JSON inválido (distinto de un body null
/// real).
class _DecodeError {
  const _DecodeError();
}
