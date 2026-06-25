import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klippr/klippr/analytics/repository/analytics_repository.dart';
import 'package:klippr/klippr/analytics/services/analytics_service.dart';
import 'package:klippr/klippr/core/network/api_client.dart';
import 'package:klippr/klippr/core/utils/result.dart';
import 'package:klippr/klippr/promotions/bloc/promotions_bloc.dart';
import 'package:klippr/klippr/promotions/models/promotion.dart';
import 'package:klippr/klippr/promotions/repository/promotions_repository.dart';
import 'package:klippr/klippr/promotions/services/promotions_service.dart';
import 'package:klippr/klippr/promotions/views/active_promotions_screen.dart';
import 'package:klippr/klippr/promotions/views/business_home_screen.dart';

void main() {
  testWidgets('draft promotion card renders mockup details and draft actions', (
    tester,
  ) async {
    final repo = _FakePromotionsRepository([
      _promotion(
        id: 'PROMO0574A52D41',
        title: 'Champions',
        description:
            'Por la compra de 2 hamburguesas, llevate la tercera completamente gratis',
        status: PromotionStatus.draft,
        isActive: false,
        redemptionCap: 250,
      ),
    ]);

    await tester.pumpBusinessHome(repo);

    expect(find.text('CHAMPIONS'), findsOneWidget);
    expect(find.textContaining('tercera completamente gratis'), findsOneWidget);
    expect(find.text('250 unid.'), findsOneWidget);
    expect(find.text('12 canjes'), findsOneWidget);
    expect(find.text('PROMO0574A52D41'), findsOneWidget);
    expect(find.text('Borrador'), findsOneWidget);
    expect(find.byTooltip('Editar promocion'), findsOneWidget);
    expect(find.byTooltip('Eliminar promocion'), findsOneWidget);
    expect(find.byTooltip('Publicar promocion'), findsOneWidget);
    expect(find.byTooltip('Cancelar promocion'), findsNothing);
  });

  testWidgets('double tapping a draft card fetches fresh data and opens edit', (
    tester,
  ) async {
    final repo = _FakePromotionsRepository(
      [
        _promotion(
          id: 'PROMODRAFT123',
          title: 'Draft old title',
          description: 'Old description',
          status: PromotionStatus.draft,
          isActive: false,
        ),
      ],
      promotionById: _promotion(
        id: 'PROMODRAFT123',
        title: 'Fresh draft title',
        description: 'Fresh description from backend',
        status: PromotionStatus.draft,
        isActive: false,
      ),
    );

    await tester.pumpBusinessHome(repo);
    await tester.scrollUntilVisible(find.text('DRAFT OLD TITLE'), 120);
    final draftTitleCenter = tester.getCenter(find.text('DRAFT OLD TITLE'));
    await tester.tapAt(draftTitleCenter);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(draftTitleCenter);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(repo.getByIdCalls, 1);
    expect(find.text('+ QR'), findsWidgets);
    expect(find.text('Fresh draft title'), findsOneWidget);
  });

  testWidgets('double tapping a non-draft card shows edit guard snackbar', (
    tester,
  ) async {
    final repo = _FakePromotionsRepository([
      _promotion(
        id: 'PROMOPUBLISHED123',
        title: 'Published promo',
        description: 'Published promotions cannot be edited',
        status: PromotionStatus.published,
        isActive: true,
      ),
    ]);

    await tester.pumpBusinessHome(repo);
    await tester.scrollUntilVisible(find.text('PUBLISHED PROMO'), 120);
    final publishedTitleCenter = tester.getCenter(find.text('PUBLISHED PROMO'));
    await tester.tapAt(publishedTitleCenter);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(publishedTitleCenter);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(repo.getByIdCalls, 0);
    expect(
      find.text('Solo puedes editar promociones en borrador.'),
      findsOneWidget,
    );
  });

  testWidgets('publish action asks for confirmation before publishing', (
    tester,
  ) async {
    final repo = _FakePromotionsRepository([
      _promotion(
        id: 'PROMODRAFTPUBLISH',
        title: 'Draft publish',
        description: 'Ready to publish',
        status: PromotionStatus.draft,
        isActive: false,
      ),
    ]);

    await tester.pumpBusinessHome(repo);
    final publishButton = find.ancestor(
      of: find.byIcon(Icons.publish_outlined),
      matching: find.byType(IconButton),
    );
    await tester.scrollUntilVisible(publishButton, 120);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -180),
    );
    await tester.pump();
    await tester.tap(publishButton);
    await tester.pumpAndSettle();

    expect(find.text('Publicar promocion'), findsOneWidget);
    expect(repo.publishCalls, 0);

    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(repo.publishCalls, 1);
    expect(find.text('Promocion publicada.'), findsOneWidget);
  });

  testWidgets('published promotion card shows active state and cancel action', (
    tester,
  ) async {
    final repo = _FakePromotionsRepository([
      _promotion(
        id: 'PROMOACTIVE1234',
        title: 'A lo pobre',
        description:
            'Llevate una hamburguesa con papas fritas totalmente gratis',
        status: PromotionStatus.published,
        isActive: true,
        redemptionCap: 100,
      ),
    ]);

    await tester.pumpBusinessHome(repo);

    expect(find.text('A LO POBRE'), findsOneWidget);
    expect(find.text('Activa'), findsOneWidget);
    expect(find.byTooltip('Editar promocion'), findsNothing);
    expect(find.byTooltip('Publicar promocion'), findsNothing);
    expect(find.byTooltip('Cancelar promocion'), findsOneWidget);
    expect(find.byTooltip('Eliminar promocion'), findsOneWidget);
  });

  testWidgets('expired and cancelled promotions only expose delete action', (
    tester,
  ) async {
    final repo = _FakePromotionsRepository([
      _promotion(
        id: 'PROMOEXPIRED123',
        title: 'Promo expirada',
        description: 'Promocion fuera de vigencia',
        status: PromotionStatus.expired,
        isActive: false,
        endDate: DateTime(2024, 1, 10),
      ),
      _promotion(
        id: 'PROMOCANCEL123',
        title: 'Promo cancelada',
        description: 'Promocion cancelada por el negocio',
        status: PromotionStatus.cancelled,
        isActive: false,
      ),
    ]);

    await tester.pumpBusinessHome(repo);

    expect(find.text('Expirada'), findsOneWidget);
    expect(find.text('Cancelada'), findsOneWidget);
    expect(find.byTooltip('Editar promocion'), findsNothing);
    expect(find.byTooltip('Publicar promocion'), findsNothing);
    expect(find.byTooltip('Cancelar promocion'), findsNothing);
    expect(find.byTooltip('Eliminar promocion'), findsNWidgets(2));
  });

  testWidgets('Mi Lista shows only active promotions from current business', (
    tester,
  ) async {
    final repo = _FakePromotionsRepository(
      const [],
      activePromotions: [
        _promotion(
          id: 'PROMOOWNACTIVE',
          title: 'Own active',
          description: 'This belongs to the current business',
          status: PromotionStatus.published,
          isActive: true,
          businessId: 'business-1',
        ),
        _promotion(
          id: 'PROMOOTHERACTIVE',
          title: 'Other active',
          description: 'This belongs to another business',
          status: PromotionStatus.published,
          isActive: true,
          businessId: 'business-2',
        ),
      ],
    );

    await tester.pumpActivePromotions(repo);

    expect(repo.loadActiveMineCalls, 1);
    expect(find.text('OWN ACTIVE'), findsOneWidget);
    expect(find.text('OTHER ACTIVE'), findsNothing);
  });
}

