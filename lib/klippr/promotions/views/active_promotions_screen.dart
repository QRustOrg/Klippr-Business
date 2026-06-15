import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/widgets/klippr_bottom_bar.dart';
import '../bloc/promotions_bloc.dart';
import '../bloc/promotions_event.dart';
import '../bloc/promotions_state.dart';
import '../models/promotion.dart';
import '../models/promotion_image_catalog.dart';
import 'create_promotion_screen.dart';
import 'promo_colors.dart';

class ActivePromotionsScreen extends StatefulWidget {
  const ActivePromotionsScreen({super.key});

  @override
  State<ActivePromotionsScreen> createState() => _ActivePromotionsScreenState();
}

class _ActivePromotionsScreenState extends State<ActivePromotionsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PromotionsBloc>().add(const LoadActivePromotions());
  }

  void _openCreate() {
    final bloc = context.read<PromotionsBloc>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: const CreatePromotionScreen(),
        ),
      ),
    );
  }

  Future<bool> _confirm(String title, String message) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          'Mi Lista',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: BlocConsumer<PromotionsBloc, PromotionsState>(
        listener: (context, state) {
          final message = state.activeError ?? state.error;
          if (message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
            context
                .read<PromotionsBloc>()
                .add(const PromotionsFlagsConsumed());
          } else if (state.actionMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.actionMessage!)),
            );
            context
                .read<PromotionsBloc>()
                .add(const PromotionsFlagsConsumed());
          }
        },
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () async {
              final bloc = context.read<PromotionsBloc>();
              bloc.add(const LoadActivePromotions());
              await bloc.stream.firstWhere((s) => !s.isActiveLoading);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              children: [
                const Center(
                  child: Text(
                    'Promociones Activas',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: PromoColors.purpleText,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (state.isActiveLoading && state.activePromotions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: PromoColors.purple,
                      ),
                    ),
                  )
                else if (state.activeIsEmpty)
                  const _ActiveEmptyState()
                else
                  ...state.activePromotions.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ActivePromotionCard(
                        promotion: p,
                        onCancel: () async {
                          if (state.actionInProgress) return;
                          if (await _confirm(
                            'Cancelar promocion',
                            '¿Cancelar "${p.title}"?',
                          )) {
                            if (!context.mounted) return;
                            context
                                .read<PromotionsBloc>()
                                .add(CancelPromotion(p.id));
                          }
                        },
                        onDelete: () async {
                          if (state.actionInProgress) return;
                          if (await _confirm(
                            'Eliminar promocion',
                            '¿Eliminar "${p.title}"? No se puede deshacer.',
                          )) {
                            if (!context.mounted) return;
                            context
                                .read<PromotionsBloc>()
                                .add(DeletePromotion(p.id));
                          }
                        },
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: KlipprBottomBar(
        current: KlipprTab.miLista,
        onQr: _openCreate,
        onInicio: () => Navigator.of(context).maybePop(),
        onMiLista: () {},
      ),
    );
  }
}

class _ActiveEmptyState extends StatelessWidget {
  const _ActiveEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 56),
      child: Center(
        child: Text(
          'No tienes promociones activas',
          style: TextStyle(
            color: PromoColors.textGray,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ActivePromotionCard extends StatelessWidget {
  const _ActivePromotionCard({
    required this.promotion,
    required this.onCancel,
    required this.onDelete,
  });

  final Promotion promotion;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final image = PromotionImageCatalog.byKey(promotion.imageKey);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  promotion.title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: PromoColors.purpleText,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const _ActiveStatusPill(),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.asset(
                image.assetPath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const DecoratedBox(
                  decoration: BoxDecoration(color: PromoColors.fieldBg),
                  child: Center(
                    child: Icon(
                      Icons.image_outlined,
                      color: PromoColors.purple,
                      size: 42,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            promotion.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              height: 1.25,
              color: PromoColors.textDark,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              _MetaChip(
                label: _redemptionCapLabel(promotion.redemptionCap),
                background: const Color(0xFFF5C5F4),
                foreground: const Color(0xFFA855B4),
              ),
              _MetaChip(
                label: _dateRangeLabel(promotion.startDate, promotion.endDate),
                background: PromoColors.statBlueBg,
                foreground: const Color(0xFF587A9C),
              ),
              _MetaChip(
                label: promotion.discountLabel,
                background: const Color(0xFFFBF7C5),
                foreground: const Color(0xFF9A9350),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(
            color: Color(0xFFEDE5F1),
            height: 1,
            thickness: 2,
            indent: 18,
            endIndent: 18,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      promotion.id.isEmpty ? 'PROMOCION' : promotion.id,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Vence: ${_formatFullDate(promotion.endDate)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _IconAction(
                    icon: Icons.cancel_outlined,
                    color: PromoColors.statAmberIcon,
                    tooltip: 'Cancelar promocion',
                    onPressed: onCancel,
                  ),
                  _IconAction(
                    icon: Icons.delete_outline,
                    color: PromoColors.errorRed,
                    tooltip: 'Eliminar promocion',
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActiveStatusPill extends StatelessWidget {
  const _ActiveStatusPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
      decoration: BoxDecoration(
        color: PromoColors.statGreenBg,
        borderRadius: BorderRadius.circular(50),
      ),
      child: const Text(
        'Activa',
        style: TextStyle(
          color: Color(0xFF009B55),
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: foreground,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 38,
      child: IconButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        tooltip: tooltip,
        icon: Icon(icon, color: color, size: 30),
      ),
    );
  }
}

String _redemptionCapLabel(int? redemptionCap) {
  if (redemptionCap == null || redemptionCap <= 0) return 'sin limite';
  return '$redemptionCap unid.';
}

String _dateRangeLabel(DateTime? start, DateTime? end) {
  if (start == null && end == null) return 'sin fecha';
  if (start == null) return 'hasta ${_formatShortDate(end)}';
  if (end == null) return 'desde ${_formatShortDate(start)}';
  return '${_formatShortDate(start)} al ${_formatShortDate(end)}';
}

String _formatShortDate(DateTime? date) {
  if (date == null) return '--/--';
  final dd = date.day.toString().padLeft(2, '0');
  final mm = date.month.toString().padLeft(2, '0');
  return '$dd/$mm';
}

String _formatFullDate(DateTime? date) {
  if (date == null) return '--/--/----';
  final dd = date.day.toString().padLeft(2, '0');
  final mm = date.month.toString().padLeft(2, '0');
  final yyyy = date.year.toString().padLeft(4, '0');
  return '$dd/$mm/$yyyy';
}
