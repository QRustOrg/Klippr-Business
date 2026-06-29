import 'package:flutter_test/flutter_test.dart';
import 'package:klippr/klippr/shared/data/pref/prefs_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('stores and clears remembered user email and password', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = PrefsHelper.test(await SharedPreferences.getInstance());

    await prefs.setRememberedUser(
      email: 'business@klippr.com',
      password: 'secret123',
    );

    expect(prefs.rememberMe, isTrue);
    expect(prefs.rememberedEmail, 'business@klippr.com');
    expect(prefs.rememberedPassword, 'secret123');

    await prefs.clearRememberedUser();

    expect(prefs.rememberMe, isFalse);
    expect(prefs.rememberedEmail, isNull);
    expect(prefs.rememberedPassword, isNull);
  });
}