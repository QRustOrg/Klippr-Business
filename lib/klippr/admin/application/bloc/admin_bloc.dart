import 'package:bloc/bloc.dart';

import '../../domain/stores/admin_analytics_store.dart';
import '../../domain/stores/admin_profile_store.dart';
import '../../domain/stores/admin_promotions_store.dart';
import 'admin_event.dart';
import 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  AdminBloc({
    required AdminPromotionsStore promotionsStore,
    required AdminProfileStore profileStore,
    required AdminAnalyticsStore analyticsStore,
  })  : _promotionsStore = promotionsStore,
        _profileStore = profileStore,
        _analyticsStore = analyticsStore,
        super(const AdminState()) {
    on<LoadAdminData>(_onLoadAdminData);
    on<LoadPendingVerifications>(_onLoadPendingVerifications);
    on<ApproveVerificationRequested>(_onApproveVerification);
    on<RejectVerificationRequested>(_onRejectVerification);
    on<TakedownPromotionRequested>(_onTakedownPromotion);
    on<DeletePromotionRequested>(_onDeletePromotion);
    on<DeactivateProfileRequested>(_onDeactivateProfile);
    on<ReactivateProfileRequested>(_onReactivateProfile);
    on<UpdateAbuseReportStatusRequested>(_onUpdateAbuseReportStatus);
    on<AdminErrorConsumed>(_onConsumeError);
    on<AdminMessageConsumed>(_onConsumeMessage);
  }

  final AdminPromotionsStore _promotionsStore;
  final AdminProfileStore _profileStore;
  final AdminAnalyticsStore _analyticsStore;

  Future<void> _onLoadAdminData(
    LoadAdminData event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    final verificationsRes = await _profileStore.getPendingVerifications();
    final promotionsRes = await _promotionsStore.getAllPromotions();
    final analyticsRes = await _analyticsStore.getPlatformAnalytics();
    final abuseReportsRes = await _analyticsStore.getAbuseReports();

    verificationsRes.when(
      onSuccess: (profiles) =>
          emit(state.copyWith(pendingVerifications: profiles)),
      onFailure: (e) => emit(state.copyWith(error: e.message)),
    );

    promotionsRes.when(
      onSuccess: (promotions) =>
          emit(state.copyWith(allPromotions: promotions)),
      onFailure: (e) => emit(state.copyWith(error: e.message)),
    );

    analyticsRes.when(
      onSuccess: (analytics) =>
          emit(state.copyWith(platformAnalytics: analytics)),
      onFailure: (e) => emit(state.copyWith(error: e.message)),
    );

    abuseReportsRes.when(
      onSuccess: (reports) => emit(state.copyWith(abuseReports: reports)),
      onFailure: (e) => emit(state.copyWith(error: e.message)),
    );

    emit(state.copyWith(isLoading: false));
  }

  Future<void> _onLoadPendingVerifications(
    LoadPendingVerifications event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    final res = await _profileStore.getPendingVerifications(
      pageNumber: event.pageNumber,
      pageSize: event.pageSize,
    );
    res.when(
      onSuccess: (profiles) => emit(
        state.copyWith(isLoading: false, pendingVerifications: profiles),
      ),
      onFailure: (e) => emit(state.copyWith(isLoading: false, error: e.message)),
    );
  }

  Future<void> _onApproveVerification(
    ApproveVerificationRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    final res = await _profileStore.approveVerification(event.profileId);
    res.when(
      onSuccess: (_) {
        emit(state.copyWith(
          isLoading: false,
          actionMessage: 'Verificación aprobada correctamente',
        ));
        add(const LoadPendingVerifications());
      },
      onFailure: (e) => emit(state.copyWith(isLoading: false, error: e.message)),
    );
  }

  Future<void> _onRejectVerification(
    RejectVerificationRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    final res = await _profileStore.rejectVerification(event.profileId);
    res.when(
      onSuccess: (_) {
        emit(state.copyWith(
          isLoading: false,
          actionMessage: 'Verificación rechazada',
        ));
        add(const LoadPendingVerifications());
      },
      onFailure: (e) => emit(state.copyWith(isLoading: false, error: e.message)),
    );
  }

  Future<void> _onTakedownPromotion(
    TakedownPromotionRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    final res = await _promotionsStore.takedownPromotion(event.promotionId);
    res.when(
      onSuccess: (_) {
        emit(state.copyWith(
          isLoading: false,
          actionMessage: 'Promoción dada de baja',
        ));
        add(const LoadAdminData());
      },
      onFailure: (e) => emit(state.copyWith(isLoading: false, error: e.message)),
    );
  }

  Future<void> _onDeletePromotion(
    DeletePromotionRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    final res = await _promotionsStore.deletePromotion(event.promotionId);
    res.when(
      onSuccess: (_) {
        emit(state.copyWith(
          isLoading: false,
          actionMessage: 'Promoción eliminada permanentemente',
        ));
        add(const LoadAdminData());
      },
      onFailure: (e) => emit(state.copyWith(isLoading: false, error: e.message)),
    );
  }

  Future<void> _onDeactivateProfile(
    DeactivateProfileRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    final res = await _profileStore.deactivateProfile(event.profileId);
    res.when(
      onSuccess: (_) {
        emit(state.copyWith(
          isLoading: false,
          actionMessage: 'Perfil desactivado',
        ));
        add(const LoadPendingVerifications());
      },
      onFailure: (e) => emit(state.copyWith(isLoading: false, error: e.message)),
    );
  }

  Future<void> _onReactivateProfile(
    ReactivateProfileRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    final res = await _profileStore.reactivateProfile(event.profileId);
    res.when(
      onSuccess: (_) {
        emit(state.copyWith(
          isLoading: false,
          actionMessage: 'Perfil reactivado',
        ));
        add(const LoadPendingVerifications());
      },
      onFailure: (e) => emit(state.copyWith(isLoading: false, error: e.message)),
    );
  }

  Future<void> _onUpdateAbuseReportStatus(
    UpdateAbuseReportStatusRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    final res = await _analyticsStore.updateAbuseReportStatus(
      event.reportId,
      event.status,
    );
    res.when(
      onSuccess: (_) {
        emit(state.copyWith(
          isLoading: false,
          actionMessage: 'Estado del reporte actualizado',
        ));
        add(const LoadAdminData());
      },
      onFailure: (e) => emit(state.copyWith(isLoading: false, error: e.message)),
    );
  }

  void _onConsumeError(AdminErrorConsumed event, Emitter<AdminState> emit) {
    emit(state.copyWith(error: null));
  }

  void _onConsumeMessage(
    AdminMessageConsumed event,
    Emitter<AdminState> emit,
  ) {
    emit(state.copyWith(actionMessage: null));
  }
}
