import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/presentation/widgets/dashed_border.dart';
import '../../../shared/presentation/widgets/klippr_bottom_bar.dart';
import '../../application/bloc/promotions_bloc.dart';
import '../../application/bloc/promotions_event.dart';
import '../../application/bloc/promotions_state.dart';
import '../../domain/models/promotion.dart';
import '../navigation/promotions_router.dart';
import '../resources/promotion_image_catalog.dart';
import 'promo_colors.dart';

// author: Samuel Bonifacio
//
// Formulario de creación/edición de promoción ("+ QR"). Port 1:1 de
// CreatePromotionScreen.kt: información, condiciones de uso, código QR y
// acciones. Conectado al PromotionsBloc.
//
// category, condiciones y QR son visuales (el backend no los recibe); solo se
// deriva redemptionCap de la condición "Límite total de usos".

/// Categorías de promoción (solo visual; el backend no las recibe).
enum _PromotionCategory {
  general('General'),
  food('Comida'),
  health('Salud'),
  entertainment('Entretenimiento'),
  sports('Deportes');

  const _PromotionCategory(this.label);
  final String label;

  String get key => switch (this) {
        _PromotionCategory.general => 'general',
        _PromotionCategory.food => 'food',
        _PromotionCategory.health => 'health',
        _PromotionCategory.entertainment => 'entertainment',
        _PromotionCategory.sports => 'sports',
      };
}

/// Tipos de condición de uso.
enum _ConditionType {
  usageLimit('Límite total de usos'),
  minPurchase('Monto Mínimo de Compra'),
  validationHours('Horario de validación'),
  validDays('Días de la semana válidos'),
  validBranches('Sucursales válidas'),
  newClients('Nuevos clientes');

  const _ConditionType(this.label);
  final String label;
}

class _Condition {
  _ConditionType? type;
  String value = '';
}

String _generateQrCode() {
  const hex = '0123456789ABCDEFabcdef';
  final rnd = Random();
  final code = List.generate(12, (_) => hex[rnd.nextInt(hex.length)]).join();
  return 'PROM$code';
}

_PromotionCategory _categoryFromKey(String categoryKey) {
  for (final category in _PromotionCategory.values) {
    if (category.key == categoryKey) return category;
  }
  return _PromotionCategory.general;
}

/// Pantalla de creación/edición de promoción.
class CreatePromotionScreen extends StatefulWidget {
  const CreatePromotionScreen({super.key, this.promotion});

  /// Si se provee, la pantalla entra en modo edición.
  final Promotion? promotion;

  @override
  State<CreatePromotionScreen> createState() => _CreatePromotionScreenState();
}

