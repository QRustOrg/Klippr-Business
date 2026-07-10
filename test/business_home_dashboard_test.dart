import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klippr/klippr/analytics/domain/stores/analytics_store.dart';
import 'package:klippr/klippr/analytics/domain/models/business_dashboard_metrics.dart';
import 'package:klippr/klippr/analytics/models/campaign_metrics.dart';
import 'package:klippr/klippr/profile/application/bloc/profile_bloc.dart';
import 'package:klippr/klippr/profile/domain/models/business_profile.dart';
import 'package:klippr/klippr/profile/domain/models/business_profile_update.dart';
import 'package:klippr/klippr/profile/domain/models/verification_document.dart';
import 'package:klippr/klippr/profile/domain/stores/profile_store.dart';
import 'package:klippr/klippr/promotions/application/bloc/promotions_bloc.dart';
import 'package:klippr/klippr/promotions/domain/models/promotion.dart';
import 'package:klippr/klippr/promotions/domain/stores/promotions_store.dart';
import 'package:klippr/klippr/promotions/presentation/views/business_home_screen.dart';
import 'package:klippr/klippr/shared/data/network/result.dart';
import 'package:klippr/klippr/shared/domain/models/id.dart';

void main() {
  testWidgets('shows total redemptions to date in the dashboard hero', (
    tester,
  ) async {
    final promotions = [
      _promotion(id: 'promo-1', title: 'Combo familiar'),
      _promotion(id: 'promo-2', title: 'Almuerzo ejecutivo'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => PromotionsBloc(_FakePromotionsStore(promotions)),
          child: BusinessHomeScreen(
            analyticsStore: _FakeAnalyticsStore({'promo-1': 5, 'promo-2': 12}),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text('Tus promos tienen 17 canjes hasta la fecha'),
      findsOneWidget,
    );
  });

  testWidgets('unverified business cannot send publish request', (
    tester,
  ) async {
    final store = _TrackingPromotionsStore([
      _promotion(
        id: 'promo-1',
        title: 'Promo borrador',
      ).copyWith(status: PromotionStatus.draft, isActive: false),
    ]);
    final profileBloc = ProfileBloc(_UnverifiedProfileStore());

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => PromotionsBloc(store)),
          BlocProvider.value(value: profileBloc),
        ],
        child: MaterialApp(
          home: BusinessHomeScreen(
            analyticsStore: const _FakeAnalyticsStore({}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(profileBloc.state.profile?.isVerified, isFalse);

    final publish = find.ancestor(
      of: find.byIcon(Icons.publish_outlined),
      matching: find.byType(IconButton),
    );
    await tester.scrollUntilVisible(publish, 120);
    tester.widget<IconButton>(publish).onPressed!();
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Tu negocio debe estar verificado antes de publicar promociones.',
      ),
      findsOneWidget,
    );
    expect(store.publishCalls, 0);
  });
}

Promotion _promotion({required String id, required String title}) {
  return Promotion(
    id: Id(id),
    businessId: const Id('business-1'),
    title: title,
    description: 'Promocion de prueba',
    discountAmount: 20,
    discountType: DiscountType.percentage,
    startDate: DateTime(2026, 6),
    endDate: DateTime(2026, 12),
    redemptionCap: 100,
    status: PromotionStatus.published,
    isActive: true,
  );
}

class _FakePromotionsStore implements PromotionsStore {
  const _FakePromotionsStore(this.promotions);

  final List<Promotion> promotions;

  @override
  Future<Result<List<Promotion>>> loadMine() async => Success(promotions);

  @override
  Future<Result<List<Promotion>>> loadActiveMine() async => Success(promotions);

  @override
  Future<Result<Promotion>> getById(String id) async =>
      Success(promotions.first);

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
  }) async => const Success('new-promo');

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

class _TrackingPromotionsStore extends _FakePromotionsStore {
  _TrackingPromotionsStore(super.promotions);

  int publishCalls = 0;

  @override
  Future<Result<void>> publish(String id) async {
    publishCalls++;
    return const Success(null);
  }
}

class _UnverifiedProfileStore implements ProfileStore {
  @override
  Future<Result<BusinessProfile>> loadBusinessProfile() async => Success(
    BusinessProfile(
      id: const Id('profile-1'),
      userId: const Id('business-1'),
      businessName: 'Negocio',
      verificationStatus: 'NONE',
    ),
  );

  @override
  Future<Result<BusinessProfile>> updateBusinessProfile(
    BusinessProfileUpdate update,
  ) async => loadBusinessProfile();

  @override
  Future<Result<void>> submitVerification(
    VerificationDocument document,
  ) async => const Success(null);
}

class _FakeAnalyticsStore implements AnalyticsStore {
  const _FakeAnalyticsStore(this.counts);

  final Map<String, int> counts;

  @override
  Future<Result<BusinessDashboardMetrics>> loadDashboard(
    String businessId,
  ) async => Success(
    BusinessDashboardMetrics(
      businessId: businessId,
      totalPromotions: counts.length,
      activePromotions: counts.length,
      totalRedemptions: counts.values.fold(0, (sum, value) => sum + value),
      usedRedemptions: counts.values.fold(0, (sum, value) => sum + value),
      views: 0,
      averageRating: 0,
    ),
  );

  @override
  Future<Result<int>> loadPromotionRedemptions(
    String businessId,
    String promotionId,
  ) async => Success(counts[promotionId] ?? 0);

  @override
  Future<Result<Map<String, int>>> loadPromotionRedemptionCounts(
    String businessId,
  ) async => Success(Map<String, int>.from(counts));

  @override
  Future<Result<CampaignMetrics>> loadCampaignMetrics(
    String campaignId,
  ) async => Success(
    CampaignMetrics(
      campaignId: campaignId,
      businessId: 'business-1',
      views: 0,
      redemptions: counts[campaignId] ?? 0,
      averageRating: 0,
      conversionRate: 0,
    ),
  );

  @override
  Future<Result<void>> updateMetrics({
    required String businessId,
    String? campaignId,
    int? viewsToAdd,
    int? redemptionsToAdd,
    double? newRating,
  }) async => const Success(null);
}
