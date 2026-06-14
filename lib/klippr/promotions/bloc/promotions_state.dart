import '../models/promotion.dart';

// author: Samuel Bonifacio
//
// Estado del BLoC de Promotions: lista del negocio + contadores del dashboard.

/// Centinela para distinguir "no pasado" de "pasado como null" en copyWith.
const Object _unset = Object();

/// Estado inmutable de las promociones del negocio.
class PromotionsState {
  const PromotionsState({
    this.isLoading = false,
    this.promotions = const [],
    this.error,
    this.actionInProgress = false,
    this.actionOk = false,
  });

  final bool isLoading;
  final List<Promotion> promotions;
  final String? error;

  /// True mientras corre una mutación (crear/editar/eliminar/publicar/cancelar).
  final bool actionInProgress;

  /// True cuando la última mutación terminó OK (gatilla navegación/refresh).
  final bool actionOk;

  // Contadores del dashboard.
  int get total => promotions.length;
  int get activos => promotions.where((p) => p.isActive).length;
  int get expiradas => promotions.where((p) => p.isExpired).length;

  /// Actividad: promociones publicadas (el backend no expone métrica de
  /// redenciones en este endpoint).
  int get actividad =>
      promotions.where((p) => p.status == PromotionStatus.published).length;

  bool get isEmpty => !isLoading && promotions.isEmpty && error == null;

  PromotionsState copyWith({
    bool? isLoading,
    List<Promotion>? promotions,
    Object? error = _unset,
    bool? actionInProgress,
    bool? actionOk,
  }) {
    return PromotionsState(
      isLoading: isLoading ?? this.isLoading,
      promotions: promotions ?? this.promotions,
      error: error == _unset ? this.error : error as String?,
      actionInProgress: actionInProgress ?? this.actionInProgress,
      actionOk: actionOk ?? this.actionOk,
    );
  }
}