extension on WidgetTester {
  Future<void> pumpBusinessHome(_FakePromotionsRepository repo) async {
    await pumpWidget(
      MaterialApp(
        home: BlocProvider<PromotionsBloc>(
          create: (_) => PromotionsBloc(repo),
          child: BusinessHomeScreen(
            analyticsRepository: _FakeAnalyticsRepository(),
          ),
        ),
      ),
    );
    await pumpAndSettle();
  }

  Future<void> pumpActivePromotions(_FakePromotionsRepository repo) async {
    await pumpWidget(
      MaterialApp(
        home: BlocProvider<PromotionsBloc>(
          create: (_) => PromotionsBloc(repo),
          child: const ActivePromotionsScreen(),
        ),
      ),
    );
    await pumpAndSettle();
  }
}

class _FakeAnalyticsRepository extends AnalyticsRepository {
  _FakeAnalyticsRepository() : super(AnalyticsService(ApiClient()));

  @override
  Future<Result<int>> loadPromotionRedemptions(String promotionId) async =>
      const Success(12);
}

Promotion _promotion({
  required String id,
  required String title,
  required String description,
  required PromotionStatus status,
  required bool isActive,
  String businessId = 'business-1',
  String? imageKey,
  int? redemptionCap,
  DateTime? startDate,
  DateTime? endDate,
}) {
  return Promotion(
    id: id,
    businessId: businessId,
    title: title,
    description: description,
    discountAmount: 50,
    discountType: DiscountType.percentage,
    startDate: startDate ?? DateTime(2026, 6, 1),
    endDate: endDate ?? DateTime(2027, 9, 7),
    redemptionCap: redemptionCap,
    imageKey: imageKey,
    status: status,
    isActive: isActive,
  );
}

class _FakePromotionsRepository extends PromotionsRepository {
  _FakePromotionsRepository(
    this.promotions, {
    this.activePromotions = const [],
    Promotion? promotionById,
  }) : promotionById =
           promotionById ?? (promotions.isEmpty ? null : promotions.first),
       super(PromotionsService(ApiClient()));

  final List<Promotion> promotions;
  final List<Promotion> activePromotions;
  final Promotion? promotionById;
  int getByIdCalls = 0;
  int loadActiveMineCalls = 0;
  int publishCalls = 0;
  int cancelCalls = 0;

  @override
  String? get businessId => 'business-1';

  @override
  Future<Result<List<Promotion>>> loadMine() async => Success(promotions);

  @override
  Future<Result<List<Promotion>>> loadActiveMine() async {
    loadActiveMineCalls += 1;
    return Success(
      activePromotions.where((p) => p.businessId == businessId).toList(),
    );
  }

  @override
  Future<Result<Promotion>> getById(String id) async {
    getByIdCalls += 1;
    return Success(promotionById ?? promotions.firstWhere((p) => p.id == id));
  }

  @override
  Future<Result<void>> cancel(String id) async {
    cancelCalls += 1;
    return const Success(null);
  }

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
  }) async => const Success('new-promotion');

  @override
  Future<Result<void>> delete(String id) async => const Success(null);

  @override
  Future<Result<void>> publish(
    String id, {
    bool isBusinessVerified = true,
  }) async {
    publishCalls += 1;
    return const Success(null);
  }

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
}
