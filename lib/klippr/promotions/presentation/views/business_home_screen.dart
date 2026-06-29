import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../analytics/data/network/analytics_web_service.dart';
import '../../../analytics/data/stores/http_analytics_store.dart';
import '../../../analytics/domain/stores/analytics_store.dart';
import '../../../redemption/application/bloc/redemption_bloc.dart';
import '../../../redemption/presentation/navigation/redemption_router.dart';
import '../../../shared/data/network/api_client.dart';
import '../../../shared/data/network/result.dart';
import '../../../shared/data/pref/prefs_helper.dart';
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
// Pantalla principal del perfil Business: dashboard con estadísticas de
// promociones y la lista creada. Replica el mockup Business y se conecta al
// PromotionsBloc.

/// Dashboard de inicio del negocio.
class BusinessHomeScreen extends StatefulWidget {
  const BusinessHomeScreen({
    super.key,
    AnalyticsStore? analyticsStore,
  }) : _analyticsStore = analyticsStore;

  final AnalyticsStore? _analyticsStore;

  @override
  State<BusinessHomeScreen> createState() => _BusinessHomeScreenState();
}

class _BusinessHomeScreenState extends State<BusinessHomeScreen> {
  late final AnalyticsStore _analyticsStore;
  final Map<String, Future<Result<int>>> _redemptionCountFutures = {};

  @override
  void initState() {
    super.initState();
    _analyticsStore =
        widget._analyticsStore ??
        HttpAnalyticsStore(AnalyticsWebService(ApiClient()));
    context.read<PromotionsBloc>().add(const LoadPromotions());
  }

  Future<Result<int>> _redemptionsFor(String promotionId) {
    final businessId = PrefsHelper.instance.userId ?? '';
    return _redemptionCountFutures.putIfAbsent(
      promotionId,
      () => _analyticsStore.loadPromotionRedemptions(
        businessId,
        promotionId,
      ),
    );
  }

  void _openCreate({Promotion? promotion}) {
    final bloc = context.read<PromotionsBloc>();
    Navigator.of(context).push(
      PromotionsRouter.create(bloc, promotion: promotion),
    );
  }

