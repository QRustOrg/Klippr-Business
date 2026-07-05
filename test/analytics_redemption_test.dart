import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:klippr/klippr/analytics/data/network/analytics_web_service.dart';
import 'package:klippr/klippr/analytics/data/stores/http_analytics_store.dart';
import 'package:klippr/klippr/redemption/application/bloc/redemption_bloc.dart';
import 'package:klippr/klippr/redemption/application/bloc/redemption_event.dart';
import 'package:klippr/klippr/redemption/application/bloc/redemption_state.dart';
import 'package:klippr/klippr/redemption/data/network/redemption_web_service.dart';
import 'package:klippr/klippr/redemption/data/stores/http_redemption_store.dart';
import 'package:klippr/klippr/redemption/domain/models/redemption.dart';
import 'package:klippr/klippr/redemption/domain/stores/redemption_store.dart';
import 'package:klippr/klippr/shared/data/network/api_client.dart';
import 'package:klippr/klippr/shared/data/network/api_exceptions.dart';
import 'package:klippr/klippr/shared/data/network/result.dart';
import 'package:klippr/klippr/shared/data/pref/prefs_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('analytics store maps dashboard and posts metrics body', () async {
    SharedPreferences.setMockInitialValues({'session_token': 'token'});
    final prefs = PrefsHelper.test(await SharedPreferences.getInstance());
    final seen = <String>[];
    final client = MockClient((request) async {
      seen.add('${request.method} ${request.url.path} ${request.body}');
      if (request.url.path.contains('/dashboard/')) {
        return http.Response(
          '{"businessId":"business-1","totalPromotions":5,'
          '"activePromotions":3,"totalRedemptions":21,"usedRedemptions":13,'
          '"views":44,"averageRating":4.5}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('', 204);
    });
    final store = HttpAnalyticsStore(
      AnalyticsWebService(ApiClient(client: client, prefs: prefs)),
    );

    final dashboard = await store.loadDashboard('business-1');
    final metrics = await store.updateMetrics(
      businessId: 'business-1',
      campaignId: 'campaign-1',
      viewsToAdd: 2,
      redemptionsToAdd: 1,
      newRating: 4.5,
    );

    expect(dashboard.dataOrNull?.totalRedemptions, 21);
    expect(metrics.isSuccess, isTrue);
    expect(seen.first, startsWith('GET /api/analytics/dashboard/business-1'));
    expect(seen.last, contains('"viewsToAdd":2'));
  });

  test('redemption store confirms by token and by numeric id', () async {
    SharedPreferences.setMockInitialValues({
      'session_token': 'token',
      'user_id': 'business-1',
    });
    final prefs = PrefsHelper.test(await SharedPreferences.getInstance());
    final seen = <String>[];
    final client = MockClient((request) async {
      seen.add('${request.method} ${request.url.path}');
      return http.Response(
        '{"id":"42","promotionId":"promo-1","promotionTitle":"Promo",'
        '"consumerId":"consumer-1","customerName":"Ana","uniqueToken":"token-1",'
        '"code":"ABC","status":"Redeemed","validationMethod":"QR",'
        '"discountAppliedAmount":10,"generatedAt":"2026-01-01T00:00:00Z",'
        '"redeemedAt":"2026-01-01T00:01:00Z"}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final store = HttpRedemptionStore(
      RedemptionWebService(ApiClient(client: client, prefs: prefs)),
      prefs: prefs,
    );

    final byToken = await store.confirmToken('token-1');
    final byId = await store.confirmById('42');

    expect(byToken.dataOrNull?.status, RedemptionTokenStatus.confirmed);
    expect(byId.dataOrNull?.id.value, '42');
    expect(seen, [
      'POST /api/redemptions/tokens/token-1/confirm',
      'POST /api/redemptions/42/confirm',
    ]);
  });

  test('redemption bloc rejects already confirmed redemption by id', () async {
    final bloc = RedemptionBloc(_FakeRedemptionStore());

    bloc.add(const ConfirmRedemptionById(redemptionId: '42'));

    await expectLater(
      bloc.stream,
      emitsThrough(
        predicate<RedemptionState>(
          (s) => s.error == 'Este canje ya fue usado.',
        ),
      ),
    );
  });
}

class _FakeRedemptionStore implements RedemptionStore {
  @override
  Future<Result<Redemption>> lookupToken(String uniqueToken) async =>
      Failure(NotFoundException('Token invalido.'));

  @override
  Future<Result<Redemption>> confirmToken(String uniqueToken) async =>
      Failure(ValidationException('Este canje ya fue usado.'));

  @override
  Future<Result<Redemption>> confirmById(String redemptionId) async =>
      Failure(ValidationException('Este canje ya fue usado.'));

  @override
  Future<Result<List<Redemption>>> loadHistory(String promotionId) async =>
      const Success([]);
}
