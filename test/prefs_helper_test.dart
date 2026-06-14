import 'package:flutter_test/flutter_test.dart';
import 'package:klippr/klippr/core/prefs/prefs_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('stores and clears remembered user email', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = PrefsHelper.test(await SharedPreferences.getInstance());

    await prefs.setRememberedUser(email: 'business@klippr.com');

    expect(prefs.rememberMe, isTrue);
    expect(prefs.rememberedEmail, 'business@klippr.com');

    await prefs.clearRememberedUser();

    expect(prefs.rememberMe, isFalse);
    expect(prefs.rememberedEmail, isNull);
  });
}