class _CreatePromotionScreenState extends State<CreatePromotionScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _discount = TextEditingController();
  final _endDate = TextEditingController();

  _PromotionCategory _category = _PromotionCategory.general;
  PromotionImageOption? _selectedImage;
  final List<_Condition> _conditions = [];
  String _qrCode = _generateQrCode();
  DateTime? _endDateValue;

  bool _titleError = false;
  bool _descriptionError = false;
  bool _dateError = false;
  bool _imageError = false;

  bool get _isEdit => widget.promotion != null;

  void _openActivePromotions() {
    final bloc = context.read<PromotionsBloc>();
    Navigator.of(context).push(PromotionsRouter.active(bloc));
  }

  @override
  void initState() {
    super.initState();
    final p = widget.promotion;
    if (p != null) {
      _title.text = p.title;
      _description.text = p.description;
      _discount.text = p.discountLabel;
      _selectedImage = PromotionImageCatalog.byKey(p.imageKey);
      _category = _categoryFromKey(_selectedImage!.categoryKey);
      if (p.endDate != null) {
        _endDateValue = p.endDate;
        _endDate.text = _formatDate(p.endDate!);
      }
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _discount.dispose();
    _endDate.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = (d.year % 100).toString().padLeft(2, '0');
    return '$dd/$mm/$yy';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDateValue ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _endDateValue = picked;
        _endDate.text = _formatDate(picked);
        _dateError = false;
      });
    }
  }

  /// Extrae el primer número del texto de descuento ("Ej: 50% OFF" -> 50).
  double _parseDiscount(String raw) {
    final match = RegExp(r'(\d+([.,]\d+)?)').firstMatch(raw);
    if (match == null) return 0;
    return double.tryParse(match.group(1)!.replaceAll(',', '.')) ?? 0;
  }

  /// redemptionCap derivado de la condición "Límite total de usos".
  int? _redemptionCap() {
    for (final c in _conditions) {
      if (c.type == _ConditionType.usageLimit) {
        final n = int.tryParse(RegExp(r'\d+').firstMatch(c.value)?.group(0) ?? '');
        if (n != null) return n;
      }
    }
    return null;
  }

  void _onCategoryChanged(_PromotionCategory category) {
    final current = _selectedImage;
    setState(() {
      _category = category;
      if (current == null || current.categoryKey != category.key) {
        _selectedImage = null;
      }
      _imageError = false;
    });
  }

  Future<void> _pickPromotionImage() async {
    final options = PromotionImageCatalog.byCategory(_category.key);
    final selected = await showModalBottomSheet<PromotionImageOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _PromotionImagePickerSheet(
        categoryLabel: _category.label,
        options: options,
        selectedKey: _selectedImage?.key,
      ),
    );
    if (selected != null) {
      setState(() {
        _selectedImage = selected;
        _imageError = false;
      });
    }
  }

  void _submit() {
    final titleOk = _title.text.trim().isNotEmpty;
    final descOk = _description.text.trim().isNotEmpty;
    final dateOk = _endDateValue != null;
    final imageOk = _selectedImage != null;
    if (!titleOk || !descOk || !dateOk || !imageOk) {
      setState(() {
        _titleError = !titleOk;
        _descriptionError = !descOk;
        _dateError = !dateOk;
        _imageError = !imageOk;
      });
      return;
    }

    final bloc = context.read<PromotionsBloc>();
    final cap = _redemptionCap();
    final amount = _parseDiscount(_discount.text);
    final start = DateTime.now();

    if (_isEdit) {
      bloc.add(UpdatePromotion(
        id: widget.promotion!.id.value,
        title: _title.text.trim(),
        description: _description.text.trim(),
        discountAmount: amount,
        discountType: DiscountType.percentage,
        startDate: widget.promotion!.startDate ?? start,
        endDate: _endDateValue!,
        imageKey: _selectedImage!.key,
        redemptionCap: cap,
      ));
    } else {
      bloc.add(CreatePromotion(
        title: _title.text.trim(),
        description: _description.text.trim(),
        discountAmount: amount,
        discountType: DiscountType.percentage,
        startDate: start,
        endDate: _endDateValue!,
        imageKey: _selectedImage!.key,
        redemptionCap: cap,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PromotionsBloc, PromotionsState>(
      listener: (context, state) {
        if (state.actionOk) {
          context.read<PromotionsBloc>().add(const PromotionsFlagsConsumed());
          Navigator.of(context).maybePop();
        } else if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!)),
          );
          context.read<PromotionsBloc>().add(const PromotionsFlagsConsumed());
        }
      },
      child: Scaffold(
        backgroundColor: PromoColors.screenBg,
        appBar: AppBar(
          backgroundColor: PromoColors.purple,
          centerTitle: true,
          leading: IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            tooltip: 'Volver',
          ),
          title: const Text(
            '+ QR',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ),
        bottomNavigationBar: KlipprBottomBar(
          current: KlipprTab.qr,
          onQr: () {},
          onInicio: () => Navigator.of(context).maybePop(),
          onMiLista: _openActivePromotions,
        ),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const _SectionHeader(title: 'Información de la Promocion'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('Titulo de la Promoción *', isError: _titleError),
                  _PromoField(
                    controller: _title,
                    hint: 'Ej: 2x1 en todas las pizzas',
                    isError: _titleError,
                    onChanged: (_) {
                      if (_titleError) setState(() => _titleError = false);
                    },
                  ),
                  const SizedBox(height: 16),
                  _FieldLabel('Descripción *', isError: _descriptionError),
                  _PromoField(
                    controller: _description,
                    hint: 'Describe los detalles de la promoción...',
                    isError: _descriptionError,
                    minLines: 4,
                    maxLines: 6,
                    onChanged: (_) {
                      if (_descriptionError) {
                        setState(() => _descriptionError = false);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _FieldLabel('Descuento *'),
                            _PromoField(
                              controller: _discount,
                              hint: 'Ej: 50% OFF',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _FieldLabel('Categoría *'),
                            _CategoryDropdown(
                              value: _category,
                              onChanged: _onCategoryChanged,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _FieldLabel('Fecho de Expiración *', isError: _dateError),
                  _PromoField(
                    controller: _endDate,
                    hint: 'dd/mm/yy',
                    isError: _dateError,
                    readOnly: true,
                    onTap: _pickDate,
                    suffixIcon: const Icon(Icons.calendar_month,
                        color: PromoColors.textGray),
                  ),
                  const SizedBox(height: 8),
                  _PromotionImageSelector(
                    selected: _selectedImage,
                    isError: _imageError,
                    onTap: _pickPromotionImage,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            _SectionHeader(
              title: 'Condiciones de Uso',
              action: ElevatedButton.icon(
                onPressed: () => setState(() => _conditions.add(_Condition())),
                icon: const Icon(Icons.add, color: Colors.white, size: 16),
                label: const Text(
                  'Agregar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PromoColors.purple,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
            ),
            if (_conditions.isEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: DashedBorder(
                  color: PromoColors.dash,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'No hay condiciones ¡Agregar algunas!',
                        style:
                            TextStyle(fontSize: 14, color: Color(0xFF666666)),
                      ),
                    ),
                  ),
                ),
              )
            else
              ..._conditions.asMap().entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: _ConditionRow(
                        item: e.value,
                        onTypeChange: (t) => setState(() => e.value.type = t),
                        onValueChange: (v) => e.value.value = v,
                        onDelete: () =>
                            setState(() => _conditions.removeAt(e.key)),
                      ),
                    ),
                  ),
            const SizedBox(height: 8),
            const _SectionHeader(title: 'Codigo QR'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _QrSection(
                qrCode: _qrCode,
                onRefresh: () => setState(() => _qrCode = _generateQrCode()),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: BlocBuilder<PromotionsBloc, PromotionsState>(
                buildWhen: (a, b) =>
                    a.actionInProgress != b.actionInProgress,
                builder: (context, state) {
                  return Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: state.actionInProgress
                              ? null
                              : () => Navigator.of(context).maybePop(),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 52),
                            side: const BorderSide(
                                color: PromoColors.purple, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(
                              color: Color(0xFFCCAACF),
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: state.actionInProgress ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PromoColors.purple,
                            minimumSize: const Size(0, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          child: state.actionInProgress
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  _isEdit ? 'Guardar' : 'Crear',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  color: PromoColors.purple,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: PromoColors.purple,
                ),
              ),
            ],
          ),
          ?action,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {this.isError = false});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isError ? PromoColors.errorRed : PromoColors.purple,
        ),
      ),
    );
  }
}

/// Campo de formulario con fondo lavanda (estilo Klippr).
class _PromoField extends StatelessWidget {
  const _PromoField({
    required this.controller,
    required this.hint,
    this.isError = false,
    this.minLines = 1,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String hint;
  final bool isError;
  final int minLines;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color),
        );

    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      minLines: minLines,
      maxLines: maxLines,
      style: const TextStyle(color: PromoColors.textDark, fontSize: 14),
      cursorColor: PromoColors.purple,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: PromoColors.textGray, fontSize: 14),
        filled: true,
        fillColor: PromoColors.fieldBg,
        suffixIcon: suffixIcon,
        border: border(Colors.transparent),
        enabledBorder:
            border(isError ? PromoColors.errorRed : Colors.transparent),
        focusedBorder:
            border(isError ? PromoColors.errorRed : PromoColors.purple),
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({required this.value, required this.onChanged});

  final _PromotionCategory value;
  final ValueChanged<_PromotionCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PromoColors.fieldBg,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_PromotionCategory>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down,
              color: PromoColors.textGray),
          style: const TextStyle(color: PromoColors.textDark, fontSize: 14),
          onChanged: (c) {
            if (c != null) onChanged(c);
          },
          items: _PromotionCategory.values
              .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
              .toList(),
        ),
      ),
    );
  }
}

