import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../promotions/presentation/resources/promotion_image_catalog.dart';
import '../../../promotions/presentation/views/promo_colors.dart';
import '../../application/bloc/admin_bloc.dart';
import '../../application/bloc/admin_event.dart';
import '../../application/bloc/admin_state.dart';
import '../../domain/models/admin_promotion.dart';

class AdminPromotionsScreen extends StatelessWidget {
  const AdminPromotionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PromoColors.screenBg,
      appBar: AppBar(
        backgroundColor: PromoColors.purple,
        title: const Text(
          'Moderar Promociones',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: BlocConsumer<AdminBloc, AdminState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Colors.red,
              ),
            );
            context.read<AdminBloc>().add(const AdminErrorConsumed());
          }
          if (state.actionMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.actionMessage!),
                backgroundColor: PromoColors.purple,
              ),
            );
            context.read<AdminBloc>().add(const AdminMessageConsumed());
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.allPromotions.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: PromoColors.purple),
            );
          }

          if (state.allPromotions.isEmpty) {
            return const Center(
              child: Text(
                'No hay promociones para moderar',
                style: TextStyle(
                  fontSize: 16,
                  color: PromoColors.textGray,
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: PromoColors.purple,
            onRefresh: () async {
              context.read<AdminBloc>().add(const LoadAdminData());
              await context.read<AdminBloc>().stream.firstWhere(
                    (s) => !s.isLoading,
                  );
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: state.allPromotions.length,
              itemBuilder: (context, index) {
                final promotion = state.allPromotions[index];
                return _PromotionCard(
                  key: Key('admin-promotion-card-${promotion.id.value}'),
                  promotion: promotion,
                  onTakedown: () => _showTakedownDialog(context, promotion),
                  onDelete: () => _showDeleteDialog(context, promotion),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showTakedownDialog(BuildContext context, AdminPromotion promotion) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Dar de Baja Promoción'),
        content: Text(
          '¿Estás seguro de dar de baja "${promotion.title}"? Esta acción cancelará la promoción.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context
                  .read<AdminBloc>()
                  .add(TakedownPromotionRequested(promotion.id.value));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text(
              'Dar de Baja',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, AdminPromotion promotion) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar Promoción'),
        content: Text(
          '¿Estás seguro de eliminar permanentemente "${promotion.title}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context
                  .read<AdminBloc>()
                  .add(DeletePromotionRequested(promotion.id.value));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card con el body completo de GET /api/promotions (imagen, estado, negocio…).
class _PromotionCard extends StatelessWidget {
  const _PromotionCard({
    super.key,
    required this.promotion,
    required this.onTakedown,
    required this.onDelete,
  });

  final AdminPromotion promotion;
  final VoidCallback onTakedown;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final image = PromotionImageCatalog.byKey(promotion.imageKey);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    promotion.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: PromoColors.textDark,
                      height: 1.15,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _StatusPill(promotion: promotion),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.storefront_outlined,
                  size: 16,
                  color: PromoColors.textGray,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    promotion.businessName.isNotEmpty
                        ? promotion.businessName
                        : 'Negocio desconocido',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: PromoColors.textGray,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.asset(
                  image.assetPath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const DecoratedBox(
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
            if (promotion.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                promotion.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.3,
                  color: PromoColors.textDark,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaChip(
                  label: promotion.discountLabel,
                  background: const Color(0xFFFBF7C5),
                  foreground: const Color(0xFF9A9350),
                ),
                if (promotion.startDate != null || promotion.endDate != null)
                  _MetaChip(
                    label: _dateRangeLabel(
                      promotion.startDate,
                      promotion.endDate,
                    ),
                    background: PromoColors.statBlueBg,
                    foreground: const Color(0xFF587A9C),
                  ),
                _MetaChip(
                  label: _redemptionCapLabel(promotion.redemptionCap),
                  background: const Color(0xFFF5C5F4),
                  foreground: const Color(0xFFA855B4),
                ),
                if (promotion.id.value.isNotEmpty)
                  _MetaChip(
                    label: promotion.id.value,
                    background: PromoColors.fieldBg,
                    foreground: PromoColors.textGray,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(
              color: Color(0xFFEDE5F1),
              height: 1,
              thickness: 1.5,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onTakedown,
                    icon: const Icon(Icons.remove_circle_outline, size: 18),
                    label: const Text('Dar de Baja'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, size: 18, color: Colors.white),
                    label: const Text(
                      'Eliminar',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.promotion});

  final AdminPromotion promotion;

  Color get _background {
    if (promotion.isExpired) return PromoColors.statAmberBg;
    final raw = promotion.status.trim().toLowerCase();
    if (raw.contains('cancel')) return const Color(0xFFFFD6D2);
    if (raw.contains('draft') || raw.contains('borrador')) {
      return PromoColors.statPurpleBg;
    }
    if (promotion.isActive) return PromoColors.statGreenBg;
    return PromoColors.statBlueBg;
  }

  Color get _foreground {
    if (promotion.isExpired) return const Color(0xFFC97900);
    final raw = promotion.status.trim().toLowerCase();
    if (raw.contains('cancel')) return PromoColors.errorRed;
    if (raw.contains('draft') || raw.contains('borrador')) {
      return PromoColors.purpleText;
    }
    if (promotion.isActive) return const Color(0xFF009B55);
    return PromoColors.statBlueIcon;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        promotion.statusLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: _foreground,
          fontSize: 13,
          fontWeight: FontWeight.bold,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
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
