import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:klippr/klippr/promotions/data/network/promotions_web_service.dart';
import 'package:klippr/klippr/promotions/data/stores/http_promotions_store.dart';
import 'package:klippr/klippr/shared/data/network/api_client.dart';
import 'package:klippr/klippr/shared/data/pref/prefs_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'loadActive returns all active promotions without owner filtering',
    () async {
      SharedPreferences.setMockInitialValues({
        'session_token': 'token',
        'user_id': 'user-1',
        'profile_id': 'business-1',
      });
      final prefs = PrefsHelper.test(await SharedPreferences.getInstance());
      final client = MockClient((request) async {
        expect(request.url.path, '/api/promotions/active');
        return http.Response(
          '[${_promotion('promo-1', 'business-1')},'
          '${_promotion('promo-2', 'business-2')}]',
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final store = HttpPromotionsStore(
        PromotionsWebService(ApiClient(client: client, prefs: prefs)),
        prefs: prefs,
      );

      final result = await store.loadActive();

      expect(result.dataOrNull!.map((promo) => promo.id.value), [
        'promo-1',
        'promo-2',
      ]);
      expect(result.dataOrNull!.last.businessName, 'Negocio business-2');
    },
  );

  test(
    'loadByBusiness calls GET /api/promotions/businesses/{businessId}',
    () async {
      SharedPreferences.setMockInitialValues({
        'session_token': 'token',
        'user_id': 'user-1',
        'profile_id': 'business-1',
      });
      final prefs = PrefsHelper.test(await SharedPreferences.getInstance());
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/promotions/businesses/business-1');
        return http.Response(
          '[${_promotion('promo-1', 'business-1')},'
          '${_promotion('promo-own-2', 'business-1')}]',
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final store = HttpPromotionsStore(
        PromotionsWebService(ApiClient(client: client, prefs: prefs)),
        prefs: prefs,
      );

      final result = await store.loadByBusiness('business-1');

      expect(result.dataOrNull!.map((promo) => promo.id.value), [
        'promo-1',
        'promo-own-2',
      ]);
      expect(result.dataOrNull!.first.title, 'Promo');
      expect(result.dataOrNull!.first.businessName, 'Negocio business-1');
      expect(result.dataOrNull!.first.imageKey, isNull);
    },
  );
}

String _promotion(String id, String businessId) =>
    '{"id":"$id","businessId":"$businessId",'
    '"businessName":"Negocio $businessId","title":"Promo",'
    '"description":"Descripcion","discountAmount":10,'
    '"discountType":"Percentage","startDate":"2026-07-01T00:00:00Z",'
    '"endDate":"2026-08-01T00:00:00Z","status":"Published",'
    '"isActive":true}';
