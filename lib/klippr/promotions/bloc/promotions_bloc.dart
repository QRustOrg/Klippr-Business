import 'package:bloc/bloc.dart';

import '../../core/utils/result.dart';
import '../repository/promotions_repository.dart';
import 'promotions_event.dart';
import 'promotions_state.dart';

// author: Samuel Bonifacio
//
// BLoC de Promotions. Orquesta listado y mutaciones (crear/editar/eliminar/
// publicar/cancelar); tras cada mutación exitosa recarga la lista.

/// Maneja el estado de las promociones del negocio.
class PromotionsBloc extends Bloc<PromotionsEvent, PromotionsState> {
  PromotionsBloc(this._repo) : super(const PromotionsState()) {
    on<LoadPromotions>(_onLoad);
    on<CreatePromotion>(_onCreate);
    on<UpdatePromotion>(_onUpdate);
    on<DeletePromotion>(_onDelete);
    on<PublishPromotion>(_onPublish);
    on<CancelPromotion>(_onCancel);
    on<PromotionsFlagsConsumed>(_onConsumeFlags);
  }

  final PromotionsRepository _repo;

  Future<void> _onLoad(LoadPromotions e, Emitter<PromotionsState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    final res = await _repo.loadMine();
    res.when(
      onSuccess: (list) =>
          emit(state.copyWith(isLoading: false, promotions: list)),
      onFailure: (err) =>
          emit(state.copyWith(isLoading: false, error: err.message)),
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
        redemptionCap: e.redemptionCap,
      ),
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
        redemptionCap: e.redemptionCap,
      ),
    );
  }

  Future<void> _onDelete(DeletePromotion e, Emitter<PromotionsState> emit) =>
      _runAction(emit, () => _repo.delete(e.id));

  Future<void> _onPublish(PublishPromotion e, Emitter<PromotionsState> emit) =>
      _runAction(emit, () => _repo.publish(e.id));

  Future<void> _onCancel(CancelPromotion e, Emitter<PromotionsState> emit) =>
      _runAction(emit, () => _repo.cancel(e.id));

  void _onConsumeFlags(
    PromotionsFlagsConsumed e,
    Emitter<PromotionsState> emit,
  ) {
    emit(state.copyWith(actionOk: false, error: null));
  }

  /// Ejecuta una mutación, emite progreso/errores y recarga la lista al éxito.
  Future<void> _runAction(
    Emitter<PromotionsState> emit,
    Future<Result<dynamic>> Function() action,
  ) async {
    emit(state.copyWith(actionInProgress: true, error: null, actionOk: false));
    final res = await action();
    final failure = res.errorOrNull;
    if (failure != null) {
      emit(state.copyWith(actionInProgress: false, error: failure.message));
      return;
    }
    // Éxito → recargar lista y marcar acción OK.
    final reload = await _repo.loadMine();
    emit(state.copyWith(
      actionInProgress: false,
      actionOk: true,
      promotions: reload.dataOrNull ?? state.promotions,
    ));
  }
}