  void _requestEdit(Promotion promotion) {
    final bloc = context.read<PromotionsBloc>();
    if (bloc.state.isFetchingPromotion || bloc.state.actionInProgress) return;
    if (promotion.status != PromotionStatus.draft || promotion.isExpired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solo puedes editar promociones en borrador.'),
        ),
      );
      return;
    }
    bloc.add(FetchPromotionForEdit(promotion.id.value));
  }

  void _openActivePromotions() {
    final bloc = context.read<PromotionsBloc>();
    Navigator.of(context).push(PromotionsRouter.active(bloc));
  }

  void _openHistorial() {
    final bloc = context.read<PromotionsBloc>();
    Navigator.of(context).push(RedemptionRouter.historyList(bloc));
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
              listenWhen: (_, _) => ModalRoute.of(context)?.isCurrent ?? true,
              listener: (context, state) {
                if (state.error != null) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(state.error!)));
                  context.read<PromotionsBloc>().add(
                    const PromotionsFlagsConsumed(),
                  );
                } else if (state.actionMessage != null) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(state.actionMessage!)));
                  context.read<PromotionsBloc>().add(
                    const PromotionsFlagsConsumed(),
                  );
                } else if (state.promotionToEdit != null) {
                  final promotion = state.promotionToEdit!;
                  context.read<PromotionsBloc>().add(
                    const PromotionEditConsumed(),
                  );
                  _openCreate(promotion: promotion);
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
                              child: GestureDetector(
                                onDoubleTap: () => _requestEdit(p),
                                child: _PromotionCard(
                                  promotion: p,
                                  onEdit: () => _requestEdit(p),
                                  redemptionsFuture: _redemptionsFor(p.id.value),
                                  onPublish: () async {
                                    if (state.actionInProgress) return;
                                    if (await _confirm(
                                      'Publicar promocion',
                                      '¿Publicar "${p.title}"?',
                                    )) {
                                      if (!context.mounted) return;
                                      context.read<PromotionsBloc>().add(
                                        PublishPromotion(p.id.value),
                                      );
                                    }
                                  },
                                  onCancel: () async {
                                    if (state.actionInProgress) return;
                                    if (await _confirm(
                                      'Cancelar promocion',
                                      '¿Cancelar "${p.title}"?',
                                    )) {
                                      if (!context.mounted) return;
                                      context.read<PromotionsBloc>().add(
                                        CancelPromotion(p.id.value),
                                      );
                                    }
                                  },
                                  onDelete: () async {
                                    if (state.actionInProgress) return;
                                    if (await _confirm(
                                      'Eliminar promocion',
                                      '¿Eliminar "${p.title}"? No se puede deshacer.',
                                    )) {
                                      if (!context.mounted) return;
                                      context.read<PromotionsBloc>().add(
                                        DeletePromotion(p.id.value),
                                      );
                                    }
                                  },
                                ),
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
        onMiLista: _openActivePromotions,
        onHistorial: _openHistorial,
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
                        onPressed: () {
                          final redemptionBloc =
                              context.read<RedemptionBloc>();
                          Navigator.of(context).push(
                            RedemptionRouter.scan(redemptionBloc),
                          );
                        },
                        icon: const Icon(
                          Icons.qr_code_2,
                          color: Colors.white,
                          size: 28,
                        ),
                        tooltip: 'QR',
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
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
class _PromotionCard extends StatelessWidget {
  const _PromotionCard({
    required this.promotion,
    required this.redemptionsFuture,
    required this.onEdit,
    required this.onPublish,
    required this.onCancel,
    required this.onDelete,
  });

  final Promotion promotion;
  final Future<Result<int>> redemptionsFuture;
  final VoidCallback onEdit;
  final VoidCallback onPublish;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  bool get _isExpired => promotion.isExpired;
  bool get _canEdit => promotion.status == PromotionStatus.draft && !_isExpired;
  bool get _canPublish =>
      promotion.status == PromotionStatus.draft && !_isExpired;
  bool get _canCancel =>
      promotion.status == PromotionStatus.published && !_isExpired;

  String get _statusLabel => switch (promotion.status) {
    _ when _isExpired => PromotionStatus.expired.label,
    PromotionStatus.published =>
      promotion.isActive ? 'Activa' : promotion.status.label,
    _ => promotion.status.label,
  };

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
              _PromotionStatusPill(
                label: _statusLabel,
                status: promotion.status,
                isActive: promotion.isActive,
                isExpired: _isExpired,
              ),
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
              _PromotionMetaChip(
                label: _redemptionCapLabel(promotion.redemptionCap),
                background: const Color(0xFFF5C5F4),
                foreground: const Color(0xFFA855B4),
              ),
              _PromotionMetaChip(
                label: _dateRangeLabel(promotion.startDate, promotion.endDate),
                background: PromoColors.statBlueBg,
                foreground: const Color(0xFF587A9C),
              ),
              _PromotionMetaChip(
                label: promotion.discountLabel,
                background: const Color(0xFFFBF7C5),
                foreground: const Color(0xFF9A9350),
              ),
              FutureBuilder<Result<int>>(
                future: redemptionsFuture,
                builder: (context, snapshot) {
                  final value = snapshot.data?.dataOrNull;
                  return _PromotionMetaChip(
                    label: value == null ? 'canjes --' : '$value canjes',
                    background: PromoColors.statGreenBg,
                    foreground: PromoColors.statGreenIcon,
                  );
                },
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
                      promotion.id.isEmpty ? 'PROMOCION' : promotion.id.value,
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
                alignment: WrapAlignment.end,
                children: [
                  if (_canEdit)
                    _PromotionIconButton(
                      icon: Icons.edit_outlined,
                      color: Colors.blue,
                      tooltip: 'Editar promocion',
                      onPressed: onEdit,
                    ),
                  if (_canPublish)
                    _PromotionIconButton(
                      icon: Icons.publish_outlined,
                      color: PromoColors.statGreenIcon,
                      tooltip: 'Publicar promocion',
                      onPressed: onPublish,
                    ),
                  if (_canCancel)
                    _PromotionIconButton(
                      icon: Icons.cancel_outlined,
                      color: PromoColors.statAmberIcon,
                      tooltip: 'Cancelar promocion',
                      onPressed: onCancel,
                    ),
                  _PromotionIconButton(
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

class _PromotionStatusPill extends StatelessWidget {
  const _PromotionStatusPill({
    required this.label,
    required this.status,
    required this.isActive,
    required this.isExpired,
  });

  final String label;
  final PromotionStatus status;
  final bool isActive;
  final bool isExpired;

  Color get _background => switch (status) {
    _ when isExpired => PromoColors.statAmberBg,
    PromotionStatus.published when isActive => PromoColors.statGreenBg,
    PromotionStatus.published => PromoColors.statBlueBg,
    PromotionStatus.draft => PromoColors.statPurpleBg,
    PromotionStatus.cancelled => const Color(0xFFFFD6D2),
    PromotionStatus.expired => PromoColors.statAmberBg,
    PromotionStatus.unknown => const Color(0xFFEAEAEA),
  };

  Color get _foreground => switch (status) {
    _ when isExpired => const Color(0xFFC97900),
    PromotionStatus.published when isActive => const Color(0xFF009B55),
    PromotionStatus.published => PromoColors.statBlueIcon,
    PromotionStatus.draft => PromoColors.purpleText,
    PromotionStatus.cancelled => PromoColors.errorRed,
    PromotionStatus.expired => const Color(0xFFC97900),
    PromotionStatus.unknown => PromoColors.textGray,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: _foreground,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _PromotionMetaChip extends StatelessWidget {
  const _PromotionMetaChip({
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

class _PromotionIconButton extends StatelessWidget {
  const _PromotionIconButton({
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
              child: const Icon(
                Icons.inventory_2_outlined,
                color: PromoColors.emptyIcon,
                size: 44,
              ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
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