class _PromotionImageSelector extends StatelessWidget {
  const _PromotionImageSelector({
    required this.selected,
    required this.isError,
    required this.onTap,
  });

  final PromotionImageOption? selected;
  final bool isError;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final image = selected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel('Imagen promocional *', isError: isError),
        Material(
          color: PromoColors.fieldBg,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isError ? PromoColors.errorRed : Colors.transparent,
                  width: 1.5,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: image == null
                        ? const _ImagePlaceholder()
                        : Image.asset(
                            image.assetPath,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const _ImagePlaceholder(),
                          ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            image?.label ?? 'Elige una imagen',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: image == null
                                  ? PromoColors.textGray
                                  : PromoColors.textDark,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.grid_view_rounded,
                          color: PromoColors.purple,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isError)
          const Padding(
            padding: EdgeInsets.only(left: 4, top: 6),
            child: Text(
              'Selecciona una imagen para la promocion',
              style: TextStyle(
                color: PromoColors.errorRed,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

class _PromotionImagePickerSheet extends StatelessWidget {
  const _PromotionImagePickerSheet({
    required this.categoryLabel,
    required this.options,
    required this.selectedKey,
  });

  final String categoryLabel;
  final List<PromotionImageOption> options;
  final String? selectedKey;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD7D0DD),
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Text(
                'Imagenes de $categoryLabel',
                style: const TextStyle(
                  color: PromoColors.purple,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.94,
                ),
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  final selected = option.key == selectedKey;
                  return _PromotionImageTile(
                    option: option,
                    selected: selected,
                    onTap: () => Navigator.of(context).pop(option),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromotionImageTile extends StatelessWidget {
  const _PromotionImageTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final PromotionImageOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PromoColors.fieldBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? PromoColors.purple : Colors.transparent,
              width: 2,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Image.asset(
                  option.assetPath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const _ImagePlaceholder(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        option.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: PromoColors.textDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (selected)
                      const Icon(
                        Icons.check_circle,
                        color: PromoColors.purple,
                        size: 18,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        color: PromoColors.purple,
        size: 42,
      ),
    );
  }
}

class _ConditionRow extends StatelessWidget {
  const _ConditionRow({
    required this.item,
    required this.onTypeChange,
    required this.onValueChange,
    required this.onDelete,
  });

  final _Condition item;
  final ValueChanged<_ConditionType> onTypeChange;
  final ValueChanged<String> onValueChange;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return DashedBorder(
      color: PromoColors.dash,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<_ConditionType>(
                        value: item.type,
                        isExpanded: true,
                        hint: const Text('Elige una opcion',
                            style: TextStyle(fontSize: 13)),
                        style: const TextStyle(
                            color: PromoColors.textDark, fontSize: 13),
                        onChanged: (t) {
                          if (t != null) onTypeChange(t);
                        },
                        items: _ConditionType.values
                            .map((t) => DropdownMenuItem(
                                value: t, child: Text(t.label)))
                            .toList(),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete,
                      color: PromoColors.errorRed, size: 22),
                  tooltip: 'Eliminar condición',
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              enabled: item.type != null,
              onChanged: onValueChange,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Valor...',
                hintStyle:
                    const TextStyle(fontSize: 12, color: PromoColors.textGray),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: PromoColors.purple),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrSection extends StatelessWidget {
  const _QrSection({required this.qrCode, required this.onRefresh});

  final String qrCode;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PromoColors.lavender,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Stack(
        children: [
          Column(
            children: [
              Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Icon(Icons.qr_code_2, color: Colors.black, size: 160),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                qrCode,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.topRight,
            child: Container(
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
              child: IconButton(
                onPressed: onRefresh,
                iconSize: 16,
                constraints:
                    const BoxConstraints.tightFor(width: 32, height: 32),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.refresh, color: PromoColors.textGray),
                tooltip: 'Regenerar QR',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
