import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:klippr/klippr/analytics/domain/models/business_dashboard_metrics.dart';
import 'package:klippr/klippr/analytics/domain/stores/analytics_store.dart';
import 'package:klippr/klippr/analytics/models/campaign_metrics.dart';
import 'package:klippr/klippr/iam/application/bloc/auth_bloc.dart';
import 'package:klippr/klippr/iam/domain/models/authenticated_user.dart';
import 'package:klippr/klippr/iam/domain/stores/authentication_store.dart';
import 'package:klippr/klippr/profile/application/bloc/profile_bloc.dart';
import 'package:klippr/klippr/profile/application/bloc/profile_event.dart';
import 'package:klippr/klippr/profile/application/bloc/profile_state.dart';
import 'package:klippr/klippr/profile/data/network/profile_web_service.dart';
import 'package:klippr/klippr/profile/data/stores/http_profile_store.dart';
import 'package:klippr/klippr/profile/domain/models/business_profile.dart';
import 'package:klippr/klippr/profile/domain/models/business_profile_update.dart';
import 'package:klippr/klippr/profile/domain/models/verification_document.dart';
import 'package:klippr/klippr/profile/domain/stores/profile_store.dart';
import 'package:klippr/klippr/profile/presentation/views/profile_screen.dart';
import 'package:klippr/klippr/promotions/application/bloc/promotions_bloc.dart';
import 'package:klippr/klippr/promotions/domain/models/promotion.dart';
import 'package:klippr/klippr/promotions/domain/stores/promotions_store.dart';
import 'package:klippr/klippr/shared/data/network/api_client.dart';
import 'package:klippr/klippr/shared/data/network/api_exceptions.dart';
import 'package:klippr/klippr/shared/data/network/result.dart';
import 'package:klippr/klippr/shared/data/pref/prefs_helper.dart';
import 'package:klippr/klippr/shared/domain/models/id.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('profile service calls prioritized business endpoints', () async {
    SharedPreferences.setMockInitialValues({'session_token': 'token'});
    final prefs = PrefsHelper.test(await SharedPreferences.getInstance());
    final seen = <String>[];
    final client = MockClient((request) async {
      seen.add('${request.method} ${request.url.path}');
      return http.Response(
        '{"id":"profile-1"}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = ProfileWebService(ApiClient(client: client, prefs: prefs));

    await service.createBusinessProfile({
      'id': 'profile-1',
      'userId': 'user-1',
      'businessName': 'Klippr Cafe',
    });
    await service.getBusinessProfile('profile-1');
    await service.updateBusinessProfile({
      'profileId': 'profile-1',
      'businessName': 'Klippr Cafe 2',
    });
    await service.submitVerification({
      'profileId': 'profile-1',
      'documentUrl': 'https://docs.test/ruc.pdf',
    });
    await service.getUser('user-1');

    expect(seen, [
      'POST /api/profiles/business',
      'GET /api/profiles/business/profile-1',
      'PUT /api/profiles/business',
      'POST /api/verification/submit',
      'GET /api/Users/user-1',
    ]);
  });

  test(
    'profile store creates and persists profile id when initial lookup misses',
    () async {
      SharedPreferences.setMockInitialValues({
        'session_token': 'token',
        'user_id': 'user-1',
      });
      final prefs = PrefsHelper.test(await SharedPreferences.getInstance());
      var call = 0;
      final client = MockClient((request) async {
        call += 1;
        if (call == 1) {
          expect(request.url.path, '/api/profiles/business/user-1');
          return http.Response('{"message":"missing"}', 404);
        }
        if (call == 2) {
          expect(request.url.path, '/api/Users/user-1');
          return http.Response(
            '{"userId":"user-1","email":"biz@test.com","role":"BUSINESS",'
            '"businessName":"Klippr Cafe","taxId":"20123456789",'
            '"isActive":true,"createdAt":"2026-01-01T00:00:00Z",'
            '"updatedAt":"2026-01-02T00:00:00Z"}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        expect(request.url.path, '/api/profiles/business');
        return http.Response(
          '{"id":"profile-9","userId":"user-1","businessName":"Klippr Cafe",'
          '"taxId":"20123456789","verificationStatus":"Pending",'
          '"createdAt":"2026-01-01T00:00:00Z","updatedAt":"2026-01-02T00:00:00Z",'
          '"isActive":true}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final store = HttpProfileStore(
        ProfileWebService(ApiClient(client: client, prefs: prefs)),
        prefs: prefs,
      );

      final result = await store.loadBusinessProfile();

      expect(result.dataOrNull?.id.value, 'profile-9');
      expect(result.dataOrNull?.email, 'biz@test.com');
      expect(prefs.profileId, 'profile-9');
    },
  );

  test('profile bloc loads, updates, and submits verification', () async {
    final store = _FakeProfileStore(_profile());
    final bloc = ProfileBloc(store);

    bloc.add(const LoadBusinessProfile());
    await expectLater(
      bloc.stream,
      emitsThrough(
        predicate<ProfileState>(
          (s) => s.profile?.businessName == 'Klippr Cafe',
        ),
      ),
    );

    bloc.add(
      const UpdateBusinessProfileRequested(
        BusinessProfileUpdate(profileId: 'profile-1', businessName: 'Nuevo'),
      ),
    );
    await expectLater(
      bloc.stream,
      emitsThrough(
        predicate<ProfileState>((s) => s.profile?.businessName == 'Nuevo'),
      ),
    );

    bloc.add(
      const SubmitVerificationRequested(
        VerificationDocument(
          profileId: 'profile-1',
          documentUrl: 'https://docs.test/ruc.pdf',
        ),
      ),
    );
    await expectLater(
      bloc.stream,
      emitsThrough(
        predicate<ProfileState>((s) => s.verificationSubmitted == true),
      ),
    );
  });

  testWidgets('profile screen renders profile metrics edit and logout', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => ProfileBloc(_FakeProfileStore(_profile())),
          ),
          BlocProvider(create: (_) => PromotionsBloc(_FakePromotionsStore())),
          BlocProvider(create: (_) => AuthBloc(_FakeAuthStore())),
        ],
        child: MaterialApp(
          home: ProfileScreen(analyticsStore: _FakeAnalyticsStore()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Klippr Cafe'), findsWidgets);
    expect(find.text('biz@test.com'), findsWidgets);
    expect(find.text('Pendiente'), findsWidgets);
    expect(find.text('Promociones'), findsOneWidget);
    expect(find.text('Activas'), findsOneWidget);
    expect(find.text('Canjes'), findsOneWidget);
    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);
  });
}

BusinessProfile _profile({String businessName = 'Klippr Cafe'}) {
  return BusinessProfile(
    id: const Id('profile-1'),
    userId: const Id('user-1'),
    businessName: businessName,
    taxId: '20123456789',
    email: 'biz@test.com',
    role: 'BUSINESS',
    verificationStatus: 'Pending',
    isActive: true,
    createdAt: DateTime.utc(2026, 1),
  );
}

class _FakeProfileStore implements ProfileStore {
  _FakeProfileStore(this.profile);

  BusinessProfile profile;

  @override
  Future<Result<BusinessProfile>> loadBusinessProfile() async =>
      Success(profile);

  @override
  Future<Result<BusinessProfile>> updateBusinessProfile(
    BusinessProfileUpdate update,
  ) async {
    profile = profile.copyWith(businessName: update.businessName);
    return Success(profile);
  }

  @override
  Future<Result<void>> submitVerification(
    VerificationDocument document,
  ) async => const Success(null);
}

class _FakeAnalyticsStore implements AnalyticsStore {
  @override
  Future<Result<BusinessDashboardMetrics>> loadDashboard(
    String businessId,
  ) async => const Success(
    BusinessDashboardMetrics(
      businessId: 'user-1',
      totalPromotions: 4,
      activePromotions: 2,
      totalRedemptions: 18,
      usedRedemptions: 10,
      views: 0,
      averageRating: 0,
    ),
  );

  @override
  Future<Result<int>> loadPromotionRedemptions(
    String businessId,
    String promotionId,
  ) async => const Success(9);

  @override
  Future<Result<Map<String, int>>> loadPromotionRedemptionCounts(
    String businessId,
  ) async => const Success({'promo-1': 9});

  @override
  Future<Result<CampaignMetrics>> loadCampaignMetrics(
    String campaignId,
  ) async => Success(
    CampaignMetrics(
      campaignId: campaignId,
      businessId: 'user-1',
      views: 0,
      redemptions: 0,
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

class _FakePromotionsStore implements PromotionsStore {
  @override
  Future<Result<List<Promotion>>> loadMine() async => Success([
    Promotion(
      id: const Id('promo-1'),
      businessId: const Id('user-1'),
      title: 'Promo',
      description: 'Promo',
      discountAmount: 10,
      discountType: DiscountType.percentage,
      startDate: DateTime.utc(2026, 1),
      endDate: DateTime.utc(2027, 1),
      status: PromotionStatus.published,
      isActive: true,
    ),
  ]);

  @override
  Future<Result<List<Promotion>>> loadActiveMine() async => loadMine();

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
  }) async => const Success('promo-1');

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

class _FakeAuthStore implements AuthenticationStore {
  @override
  Future<Result<AuthenticatedUser>> signIn(
    String email,
    String password,
  ) async => Failure(UnauthorizedException());

  @override
  Future<Result<AuthenticatedUser>> signUpBusiness({
    required String email,
    required String password,
    required String businessName,
    required String taxId,
  }) async => Failure(UnauthorizedException());

  @override
  Future<Result<void>> forgotPassword(String email) async =>
      const Success(null);

  @override
  Future<Result<void>> resetPassword(String email, String newPassword) async =>
      const Success(null);

  @override
  Future<void> signOut() async {}
}
