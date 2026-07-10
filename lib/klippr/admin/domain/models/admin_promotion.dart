import '../../../shared/domain/models/id.dart';

/// Promoción tal como la devuelve GET /api/promotions (body completo).
class AdminPromotion {
  const AdminPromotion({
    required this.id,
    required this.businessId,
    this.businessName = '',
    required this.title,
    this.description = '',
    this.discountAmount = 0,
    this.discountType = '',
    this.startDate,
    this.endDate,
    this.redemptionCap,
    this.imageKey,
    this.status = '',
    this.isActive = true,
  });

  final Id id;
  final Id businessId;
  final String businessName;
  final String title;
  final String description;
  final double discountAmount;
  final String discountType;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? redemptionCap;
  final String? imageKey;
  final String status;
  final bool isActive;

  /// Etiqueta del descuento ("50% OFF" / "S/ 10 OFF").
  String get discountLabel {
    final amount = discountAmount.toStringAsFixed(
      discountAmount == discountAmount.roundToDouble() ? 0 : 2,
    );
    final type = discountType.toLowerCase();
    if (type.contains('fixed') || type.contains('fijo')) {
      return 'S/ $amount OFF';
    }
    return '$amount% OFF';
  }

  /// Estado legible en español (status del backend o Activa/Inactiva).
  String get statusLabel {
    final raw = status.trim().toLowerCase();
    if (raw.isEmpty) return isActive ? 'Activa' : 'Inactiva';
    return switch (raw) {
      'draft' || 'borrador' => 'Borrador',
      'published' || 'publicada' => isActive ? 'Activa' : 'Publicada',
      'cancelled' || 'canceled' || 'cancelada' => 'Cancelada',
      'expired' || 'expirada' => 'Expirada',
      _ => status,
    };
  }

  bool get isExpired {
    final raw = status.trim().toLowerCase();
    if (raw == 'expired' || raw == 'expirada') return true;
    return endDate != null && endDate!.isBefore(DateTime.now());
  }

  factory AdminPromotion.fromJson(Map<String, dynamic> json) {
    return AdminPromotion(
      id: Id(json['promotionId']?.toString() ?? json['id']?.toString() ?? ''),
      businessId: Id(json['businessId']?.toString() ?? ''),
      businessName: json['businessName']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      discountType: json['discountType']?.toString() ?? '',
      startDate: _parseDate(json['startDate']),
      endDate: _parseDate(json['endDate']),
      redemptionCap: (json['redemptionCap'] as num?)?.toInt(),
      imageKey: _readImageKey(json),
      status: json['status']?.toString() ?? json['Status']?.toString() ?? '',
      isActive: json['isActive'] as bool? ?? json['IsActive'] as bool? ?? true,
    );
  }

  /// Acepta imageKey / ImageKey / promotionImage / etc. del body del GET.
  static String? _readImageKey(Map<String, dynamic> json) {
    const candidates = <String>[
      'imageKey',
      'ImageKey',
      'image_key',
      'promotionImage',
      'PromotionImage',
      'image',
      'Image',
    ];
    for (final field in candidates) {
      final raw = json[field];
      if (raw == null) continue;
      final text = raw.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return null;
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw == null) return null;
    if (raw is int) {
      // epoch ms o s
      final ms = raw > 9999999999 ? raw : raw * 1000;
      return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
    }
    final text = raw.toString().trim();
    if (text.isEmpty) return null;
    return DateTime.tryParse(text)?.toLocal();
  }
}
