// author: Samuel Bonifacio
//
// Cuerpo de POST /api/promotions/{id}/publish.

/// Petición de publicación de una promoción.
class PublishRequest {
  /// Crea un [PublishRequest].
  const PublishRequest({required this.isBusinessVerified});

  final bool isBusinessVerified;

  /// Serializa esta petición a un mapa JSON-compatible.
  Map<String, dynamic> toJson() => {'isBusinessVerified': isBusinessVerified};
}
