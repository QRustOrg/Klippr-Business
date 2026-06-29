import '../../domain/models/redemption.dart';

const Object _unset = Object();

class RedemptionState {
  const RedemptionState({
    this.isLoading = false,
    this.isConfirming = false,
    this.isHistoryLoading = false,
    this.foundRedemption,
    this.confirmedRedemption,
    this.history = const [],
    this.error,
    this.successMessage,
    this.actionOk = false,
  });

  final bool isLoading;
  final bool isConfirming;
  final bool isHistoryLoading;
  final Redemption? foundRedemption;
  final Redemption? confirmedRedemption;
  final List<Redemption> history;
  final String? error;
  final String? successMessage;
  final bool actionOk;

  RedemptionState copyWith({
    bool? isLoading,
    bool? isConfirming,
    bool? isHistoryLoading,
    Object? foundRedemption = _unset,
    Object? confirmedRedemption = _unset,
    List<Redemption>? history,
    Object? error = _unset,
    Object? successMessage = _unset,
    bool? actionOk,
  }) {
    return RedemptionState(
      isLoading: isLoading ?? this.isLoading,
      isConfirming: isConfirming ?? this.isConfirming,
      isHistoryLoading: isHistoryLoading ?? this.isHistoryLoading,
      foundRedemption:
          foundRedemption == _unset
              ? this.foundRedemption
              : foundRedemption as Redemption?,
      confirmedRedemption:
          confirmedRedemption == _unset
              ? this.confirmedRedemption
              : confirmedRedemption as Redemption?,
      history: history ?? this.history,
      error: error == _unset ? this.error : error as String?,
      successMessage:
          successMessage == _unset
              ? this.successMessage
              : successMessage as String?,
      actionOk: actionOk ?? this.actionOk,
    );
  }
}
