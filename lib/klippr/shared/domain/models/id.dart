// author: Samuel Bonifacio
//
// Identificador universal, agnóstico de framework, reusable por cualquier
// bounded context. Envolver un String crudo evita mezclar accidentalmente
// identificadores no relacionados (pasar un id de negocio donde se espera
// un id de promoción) y centraliza la evolución futura de la semántica del
// identificador. Pertenece al dominio compartido: sin anotaciones, sin
// tokens de serialización, sin dependencias de infraestructura.

/// Identificador de dominio, agnóstico de la fuente de datos.
class Id {
  /// Crea un [Id] a partir de su valor crudo [value].
  const Id(this.value);

  /// Crea un [Id] vacío, útil como placeholder no nulo.
  const Id.empty() : value = '';

  /// El identificador crudo subyacente.
  final String value;

  /// True si este identificador no tiene valor.
  bool get isEmpty => value.isEmpty;

  /// True si este identificador tiene valor.
  bool get isNotEmpty => value.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Id && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
