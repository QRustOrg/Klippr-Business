// Shared local image catalog for promotion cards.
//
// Keep these keys stable: the backend stores only imageKey and both Business
// and Consumer resolve that key to an asset bundled in the app.

class PromotionImageOption {
  const PromotionImageOption({
    required this.key,
    required this.categoryKey,
    required this.label,
    required this.assetPath,
  });

  final String key;
  final String categoryKey;
  final String label;
  final String assetPath;
}

class PromotionImageCatalog {
  const PromotionImageCatalog._();

  static const fallback = PromotionImageOption(
    key: 'comida_hamburguesas',
    categoryKey: 'food',
    label: 'Hamburguesas',
    assetPath: 'assets/images/promotions/comida_hamburguesas.png',
  );

  static const options = <PromotionImageOption>[
    PromotionImageOption(
      key: 'comida_pizza',
      categoryKey: 'food',
      label: 'Pizza',
      assetPath: 'assets/images/promotions/comida_pizza.png',
    ),
    fallback,
    PromotionImageOption(
      key: 'comida_pollo_frito',
      categoryKey: 'food',
      label: 'Pollo frito',
      assetPath: 'assets/images/promotions/comida_pollo_frito.png',
    ),
    PromotionImageOption(
      key: 'comida_ceviche',
      categoryKey: 'food',
      label: 'Ceviche',
      assetPath: 'assets/images/promotions/comida_ceviche.png',
    ),
    PromotionImageOption(
      key: 'salud_pastillas',
      categoryKey: 'health',
      label: 'Pastillas',
      assetPath: 'assets/images/promotions/salud_pastillas.png',
    ),
    PromotionImageOption(
      key: 'salud_medicamentos',
      categoryKey: 'health',
      label: 'Medicamentos',
      assetPath: 'assets/images/promotions/salud_medicamentos.png',
    ),
    PromotionImageOption(
      key: 'entretenimiento_cine',
      categoryKey: 'entertainment',
      label: 'Cine',
      assetPath: 'assets/images/promotions/entretenimiento_cine.png',
    ),
    PromotionImageOption(
      key: 'entretenimiento_bolos',
      categoryKey: 'entertainment',
      label: 'Bolos',
      assetPath: 'assets/images/promotions/entretenimiento_bolos.png',
    ),
    PromotionImageOption(
      key: 'entretenimiento_bares',
      categoryKey: 'entertainment',
      label: 'Bares',
      assetPath: 'assets/images/promotions/entretenimiento_bares.png',
    ),
    PromotionImageOption(
      key: 'entretenimiento_cibercafe',
      categoryKey: 'entertainment',
      label: 'Cibercafe',
      assetPath: 'assets/images/promotions/entretenimiento_cibercafe.png',
    ),
    PromotionImageOption(
      key: 'deportes_futbol',
      categoryKey: 'sports',
      label: 'Futbol',
      assetPath: 'assets/images/promotions/deportes_futbol.png',
    ),
    PromotionImageOption(
      key: 'deportes_volley',
      categoryKey: 'sports',
      label: 'Volley',
      assetPath: 'assets/images/promotions/deportes_volley.png',
    ),
    PromotionImageOption(
      key: 'deportes_basket',
      categoryKey: 'sports',
      label: 'Basket',
      assetPath: 'assets/images/promotions/deportes_basket.png',
    ),
  ];

  /// Resuelve un asset local a partir de la key del backend.
  ///
  /// Si [key] es null/vacía o no existe en el catálogo, devuelve
  /// [fallback] (`comida_hamburguesas`) — por eso se ven hamburguesas
  /// cuando el GET no trae `imageKey` o trae un valor desconocido.
  static PromotionImageOption byKey(String? key) {
    final normalized = normalizeKey(key);
    if (normalized == null) return fallback;

    for (final option in options) {
      if (option.key == normalized) return option;
    }
    // Match flexible: paths, casing o subcadenas ("pizza", "comida_pizza.png").
    for (final option in options) {
      final optionKey = option.key;
      if (normalized.contains(optionKey) || optionKey.contains(normalized)) {
        return option;
      }
    }
    return fallback;
  }

  /// Normaliza una key cruda del backend (path, extensión, casing).
  static String? normalizeKey(String? key) {
    if (key == null) return null;
    var value = key.trim();
    if (value.isEmpty || value.toLowerCase() == 'null') return null;
    if (value.contains('/')) value = value.split('/').last;
    if (value.contains(r'\')) value = value.split(r'\').last;
    final dot = value.lastIndexOf('.');
    if (dot > 0) value = value.substring(0, dot);
    value = value.trim().toLowerCase();
    return value.isEmpty ? null : value;
  }

  /// Lee imageKey desde varias formas del JSON del backend.
  static String? readKeyFromJson(Map<String, dynamic> json) {
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

  static List<PromotionImageOption> byCategory(String categoryKey) {
    final matches =
        options.where((option) => option.categoryKey == categoryKey).toList();
    return matches.isEmpty ? options : matches;
  }
}
