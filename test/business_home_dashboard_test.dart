import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klippr/klippr/analytics/domain/stores/analytics_store.dart';
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
            analyticsStore: _FakeAnalyticsStore({
              'promo-1': 5,
              'promo-2': 12,
            }),
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
  }) async =>
      const Success('new-promo');

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
  }) async =>
      const Success(null);

  @override
  Future<Result<void>> delete(String id) async => const Success(null);

  @override
  Future<Result<void>> publish(
    String id, {
    bool isBusinessVerified = true,
  }) async =>
      const Success(null);

  @override
  Future<Result<void>> cancel(String id) async => const Success(null);
}

class _FakeAnalyticsStore implements AnalyticsStore {
  const _FakeAnalyticsStore(this.counts);

  final Map<String, int> counts;

  @override
  Future<Result<int>> loadPromotionRedemptions(
    String businessId,
    String promotionId,
  ) async =>
      Success(counts[promotionId] ?? 0);
}
