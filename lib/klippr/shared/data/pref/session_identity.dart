import 'dart:convert';

import 'prefs_helper.dart';

// author: Samuel Bonifacio
//
// Recupera el userId de sesión cuando hay token pero falta el id en prefs
// (p. ej. sesiones antiguas o splash que solo validaba el token).

/// Utilidades de identidad de sesión.
abstract final class SessionIdentity {
  /// Intenta rellenar [PrefsHelper.userId] desde el JWT si está vacío.
  ///
  /// Devuelve el userId efectivo (prefs o recuperado), o null si no hay.
  static Future<String?> ensureUserId([PrefsHelper? prefs]) async {
    final p = prefs ?? PrefsHelper.instance;
    final existing = p.userId;
    if (existing != null && existing.isNotEmpty) return existing;

    final token = p.token;
    if (token == null || token.isEmpty) return null;

    final recovered = userIdFromJwt(token);
    if (recovered == null || recovered.isEmpty) return null;

    await p.setUserId(recovered);
    return recovered;
  }

  /// Extrae el userId del payload JWT sin validar firma (solo cliente).
  static String? userIdFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;

      var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      final mod = payload.length % 4;
      if (mod > 0) payload += '=' * (4 - mod);

      final map =
          jsonDecode(utf8.decode(base64.decode(payload))) as Map<String, dynamic>;

      const keys = <String>[
        'sub',
        'userId',
        'nameid',
        'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier',
      ];
      for (final key in keys) {
        final value = map[key];
        if (value is String && value.isNotEmpty) return value;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
