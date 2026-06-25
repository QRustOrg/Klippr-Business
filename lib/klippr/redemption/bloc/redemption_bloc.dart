import 'package:bloc/bloc.dart';

import '../repository/redemption_repository.dart';
import 'redemption_event.dart';
import 'redemption_state.dart';

class RedemptionBloc extends Bloc<RedemptionEvent, RedemptionState> {
  RedemptionBloc(this._repo) : super(const RedemptionState()) {
    on<LookupToken>(_onLookup);
    on<ConfirmToken>(_onConfirm);
    on<LoadHistory>(_onLoadHistory);
    on<ResetLookup>(_onReset);
    on<RedemptionFlagsConsumed>(_onConsumeFlags);
  }

  final RedemptionRepository _repo;

  Future<void> _onLookup(
    LookupToken e,
    Emitter<RedemptionState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    final res = await _repo.lookupToken(e.uniqueToken);
    res.when(
      onSuccess: (redemption) => emit(
        state.copyWith(
          isLoading: false,
          foundRedemption: redemption,
          error: null,
        ),
      ),
      onFailure: (err) => emit(
        state.copyWith(isLoading: false, error: err.message),
      ),
    );
  }

  Future<void> _onConfirm(
    ConfirmToken e,
    Emitter<RedemptionState> emit,
  ) async {
    emit(state.copyWith(isConfirming: true, error: null, successMessage: null));
    final res = await _repo.confirmToken(e.uniqueToken);
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
        state.copyWith(isConfirming: false, error: err.message),
      ),
    );
  }

  Future<void> _onLoadHistory(
    LoadHistory e,
    Emitter<RedemptionState> emit,
  ) async {
    emit(state.copyWith(isHistoryLoading: true, error: null));
    final res = await _repo.loadHistory(e.promotionId);
    res.when(
      onSuccess: (list) => emit(
        state.copyWith(isHistoryLoading: false, history: list, error: null),
      ),
      onFailure: (err) => emit(
        state.copyWith(isHistoryLoading: false, error: err.message),
      ),
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
}
