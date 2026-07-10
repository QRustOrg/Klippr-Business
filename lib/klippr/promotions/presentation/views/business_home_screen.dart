import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../analytics/data/network/analytics_web_service.dart';
import '../../../analytics/data/stores/http_analytics_store.dart';
import '../../../analytics/domain/stores/analytics_store.dart';
import '../../../profile/application/bloc/profile_bloc.dart';
import '../../../profile/application/bloc/profile_event.dart';
import '../../../profile/presentation/navigation/profile_router.dart';
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
  const BusinessHomeScreen({super.key, AnalyticsStore? analyticsStore})
    : _analyticsStore = analyticsStore;

  final AnalyticsStore? _analyticsStore;

  @override
  State<BusinessHomeScreen> createState() => _BusinessHomeScreenState();
}

class _BusinessHomeScreenState extends State<BusinessHomeScreen>
    with WidgetsBindingObserver {
  late final AnalyticsStore _analyticsStore;

  /// Generación de métricas: se incrementa para invalidar FutureBuilders.
  int _metricsEpoch = 0;
  String _countsCacheKey = '';
  Future<Map<String, int>>? _redemptionCountsFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _analyticsStore =
        widget._analyticsStore ??
        HttpAnalyticsStore(AnalyticsWebService(ApiClient()));
    // El backend guarda promos con profileId. Cargar perfil primero cachea
    // ese id; luego LoadPromotions puede listar correctamente.
    try {
      context.read<ProfileBloc>().add(const LoadBusinessProfile());
    } catch (_) {
      // ProfileBloc no disponible en algunos tests.
    }
    context.read<PromotionsBloc>().add(const LoadPromotions());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      // Al volver del background (p. ej. tras canjear en otro flujo).
      _refreshDashboard();
    }
  }

  String _safeBusinessId() {
    try {
      final prefs = PrefsHelper.instance;
      // Analytics/redemptions usan BusinessProfile.Id en el backend.
      final profileId = prefs.profileId;
      if (profileId != null && profileId.isNotEmpty) return profileId;
      return prefs.userId ?? '';
    } on StateError {
      return '';
    }
  }

  void _invalidateMetricsCache() {
    _metricsEpoch++;
    _countsCacheKey = '';
    _redemptionCountsFuture = null;
  }

  /// Recarga promos + canjes (publicadas/activas/expiradas salen del bloc).
  Future<void> _refreshDashboard() async {
    if (!mounted) return;
    _invalidateMetricsCache();
    setState(() {});
    final bloc = context.read<PromotionsBloc>();
    bloc.add(const LoadPromotions());
    await bloc.stream.firstWhere((s) => !s.isLoading);
    if (mounted) setState(() {});
  }

  Future<Map<String, int>> _redemptionCounts(List<Promotion> promotions) {
    final key =
        '$_metricsEpoch|${_safeBusinessId()}|${promotions.map((p) => p.id.value).join('|')}';
    if (_countsCacheKey == key && _redemptionCountsFuture != null) {
      return _redemptionCountsFuture!;
    }
    _countsCacheKey = key;
    _redemptionCountsFuture = _loadRedemptionCounts();
    return _redemptionCountsFuture!;
  }

  Future<Map<String, int>> _loadRedemptionCounts() async {
    final businessId = _safeBusinessId();
    final result = await _analyticsStore.loadPromotionRedemptionCounts(
      businessId,
    );
    return result.dataOrNull ?? const {};
  }

  Future<void> _openCreate({Promotion? promotion}) async {
    final bloc = context.read<PromotionsBloc>();
    await Navigator.of(
      context,
    ).push(PromotionsRouter.create(bloc, promotion: promotion));
    // Crear/editar ya recarga el bloc; invalidamos canjes al volver.
    if (mounted) await _refreshDashboard();
  }

  Future<void> _openScan() async {
    final redemptionBloc = context.read<RedemptionBloc>();
    await Navigator.of(context).push(RedemptionRouter.scan(redemptionBloc));
    if (mounted) await _refreshDashboard();
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

  Future<void> _openActivePromotions() async {
    final bloc = context.read<PromotionsBloc>();
    await Navigator.of(context).push(PromotionsRouter.active(bloc));
    if (mounted) await _refreshDashboard();
  }

  Future<void> _openHistorial() async {
    final bloc = context.read<PromotionsBloc>();
    await Navigator.of(context).push(RedemptionRouter.historyList(bloc));
    if (mounted) await _refreshDashboard();
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
                  // Publicar / cancelar / eliminar / crear: revalidar canjes.
                  _invalidateMetricsCache();
                  setState(() {});
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
                final countsFuture = _redemptionCounts(state.promotions);
                return RefreshIndicator(
                  onRefresh: _refreshDashboard,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        FutureBuilder<Map<String, int>>(
                          future: countsFuture,
                          builder: (context, snapshot) {
                            final total = snapshot.hasData
                                ? snapshot.data!.values.fold<int>(
                                    0,
                                    (sum, n) => sum + n,
                                  )
                                : null;
                            return _DashboardHero(
                              totalRedemptions: total,
                              activePromotions: state.activos,
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _statsGrid(state, countsFuture),
                        const SizedBox(height: 16),
                        _SuggestedPromoCard(onCreate: () => _openCreate()),
                        const SizedBox(height: 16),
                        _QuickActions(
                          onScan: _openScan,
                          onCreate: () => _openCreate(),
                          onHistory: _openHistorial,
                          onActivePromotions: _openActivePromotions,
                        ),
                        const SizedBox(height: 28),
                        const Center(
                          child: Text(
                            'Rendimiento por promo',
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
                                  redemptionsFuture: countsFuture.then(
                                    (map) => Success<int>(map[p.id.value] ?? 0),
                                  ),
                                  onPublish: () async {
                                    if (state.actionInProgress) return;
                                    try {
                                      final profile = context
                                          .read<ProfileBloc>()
                                          .state
                                          .profile;
                                      if (profile != null &&
                                          !profile.isVerified) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Tu negocio debe estar verificado antes de publicar promociones.',
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                    } catch (_) {
                                      // ProfileBloc no disponible en tests aislados.
                                    }
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

  Widget _statsGrid(
    PromotionsState state,
    Future<Map<String, int>> countsFuture,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FutureBuilder<Map<String, int>>(
                future: countsFuture,
                builder: (context, snapshot) {
                  final total = snapshot.hasData
                      ? snapshot.data!.values
                            .fold<int>(0, (sum, n) => sum + n)
                            .toString()
                      : '--';
                  return _StatCard(
                    title: 'Canjes',
                    value: total,
                    icon: Icons.qr_code_2,
                    iconBg: PromoColors.statPurpleBg,
                    iconTint: PromoColors.statPurpleIcon,
                  );
                },
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _StatCard(
                title: 'Activas',
                value: '${state.activos}',
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
                title: 'Publicadas',
                value: '${state.actividad}',
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

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({
    required this.totalRedemptions,
    required this.activePromotions,
  });

  final int? totalRedemptions;
  final int activePromotions;

  @override
  Widget build(BuildContext context) {
    final canjes = totalRedemptions?.toString() ?? '--';
    return Container(
      decoration: BoxDecoration(
        color: PromoColors.purple,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Resumen de ventas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$activePromotions activas',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Tus promos tienen $canjes canjes hasta la fecha',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              height: 1.12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Mide que ofertas mueven clientes y repitelas cuando funcionan.',
            style: TextStyle(
              color: Color(0xFFF7F3FF),
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestedPromoCard extends StatelessWidget {
  const _SuggestedPromoCard({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PromoColors.fieldBg,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: PromoColors.purple,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Promo sugerida',
                  style: TextStyle(
                    color: PromoColors.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Activa una oferta corta para mover horas bajas.',
                  style: TextStyle(
                    color: PromoColors.textGray,
                    fontSize: 13,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onCreate, child: const Text('Crear')),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onScan,
    required this.onCreate,
    required this.onHistory,
    required this.onActivePromotions,
  });

  final VoidCallback onScan;
  final VoidCallback onCreate;
  final VoidCallback onHistory;
  final VoidCallback onActivePromotions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QuickAction(
          icon: Icons.qr_code_scanner,
          label: 'Escanear',
          onTap: onScan,
        ),
        _QuickAction(icon: Icons.add, label: 'Nueva', onTap: onCreate),
        _QuickAction(
          icon: Icons.receipt_long_outlined,
          label: 'Historial',
          onTap: onHistory,
        ),
        _QuickAction(
          icon: Icons.inbox_outlined,
          label: 'Activas',
          onTap: onActivePromotions,
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: PromoColors.statPurpleBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: PromoColors.purple, size: 22),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: PromoColors.textDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
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
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      final bloc = context.read<ProfileBloc>();
                      Navigator.of(context).push(ProfileRouter.profile(bloc));
                    },
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
                          final redemptionBloc = context.read<RedemptionBloc>();
                          Navigator.of(
                            context,
                          ).push(RedemptionRouter.scan(redemptionBloc));
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
