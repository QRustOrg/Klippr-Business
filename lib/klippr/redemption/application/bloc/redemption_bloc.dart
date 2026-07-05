import 'package:bloc/bloc.dart';

import '../../domain/stores/redemption_store.dart';
import 'redemption_event.dart';
import 'redemption_state.dart';

// author: Samuel Bonifacio
//
// BLoC de Redemption. La lógica de red vive detrás del puerto
// [RedemptionStore] (hexagonal).

class RedemptionBloc extends Bloc<RedemptionEvent, RedemptionState> {
  /// Crea un [RedemptionBloc] vinculado al puerto [RedemptionStore].
  RedemptionBloc(this._store) : super(const RedemptionState()) {
    on<LookupToken>(_onLookup);
    on<ConfirmToken>(_onConfirm);
    on<ConfirmRedemptionById>(_onConfirmById);
    on<LoadHistory>(_onLoadHistory);
    on<ResetLookup>(_onReset);
    on<RedemptionFlagsConsumed>(_onConsumeFlags);
  }

  final RedemptionStore _store;

  Future<void> _onLookup(LookupToken e, Emitter<RedemptionState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    final res = await _store.lookupToken(e.uniqueToken);
    res.when(
      onSuccess: (redemption) => emit(
        state.copyWith(
          isLoading: false,
          foundRedemption: redemption,
          error: null,
        ),
      ),
      onFailure: (err) => emit(
        state.copyWith(isLoading: false, error: _friendlyError(err.message)),
      ),
    );
  }

  Future<void> _onConfirm(ConfirmToken e, Emitter<RedemptionState> emit) async {
    emit(state.copyWith(isConfirming: true, error: null, successMessage: null));
    final res = await _store.confirmToken(e.uniqueToken);
    res.when(
      onSuccess: (redemption) => emit(
        state.copyWith(
          isConfirming: false,
          confirmedRedemption: redemption,
          actionOk: true,
          successMessage: 'Redemption confirmed successfully',
          error: null,
        ),
      ),
      onFailure: (err) => emit(
        state.copyWith(isConfirming: false, error: _friendlyError(err.message)),
      ),
    );
  }

  Future<void> _onConfirmById(
    ConfirmRedemptionById e,
    Emitter<RedemptionState> emit,
  ) async {
    emit(state.copyWith(isConfirming: true, error: null, successMessage: null));
    final res = await _store.confirmById(e.redemptionId);
    res.when(
      onSuccess: (redemption) => emit(
        state.copyWith(
          isConfirming: false,
          confirmedRedemption: redemption,
          actionOk: true,
          successMessage: 'Canje confirmado correctamente',
          error: null,
        ),
      ),
      onFailure: (err) => emit(
        state.copyWith(isConfirming: false, error: _friendlyError(err.message)),
      ),
    );
  }

  Future<void> _onLoadHistory(
    LoadHistory e,
    Emitter<RedemptionState> emit,
  ) async {
    emit(state.copyWith(isHistoryLoading: true, error: null));
    final res = await _store.loadHistory(e.promotionId);
    res.when(
      onSuccess: (list) => emit(
        state.copyWith(isHistoryLoading: false, history: list, error: null),
      ),
      onFailure: (err) =>
          emit(state.copyWith(isHistoryLoading: false, error: err.message)),
    );
  }

  void _onReset(ResetLookup e, Emitter<RedemptionState> emit) {
    emit(
      state.copyWith(
        foundRedemption: null,
        confirmedRedemption: null,
        actionOk: false,
        successMessage: null,
        error: null,
      ),
    );
  }

  void _onConsumeFlags(
    RedemptionFlagsConsumed e,
    Emitter<RedemptionState> emit,
  ) {
    emit(state.copyWith(error: null, successMessage: null, actionOk: false));
  }

  String _friendlyError(String raw) {
    final value = raw.toLowerCase();
    if (value.contains('used') ||
        value.contains('redeemed') ||
        value.contains('ya fue') ||
        value.contains('already')) {
      return 'Este canje ya fue usado.';
    }
    if (value.contains('expired') || value.contains('expir')) {
      return 'Este canje expiró.';
    }
    if (value.contains('not found') ||
        value.contains('no encontrado') ||
        value.contains('invalid') ||
        value.contains('invalido') ||
        value.contains('inválido')) {
      return 'Código de canje inválido.';
    }
    return raw;
  }
}
