import '../models/promotion.dart';

// author: Samuel Bonifacio
//
// Eventos del BLoC de Promotions.

/// Evento base de promociones.
sealed class PromotionsEvent {
  const PromotionsEvent();
}

/// Carga (o recarga) las promociones del negocio.
class LoadPromotions extends PromotionsEvent {
  const LoadPromotions();
}

/// Carga promociones activas del negocio autenticado.
class LoadActivePromotions extends PromotionsEvent {
  const LoadActivePromotions();
}

/// Obtiene una promocion fresca antes de abrir edicion.
class FetchPromotionForEdit extends PromotionsEvent {
  const FetchPromotionForEdit(this.id);
  final String id;
}

/// Crea una promoción.
class CreatePromotion extends PromotionsEvent {
  const CreatePromotion({
    required this.title,
    required this.description,
    required this.discountAmount,
    required this.discountType,
    required this.startDate,
    required this.endDate,
    required this.imageKey,
    this.redemptionCap,
  });

  final String title;
  final String description;
  final double discountAmount;
  final DiscountType discountType;
  final DateTime startDate;
  final DateTime endDate;
  final String imageKey;
  final int? redemptionCap;
}

/// Actualiza una promoción existente.
class UpdatePromotion extends PromotionsEvent {
  const UpdatePromotion({
    required this.id,
    required this.title,
    required this.description,
    required this.discountAmount,
    required this.discountType,
    required this.startDate,
    required this.endDate,
    required this.imageKey,
    this.redemptionCap,
  });

  final String id;
  final String title;
  final String description;
  final double discountAmount;
  final DiscountType discountType;
  final DateTime startDate;
  final DateTime endDate;
  final String imageKey;
  final int? redemptionCap;
}

/// Elimina una promoción.
class DeletePromotion extends PromotionsEvent {
  const DeletePromotion(this.id);
  final String id;
}

/// Publica una promoción.
class PublishPromotion extends PromotionsEvent {
  const PublishPromotion(this.id);
  final String id;
}

/// Cancela una promoción.
class CancelPromotion extends PromotionsEvent {
  const CancelPromotion(this.id);
  final String id;
}

/// Limpia el error/flag de acción del estado.
class PromotionsFlagsConsumed extends PromotionsEvent {
  const PromotionsFlagsConsumed();
}

/// Limpia la promocion fresca usada para abrir edicion.
class PromotionEditConsumed extends PromotionsEvent {
  const PromotionEditConsumed();
}
