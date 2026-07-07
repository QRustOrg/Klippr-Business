import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
            child: const Text('Dar de Baja', style: TextStyle(color: Colors.white)),
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
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _PromotionCard extends StatelessWidget {
  const _PromotionCard({
    required this.promotion,
    required this.onTakedown,
    required this.onDelete,
  });

  final AdminPromotion promotion;
  final VoidCallback onTakedown;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      promotion.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: PromoColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      promotion.businessName ?? 'Negocio desconocido',
                      style: const TextStyle(
                        fontSize: 13,
                        color: PromoColors.textGray,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (promotion.isActive
                          ? Colors.green
                          : Colors.red)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  promotion.isActive ? 'Activa' : 'Inactiva',
                  style: TextStyle(
                    color: promotion.isActive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if (promotion.description != null && promotion.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              promotion.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: PromoColors.textDark,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              if (promotion.discountAmount != null) ...[
                Icon(
                  Icons.local_offer,
                  size: 16,
                  color: PromoColors.purple,
                ),
                const SizedBox(width: 4),
                Text(
                  '${promotion.discountAmount}${promotion.discountType == 'PERCENTAGE' ? '%' : ''}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: PromoColors.purple,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              if (promotion.startDate != null) ...[
                const Icon(Icons.calendar_today, size: 16, color: PromoColors.textGray),
                const SizedBox(width: 4),
                Text(
                  '${_formatDate(promotion.startDate!)} - ${_formatDate(promotion.endDate!)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: PromoColors.textGray,
                  ),
                ),
              ],
            ],
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
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Eliminar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
