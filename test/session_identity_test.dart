import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:klippr/klippr/shared/data/pref/session_identity.dart';

void main() {
  test('userIdFromJwt reads sub claim', () {
    final payload = base64Url
        .encode(utf8.encode(jsonEncode({'sub': 'user-123', 'role': 'BUSINESS'})))
        .replaceAll('=', '');
    final token = 'header.$payload.sig';

    expect(SessionIdentity.userIdFromJwt(token), 'user-123');
  });

  test('userIdFromJwt reads .NET nameidentifier claim', () {
    final payload = base64Url
        .encode(
          utf8.encode(
            jsonEncode({
              'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier':
                  'net-user-9',
            }),
          ),
        )
        .replaceAll('=', '');
    final token = 'x.$payload.y';

    expect(SessionIdentity.userIdFromJwt(token), 'net-user-9');
  });

  test('userIdFromJwt returns null for garbage', () {
    expect(SessionIdentity.userIdFromJwt('not-a-jwt'), isNull);
  });
}
