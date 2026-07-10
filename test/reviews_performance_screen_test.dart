import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:klippr/klippr/analytics/domain/models/business_dashboard_metrics.dart';
import 'package:klippr/klippr/analytics/domain/stores/analytics_store.dart';
import 'package:klippr/klippr/analytics/models/campaign_metrics.dart';
import 'package:klippr/klippr/community/presentation/views/reviews_performance_screen.dart';
import 'package:klippr/klippr/community/repository/reviews_repository.dart';
import 'package:klippr/klippr/promotions/domain/models/promotion.dart';
import 'package:klippr/klippr/promotions/domain/stores/promotions_store.dart';
import 'package:klippr/klippr/shared/data/network/api_client.dart';
import 'package:klippr/klippr/shared/data/network/api_exceptions.dart';
import 'package:klippr/klippr/shared/data/network/result.dart';
import 'package:klippr/klippr/shared/data/pref/prefs_helper.dart';
import 'package:klippr/klippr/shared/domain/models/id.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('separates own promotions from active promotions to explore', (
    tester,
  ) async {
    final dependencies = await _dependencies();

    await tester.pumpWidget(
      MaterialApp(
        home: ReviewsPerformanceScreen(
          profileId: 'business-1',
          reviewsRepository: dependencies.reviews,
          promotionsStore: dependencies.promotions,
          analyticsStore: dependencies.analytics,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mis promociones'), findsOneWidget);
    expect(find.text('Explorar'), findsOneWidget);
    expect(find.byKey(const Key('promotion-card-own-1')), findsOneWidget);
    expect(find.byKey(const Key('promotion-card-other-1')), findsNothing);
    expect(find.text('Promo propia'), findsOneWidget);
    expect(find.text('Activa'), findsOneWidget);
    expect(find.text('10% OFF'), findsOneWidget);
    expect(find.text('1 reseña'), findsOneWidget);
    expect(find.text('2 likes'), findsOneWidget);
    expect(find.text('1 respuesta'), findsOneWidget);
    expect(find.text('7 canjes'), findsOneWidget);

    await tester.tap(find.text('Explorar'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('promotion-card-own-1')), findsNothing);
    expect(find.byKey(const Key('promotion-card-other-1')), findsOneWidget);
    expect(find.text('Promo ajena'), findsOneWidget);
    expect(find.text('Otro negocio'), findsOneWidget);
    expect(find.text('4 canjes'), findsOneWidget);
  });

  testWidgets('allows replying only on reviews from an own promotion', (
    tester,
  ) async {
    final dependencies = await _dependencies();

    await tester.pumpWidget(
      MaterialApp(
        home: ReviewsPerformanceScreen(
          profileId: 'business-1',
          reviewsRepository: dependencies.reviews,
          promotionsStore: dependencies.promotions,
          analyticsStore: dependencies.analytics,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('promotion-card-own-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reply-field')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('reply-field')),
      'Gracias por venir',
    );
    await tester.tap(find.byKey(const Key('send-reply')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Gracias por venir'), findsOneWidget);

    Navigator.of(tester.element(find.text('Reseñas'))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explorar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('promotion-card-other-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reply-field')), findsNothing);
  });

  testWidgets('detail retries comments that failed during the initial load', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'session_token': 'token'});
    final prefs = PrefsHelper.test(await SharedPreferences.getInstance());
    var commentCalls = 0;
    final client = MockClient((request) async {
      if (request.url.path == '/api/reviews') {
        return http.Response(
          '[${_review('review-own', 'own-1', 'Promo propia', 0)}]',
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      commentCalls += 1;
      if (commentCalls == 1) {
        return http.Response(
          '{"message":"No disponible"}',
          500,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response(
        '[{"id":"comment-recovered","reviewId":"review-own",'
        '"userId":"business-1","userName":"Cafe",'
        '"comment":"Respuesta recuperada",'
        '"createdAt":"2026-07-10T13:00:00Z"}]',
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        home: ReviewsPerformanceScreen(
          profileId: 'business-1',
          reviewsRepository: ReviewsRepository(
            ApiClient(client: client, prefs: prefs),
          ),
          promotionsStore: _FakePromotionsStore(),
          analyticsStore: _FakeAnalyticsStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('promotion-card-own-1')));
    await tester.pumpAndSettle();

    expect(find.text('Reintentar respuestas'), findsOneWidget);
    await tester.tap(find.text('Reintentar respuestas'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Respuesta recuperada'), findsOneWidget);
  });
}

Future<_Dependencies> _dependencies() async {
  SharedPreferences.setMockInitialValues({'session_token': 'token'});
  final prefs = PrefsHelper.test(await SharedPreferences.getInstance());
  final client = MockClient((request) async {
    if (request.method == 'POST') {
      return http.Response(
        '{"id":"comment-new","reviewId":"review-own",'
        '"userId":"business-1","userName":"Cafe",'
        '"comment":"Gracias por venir",'
        '"createdAt":"2026-07-10T13:00:00Z"}',
        200,
        headers: {'content-type': 'application/json'},
      );
    }
    if (request.url.path == '/api/reviews') {
      return http.Response(
        '[${_review('review-own', 'own-1', 'Promo propia', 2)},'
        '${_review('review-other', 'other-1', 'Promo ajena', 1)}]',
        200,
        headers: {'content-type': 'application/json'},
      );
    }
    if (request.url.path.endsWith('review-own/comments')) {
      return http.Response(
        '[{"id":"comment-1","reviewId":"review-own",'
        '"userId":"business-1","userName":"Cafe",'
        '"comment":"Gracias","createdAt":"2026-07-10T12:30:00Z"}]',
        200,
        headers: {'content-type': 'application/json'},
      );
    }
    return http.Response(
      '[]',
      200,
      headers: {'content-type': 'application/json'},
    );
  });
  return _Dependencies(
    reviews: ReviewsRepository(ApiClient(client: client, prefs: prefs)),
    promotions: _FakePromotionsStore(),
    analytics: _FakeAnalyticsStore(),
  );
}

String _review(String id, String promotionId, String title, int likes) =>
    '{"id":"$id","promotionId":"$promotionId",'
    '"promotionTitle":"$title","businessName":"Cafe",'
    '"userId":"user-1","userName":"Ana","rating":4,'
    '"comment":"Muy buena","createdAt":1783695614354,'
    '"verified":true,"likeCount":$likes,"likedByCurrentUser":false}';

Promotion _promotion(
  String id,
  String businessId,
  String title, {
  String businessName = '',
}) => Promotion(
  id: Id(id),
  businessId: Id(businessId),
  businessName: businessName,
  title: title,
  description: 'Descripcion',
  discountAmount: 10,
  discountType: DiscountType.percentage,
  startDate: DateTime.utc(2026, 7),
  endDate: DateTime.utc(2026, 8),
  imageKey: 'comida_pizza',
  status: PromotionStatus.published,
  isActive: true,
);

class _Dependencies {
  const _Dependencies({
    required this.reviews,
    required this.promotions,
    required this.analytics,
  });

  final ReviewsRepository reviews;
  final PromotionsStore promotions;
  final AnalyticsStore analytics;
}

class _FakePromotionsStore implements PromotionsStore {
  final own = _promotion(
    'own-1',
    'business-1',
    'Promo propia',
    businessName: 'Mi cafe',
  );
  final other = _promotion(
    'other-1',
    'business-2',
    'Promo ajena',
    businessName: 'Otro negocio',
  );

  @override
  Future<Result<List<Promotion>>> loadMine() async => Success([own]);

  @override
  Future<Result<List<Promotion>>> loadByBusiness(String businessId) async {
    if (businessId == 'business-1') return Success([own]);
    if (businessId == 'business-2') return Success([other]);
    return const Success([]);
  }

  @override
  Future<Result<List<Promotion>>> loadActive() async => Success([own, other]);

  @override
  Future<Result<List<Promotion>>> loadActiveMine() async => Success([own]);

  @override
  Future<Result<Promotion>> getById(String id) async =>
      Failure(NotFoundException(id));

  @override
  Future<Result<String>> create({
    required String title,
    required String description,
    required double discountAmount,
    required DiscountType discountType,
    required DateTime startDate,
    required DateTime endDate,
    required String imageKey,
    int? redemptionCap,
  }) async => const Success('');

  @override
  Future<Result<void>> update(
    String id, {
    required String title,
    required String description,
    required double discountAmount,
    required DiscountType discountType,
    required DateTime startDate,
    required DateTime endDate,
    required String imageKey,
    int? redemptionCap,
  }) async => const Success(null);

  @override
  Future<Result<void>> delete(String id) async => const Success(null);

  @override
  Future<Result<void>> publish(String id) async => const Success(null);

  @override
  Future<Result<void>> cancel(String id) async => const Success(null);
}

class _FakeAnalyticsStore implements AnalyticsStore {
  @override
  Future<Result<Map<String, int>>> loadPromotionRedemptionCounts(
    String businessId,
  ) async => const Success({'own-1': 7});

  @override
  Future<Result<CampaignMetrics>> loadCampaignMetrics(
    String campaignId,
  ) async => Success(
    CampaignMetrics(
      campaignId: campaignId,
      businessId: 'business-2',
      views: 10,
      redemptions: 4,
      averageRating: 4,
      conversionRate: 0.4,
    ),
  );

  @override
  Future<Result<BusinessDashboardMetrics>> loadDashboard(
    String businessId,
  ) async => Failure(NotFoundException(businessId));

  @override
  Future<Result<int>> loadPromotionRedemptions(
    String businessId,
    String promotionId,
  ) async => const Success(0);

  @override
  Future<Result<void>> updateMetrics({
    required String businessId,
    String? campaignId,
    int? viewsToAdd,
    int? redemptionsToAdd,
    double? newRating,
  }) async => const Success(null);
}
