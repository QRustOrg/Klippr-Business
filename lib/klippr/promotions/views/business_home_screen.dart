import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/widgets/dashed_border.dart';
import '../../core/widgets/klippr_bottom_bar.dart';
import '../bloc/promotions_bloc.dart';
import '../bloc/promotions_event.dart';
import '../bloc/promotions_state.dart';
import '../models/promotion.dart';
import 'create_promotion_screen.dart';
import 'promo_colors.dart';

// author: Samuel Bonifacio
//
// Pantalla principal del perfil Business: dashboard con estadísticas de
// promociones y la lista creada. Replica el mockup Business y se conecta al
// PromotionsBloc.

/// Dashboard de inicio del negocio.
class BusinessHomeScreen extends StatefulWidget {
  const BusinessHomeScreen({super.key});

  @override
  State<BusinessHomeScreen> createState() => _BusinessHomeScreenState();
}

class _BusinessHomeScreenState extends State<BusinessHomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PromotionsBloc>().add(const LoadPromotions());
  }

  void _openCreate({Promotion? promotion}) {
    final bloc = context.read<PromotionsBloc>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: CreatePromotionScreen(promotion: promotion),
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
      body: Column(
        children: [
          const _HomeTopBar(),
          Expanded(
            child: BlocConsumer<PromotionsBloc, PromotionsState>(
              listenWhen: (_, _) =>
                  ModalRoute.of(context)?.isCurrent ?? true,
              listener: (context, state) {
                if (state.error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.error!)),
                  );
                  context.read<PromotionsBloc>().add(
                        const PromotionsFlagsConsumed(),
                      );
                }
              },
              builder: (context, state) {
                return RefreshIndicator(
                  onRefresh: () async {
                    final bloc = context.read<PromotionsBloc>();
                    bloc.add(const LoadPromotions());
                    await bloc.stream.firstWhere((s) => !s.isLoading);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        _statsGrid(state),
                        const SizedBox(height: 28),
                        const Center(
                          child: Text(
                            'Promociones Creadas',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: PromoColors.purpleText,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (state.isLoading && state.promotions.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 48),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: PromoColors.purple,
                              ),
                            ),
                          )
                        else if (state.promotions.isEmpty)
                          _EmptyPromotions(onCreate: _openCreate)
                        else
                          ...state.promotions.map(
                            (p) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _PromotionCard(
                                promotion: p,
                                onEdit: () => _openCreate(promotion: p),
                                onPublish: () => context
                                    .read<PromotionsBloc>()
                                    .add(PublishPromotion(p.id)),
                                onCancel: () async {
                                  if (await _confirm('Cancelar promoción',
                                      '¿Cancelar "${p.title}"?')) {
                                    if (!context.mounted) return;
                                    context
                                        .read<PromotionsBloc>()
                                        .add(CancelPromotion(p.id));
                                  }
                                },
                                onDelete: () async {
                                  if (await _confirm('Eliminar promoción',
                                      '¿Eliminar "${p.title}"? No se puede deshacer.')) {
                                    if (!context.mounted) return;
                                    context
                                        .read<PromotionsBloc>()
                                        .add(DeletePromotion(p.id));
                                  }
                                },
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: KlipprBottomBar(
        current: KlipprTab.inicio,
        onQr: () => _openCreate(),
        onInicio: () {},
        onMiLista: () {},
      ),
    );
  }

  Widget _statsGrid(PromotionsState state) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Total',
                value: '${state.total}',
                icon: Icons.card_giftcard,
                iconBg: PromoColors.statPurpleBg,
                iconTint: PromoColors.statPurpleIcon,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _StatCard(
                title: 'Actividad',
                value: '${state.actividad}',
                icon: Icons.north_east,
                iconBg: PromoColors.statGreenBg,
                iconTint: PromoColors.statGreenIcon,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Activados',
                value: '${state.activos}',
                icon: Icons.check,
                iconBg: PromoColors.statBlueBg,
                iconTint: PromoColors.statBlueIcon,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _StatCard(
                title: 'Expiradas',
                value: '${state.expiradas}',
                icon: Icons.calendar_today,
                iconBg: PromoColors.statAmberBg,
                iconTint: PromoColors.statAmberIcon,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: PromoColors.purple,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SizedBox(
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: PromoColors.avatarBg,
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/images/klippr_mascot.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const Text(
                  'Klippr',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.qr_code_2,
                            color: Colors.white, size: 28),
                        tooltip: 'QR',
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.notifications_outlined,
                            color: Colors.white, size: 28),
                        tooltip: 'Notificaciones',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.iconTint,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color iconBg;
  final Color iconTint;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: PromoColors.purpleText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: PromoColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconTint, size: 24),
          ),
        ],
      ),
    );
  }
}

/// Acciones disponibles según el estado de la promoción.
enum _PromoAction { editar, publicar, cancelar, eliminar }

class _PromotionCard extends StatelessWidget {
  const _PromotionCard({
    required this.promotion,
    required this.onEdit,
    required this.onPublish,
    required this.onCancel,
    required this.onDelete,
  });

  final Promotion promotion;
  final VoidCallback onEdit;
  final VoidCallback onPublish;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  Color get _statusColor => switch (promotion.status) {
        PromotionStatus.published => PromoColors.statGreenIcon,
        PromotionStatus.draft => PromoColors.purpleText,
        PromotionStatus.cancelled => PromoColors.errorRed,
        PromotionStatus.expired => PromoColors.statAmberIcon,
        PromotionStatus.unknown => PromoColors.textGray,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  promotion.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: PromoColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: PromoColors.purple,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        promotion.discountLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      promotion.status.label,
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<_PromoAction>(
            icon: const Icon(Icons.more_vert, color: PromoColors.textGray),
            onSelected: (a) {
              switch (a) {
                case _PromoAction.editar:
                  onEdit();
                case _PromoAction.publicar:
                  onPublish();
                case _PromoAction.cancelar:
                  onCancel();
                case _PromoAction.eliminar:
                  onDelete();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: _PromoAction.editar, child: Text('Editar')),
              PopupMenuItem(
                  value: _PromoAction.publicar, child: Text('Publicar')),
              PopupMenuItem(
                  value: _PromoAction.cancelar, child: Text('Cancelar')),
              PopupMenuItem(
                  value: _PromoAction.eliminar, child: Text('Eliminar')),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyPromotions extends StatelessWidget {
  const _EmptyPromotions({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return DashedBorder(
      color: PromoColors.dash,
      radius: 20,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        child: Column(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: PromoColors.lavender, width: 2),
              ),
              child: const Icon(Icons.inventory_2_outlined,
                  color: PromoColors.emptyIcon, size: 44),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sin promociones',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: PromoColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Crea tu primera promocion',
              style: TextStyle(fontSize: 15, color: PromoColors.textGray),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Crear Promocion',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: PromoColors.purple,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
