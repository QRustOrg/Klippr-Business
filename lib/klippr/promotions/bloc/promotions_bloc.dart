import 'package:bloc/bloc.dart';

import '../../core/utils/result.dart';
import '../repository/promotions_repository.dart';
import 'promotions_event.dart';
import 'promotions_state.dart';

// author: Samuel Bonifacio
//
// BLoC de Promotions. Orquesta listado, activas, edicion fresca y mutaciones.

class PromotionsBloc extends Bloc<PromotionsEvent, PromotionsState> {
  PromotionsBloc(this._repo) : super(const PromotionsState()) {
    on<LoadPromotions>(_onLoad);
    on<LoadActivePromotions>(_onLoadActive);
    on<FetchPromotionForEdit>(_onFetchForEdit);
    on<CreatePromotion>(_onCreate);
    on<UpdatePromotion>(_onUpdate);
    on<DeletePromotion>(_onDelete);
    on<PublishPromotion>(_onPublish);
    on<CancelPromotion>(_onCancel);
    on<PromotionsFlagsConsumed>(_onConsumeFlags);
    on<PromotionEditConsumed>(_onConsumeEdit);
  }

  final PromotionsRepository _repo;

  Future<void> _onLoad(LoadPromotions e, Emitter<PromotionsState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    final res = await _repo.loadMine();
    res.when(
      onSuccess: (list) => emit(
        state.copyWith(isLoading: false, promotions: list, error: null),
      ),
      onFailure: (err) =>
          emit(state.copyWith(isLoading: false, error: err.message)),
    );
  }

  Future<void> _onLoadActive(
    LoadActivePromotions e,
    Emitter<PromotionsState> emit,
  ) async {
    emit(state.copyWith(isActiveLoading: true, activeError: null));
    final res = await _repo.loadActiveMine();
    res.when(
      onSuccess: (list) => emit(
        state.copyWith(
          isActiveLoading: false,
          activePromotions: list,
          activeError: null,
        ),
      ),
      onFailure: (err) => emit(
        state.copyWith(isActiveLoading: false, activeError: err.message),
      ),
    );
  }

  Future<void> _onFetchForEdit(
    FetchPromotionForEdit e,
    Emitter<PromotionsState> emit,
  ) async {
    emit(state.copyWith(
      isFetchingPromotion: true,
      promotionToEdit: null,
      error: null,
    ));
    final res = await _repo.getById(e.id);
    res.when(
      onSuccess: (promotion) => emit(
        state.copyWith(
          isFetchingPromotion: false,
          promotionToEdit: promotion,
          error: null,
        ),
      ),
      onFailure: (err) => emit(
        state.copyWith(isFetchingPromotion: false, error: err.message),
      ),
    );
  }

  Future<void> _onCreate(
    CreatePromotion e,
    Emitter<PromotionsState> emit,
  ) async {
    await _runAction(
      emit,
      () => _repo.create(
        title: e.title,
        description: e.description,
        discountAmount: e.discountAmount,
        discountType: e.discountType,
        startDate: e.startDate,
        endDate: e.endDate,
        imageKey: e.imageKey,
        redemptionCap: e.redemptionCap,
      ),
      successMessage: 'Promocion creada.',
    );
  }

  Future<void> _onUpdate(
    UpdatePromotion e,
    Emitter<PromotionsState> emit,
  ) async {
    await _runAction(
      emit,
      () => _repo.update(
        e.id,
        title: e.title,
        description: e.description,
        discountAmount: e.discountAmount,
        discountType: e.discountType,
        startDate: e.startDate,
        endDate: e.endDate,
        imageKey: e.imageKey,
        redemptionCap: e.redemptionCap,
      ),
      successMessage: 'Promocion actualizada.',
    );
  }

  Future<void> _onDelete(DeletePromotion e, Emitter<PromotionsState> emit) =>
      _runAction(
        emit,
        () => _repo.delete(e.id),
        successMessage: 'Promocion eliminada.',
      );

  Future<void> _onPublish(PublishPromotion e, Emitter<PromotionsState> emit) =>
      _runAction(
        emit,
        () => _repo.publish(e.id),
        successMessage: 'Promocion publicada.',
      );

  Future<void> _onCancel(CancelPromotion e, Emitter<PromotionsState> emit) =>
      _runAction(
        emit,
        () => _repo.cancel(e.id),
        successMessage: 'Promocion cancelada.',
      );

  void _onConsumeFlags(
    PromotionsFlagsConsumed e,
    Emitter<PromotionsState> emit,
  ) {
    emit(state.copyWith(
      actionOk: false,
      error: null,
      activeError: null,
      actionMessage: null,
    ));
  }

  void _onConsumeEdit(
    PromotionEditConsumed e,
    Emitter<PromotionsState> emit,
  ) {
    emit(state.copyWith(promotionToEdit: null));
  }

  Future<void> _runAction(
    Emitter<PromotionsState> emit,
    Future<Result<dynamic>> Function() action, {
    required String successMessage,
  }) async {
    emit(state.copyWith(
      actionInProgress: true,
      error: null,
      activeError: null,
      actionMessage: null,
      actionOk: false,
    ));
    final res = await action();
    final failure = res.errorOrNull;
    if (failure != null) {
      emit(state.copyWith(
        actionInProgress: false,
        error: failure.message,
      ));
      return;
    }

    final promotions = await _repo.loadMine();
    final active = await _repo.loadActiveMine();
    emit(state.copyWith(
      actionInProgress: false,
      actionOk: true,
      actionMessage: successMessage,
      promotions: promotions.dataOrNull ?? state.promotions,
      activePromotions: active.dataOrNull ?? state.activePromotions,
      error: promotions.errorOrNull?.message,
      activeError: active.errorOrNull?.message,
    ));
  }
}
