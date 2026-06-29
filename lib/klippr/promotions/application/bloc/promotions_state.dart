import '../../domain/models/promotion.dart';

// author: Samuel Bonifacio
//
// Estado del BLoC de Promotions: listas del negocio, contadores y flags de UI.

const Object _unset = Object();

class PromotionsState {
  const PromotionsState({
    this.isLoading = false,
    this.promotions = const [],
    this.activePromotions = const [],
    this.error,
    this.activeError,
    this.actionMessage,
    this.actionInProgress = false,
    this.isActiveLoading = false,
    this.isFetchingPromotion = false,
    this.actionOk = false,
    this.promotionToEdit,
  });

  final bool isLoading;
  final List<Promotion> promotions;
  final List<Promotion> activePromotions;
  final String? error;
  final String? activeError;
  final String? actionMessage;

  final bool actionInProgress;
  final bool isActiveLoading;
  final bool isFetchingPromotion;
  final bool actionOk;
  final Promotion? promotionToEdit;

  int get total => promotions.length;
  int get activos => promotions.where((p) => p.isActive).length;
  int get expiradas => promotions.where((p) => p.isExpired).length;

  int get actividad =>
      promotions.where((p) => p.status == PromotionStatus.published).length;

  bool get isEmpty => !isLoading && promotions.isEmpty && error == null;
  bool get activeIsEmpty =>
      !isActiveLoading && activePromotions.isEmpty && activeError == null;

  PromotionsState copyWith({
    bool? isLoading,
    List<Promotion>? promotions,
    List<Promotion>? activePromotions,
    Object? error = _unset,
    Object? activeError = _unset,
    Object? actionMessage = _unset,
    bool? actionInProgress,
    bool? isActiveLoading,
    bool? isFetchingPromotion,
    bool? actionOk,
    Object? promotionToEdit = _unset,
  }) {
    return PromotionsState(
      isLoading: isLoading ?? this.isLoading,
      promotions: promotions ?? this.promotions,
      activePromotions: activePromotions ?? this.activePromotions,
      error: error == _unset ? this.error : error as String?,
      activeError:
          activeError == _unset ? this.activeError : activeError as String?,
      actionMessage: actionMessage == _unset
          ? this.actionMessage
          : actionMessage as String?,
      actionInProgress: actionInProgress ?? this.actionInProgress,
      isActiveLoading: isActiveLoading ?? this.isActiveLoading,
      isFetchingPromotion: isFetchingPromotion ?? this.isFetchingPromotion,
      actionOk: actionOk ?? this.actionOk,
      promotionToEdit: promotionToEdit == _unset
          ? this.promotionToEdit
          : promotionToEdit as Promotion?,
    );
  }
}
