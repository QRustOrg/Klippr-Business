import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:klippr/klippr/promotions/data/network/promotions_web_service.dart';
import 'package:klippr/klippr/promotions/data/stores/http_promotions_store.dart';
import 'package:klippr/klippr/shared/data/network/api_client.dart';
import 'package:klippr/klippr/shared/data/pref/prefs_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('publish sends the promotion id without a request body', () async {
    SharedPreferences.setMockInitialValues({'session_token': 'token'});
    final prefs = PrefsHelper.test(await SharedPreferences.getInstance());
    late http.Request seen;
    final client = MockClient((request) async {
      seen = request;
      return http.Response('', 204);
    });
    final store = HttpPromotionsStore(
      PromotionsWebService(ApiClient(client: client, prefs: prefs)),
      prefs: prefs,
    );

    final result = await store.publish('promotion-id');

    expect(result.isSuccess, isTrue);
    expect(seen.method, 'POST');
    expect(seen.url.path, '/api/promotions/promotion-id/publish');
    expect(seen.body, isEmpty);
  });
}
