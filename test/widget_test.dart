import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klippr/klippr/core/network/api_client.dart';
import 'package:klippr/klippr/core/utils/result.dart';
import 'package:klippr/klippr/promotions/bloc/promotions_bloc.dart';
import 'package:klippr/klippr/promotions/models/promotion.dart';
import 'package:klippr/klippr/promotions/repository/promotions_repository.dart';
import 'package:klippr/klippr/promotions/services/promotions_service.dart';
import 'package:klippr/klippr/promotions/views/business_home_screen.dart';

void main() {
  testWidgets('draft promotion card renders mockup details and draft actions',
      (tester) async {
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
    expect(find.text('PROMO0574A52D41'), findsOneWidget);
    expect(find.text('Borrador'), findsOneWidget);
    expect(find.byTooltip('Editar promocion'), findsOneWidget);
    expect(find.byTooltip('Eliminar promocion'), findsOneWidget);
    expect(find.byTooltip('Publicar promocion'), findsOneWidget);
    expect(find.byTooltip('Cancelar promocion'), findsNothing);
  });

  testWidgets('published promotion card shows active state and cancel action',
      (tester) async {
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

  testWidgets('expired and cancelled promotions only expose delete action',
      (tester) async {
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
}

extension on WidgetTester {
  Future<void> pumpBusinessHome(_FakePromotionsRepository repo) async {
    await pumpWidget(
      MaterialApp(
        home: BlocProvider<PromotionsBloc>(
          create: (_) => PromotionsBloc(repo),
          child: const BusinessHomeScreen(),
        ),
      ),
    );
    await pumpAndSettle();
  }
}

Promotion _promotion({
  required String id,
  required String title,
  required String description,
  required PromotionStatus status,
  required bool isActive,
  int? redemptionCap,
  DateTime? startDate,
  DateTime? endDate,
}) {
  return Promotion(
    id: id,
    businessId: 'business-1',
    title: title,
    description: description,
    discountAmount: 50,
    discountType: DiscountType.percentage,
    startDate: startDate ?? DateTime(2026, 6, 1),
    endDate: endDate ?? DateTime(2027, 9, 7),
    redemptionCap: redemptionCap,
    status: status,
    isActive: isActive,
  );
}

class _FakePromotionsRepository extends PromotionsRepository {
  _FakePromotionsRepository(this.promotions)
      : super(PromotionsService(ApiClient()));

  final List<Promotion> promotions;

  @override
  String? get businessId => 'business-1';

  @override
  Future<Result<List<Promotion>>> loadMine() async => Success(promotions);

  @override
  Future<Result<void>> cancel(String id) async => const Success(null);

  @override
  Future<Result<String>> create({
    required String title,
    required String description,
    required double discountAmount,
    required DiscountType discountType,
    required DateTime startDate,
    required DateTime endDate,
    int? redemptionCap,
  }) async =>
      const Success('new-promotion');

  @override
  Future<Result<void>> delete(String id) async => const Success(null);

  @override
  Future<Result<void>> publish(
    String id, {
    bool isBusinessVerified = true,
  }) async =>
      const Success(null);

  @override
  Future<Result<void>> update(
    String id, {
    required String title,
    required String description,
    required double discountAmount,
    required DiscountType discountType,
    required DateTime startDate,
    required DateTime endDate,
    int? redemptionCap,
  }) async =>
      const Success(null);
}
