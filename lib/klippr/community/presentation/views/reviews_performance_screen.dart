import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../analytics/domain/stores/analytics_store.dart';
import '../../../promotions/domain/models/promotion.dart';
import '../../../promotions/domain/stores/promotions_store.dart';
import '../../../promotions/presentation/resources/promotion_image_catalog.dart';
import '../../../promotions/presentation/views/promo_colors.dart';
import '../../domain/models/promotion_feedback_metrics.dart';
import '../../domain/models/review.dart';
import '../../domain/models/review_comment.dart';
import '../../repository/reviews_repository.dart';

class ReviewsPerformanceScreen extends StatefulWidget {
  const ReviewsPerformanceScreen({
    super.key,
    required this.profileId,
    this.reviewsRepository,
    this.promotionsStore,
    this.analyticsStore,
  });

  final String profileId;
  final ReviewsRepository? reviewsRepository;
  final PromotionsStore? promotionsStore;
  final AnalyticsStore? analyticsStore;

  @override
  State<ReviewsPerformanceScreen> createState() =>
      _ReviewsPerformanceScreenState();
}

class _ReviewsPerformanceScreenState extends State<ReviewsPerformanceScreen> {
  late final ReviewsRepository _reviews =
      widget.reviewsRepository ?? GetIt.instance<ReviewsRepository>();
  late final PromotionsStore _promotions =
      widget.promotionsStore ?? GetIt.instance<PromotionsStore>();
  late final AnalyticsStore _analytics =
      widget.analyticsStore ?? GetIt.instance<AnalyticsStore>();

  bool _loading = true;
  String? _error;
  List<Promotion> _own = const [];
  List<Promotion> _explore = const [];
  Map<String, List<Review>> _reviewsByPromotion = const {};
  Map<String, List<ReviewComment>> _commentsByReview = const {};
  Map<String, int>? _ownRedemptions;
  Map<String, int?> _exploreRedemptions = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);

    // Mis promociones: GET /api/promotions/businesses/{businessId}
    final businessId = widget.profileId.trim();
    final ownFuture = businessId.isNotEmpty
        ? _promotions.loadByBusiness(businessId)
        : _promotions.loadMine();
    final activeFuture = _promotions.loadActive();
    final reviewsFuture = _reviews.getReviews();
    final ownResult = await ownFuture;
    final activeResult = await activeFuture;
    final reviewsResult = await reviewsFuture;
    final failure =
        ownResult.errorOrNull ??
        activeResult.errorOrNull ??
        reviewsResult.errorOrNull;
    if (failure != null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = failure.message;
        });
      }
      return;
    }

    final own = ownResult.dataOrNull!;
    final ownIds = own.map((promotion) => promotion.id.value).toSet();
    final explore = activeResult.dataOrNull!
        .where((promotion) => !ownIds.contains(promotion.id.value))
        .toList(growable: false);
    final reviews = reviewsResult.dataOrNull!;
    final groupedReviews = <String, List<Review>>{};
    for (final review in reviews) {
      groupedReviews.putIfAbsent(review.promotionId, () => []).add(review);
    }

    // ponytail: una llamada por reseña; cambiar a commentCount batch cuando
    // el volumen real lo justifique o el backend lo exponga.
    final comments = <String, List<ReviewComment>>{};
    await Future.wait(
      reviews.map((review) async {
        final result = await _reviews.getComments(review.id);
        final value = result.dataOrNull;
        if (value != null) comments[review.id] = value;
      }),
    );
    Map<String, int>? ownRedemptions;
    final redemptionsBusinessId = businessId.isNotEmpty
        ? businessId
        : own.firstOrNull?.businessId.value;
    if (redemptionsBusinessId != null && redemptionsBusinessId.isNotEmpty) {
      ownRedemptions = (await _analytics.loadPromotionRedemptionCounts(
        redemptionsBusinessId,
      )).dataOrNull;
    }

    // ponytail: una métrica por promoción ajena; usar endpoint batch cuando
    // exista o la cantidad visible haga medible este costo.
    final exploreRedemptions = <String, int?>{};
    await Future.wait(
      explore.map((promotion) async {
        final result = await _analytics.loadCampaignMetrics(promotion.id.value);
        exploreRedemptions[promotion.id.value] = result.dataOrNull?.redemptions;
      }),
    );

    if (!mounted) return;
    setState(() {
      _own = own;
      _explore = explore;
      _reviewsByPromotion = groupedReviews;
      _commentsByReview = comments;
      _ownRedemptions = ownRedemptions;
      _exploreRedemptions = exploreRedemptions;
      _loading = false;
      _error = null;
    });
  }

  PromotionFeedbackMetrics _metrics(Promotion promotion, bool isOwn) {
    final reviews = _reviewsByPromotion[promotion.id.value] ?? const [];
    return PromotionFeedbackMetrics.fromReviews(
      reviews: reviews,
      commentsByReview: _commentsByReview,
      redemptions: isOwn
          ? (_ownRedemptions == null
                ? null
                : _ownRedemptions![promotion.id.value] ?? 0)
          : _exploreRedemptions[promotion.id.value],
    );
  }

  void _commentAdded(ReviewComment comment) {
    setState(() {
      _commentsByReview = {
        ..._commentsByReview,
        comment.reviewId: [...?_commentsByReview[comment.reviewId], comment],
      };
    });
  }

  void _open(Promotion promotion, bool isOwn) {
    final reviews = _reviewsByPromotion[promotion.id.value] ?? const [];
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ReviewsDetailScreen(
          promotion: promotion,
          reviews: reviews,
          commentsByReview: _commentsByReview,
          canReply: isOwn,
          repository: _reviews,
          onCommentAdded: _commentAdded,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: PromoColors.purple,
          foregroundColor: Colors.white,
          title: const Text(
            'Rendimiento y reseñas',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Mis promociones'),
              Tab(text: 'Explorar'),
            ],
          ),
        ),
        body: _body(),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }
    return TabBarView(
      children: [
        _PromotionReviewsList(
          promotions: _own,
          isOwn: true,
          metrics: _metrics,
          onOpen: _open,
          onRefresh: _load,
        ),
        _PromotionReviewsList(
          promotions: _explore,
          isOwn: false,
          metrics: _metrics,
          onOpen: _open,
          onRefresh: _load,
        ),
      ],
    );
  }
}

class _PromotionReviewsList extends StatelessWidget {
  const _PromotionReviewsList({
    required this.promotions,
    required this.isOwn,
    required this.metrics,
    required this.onOpen,
    required this.onRefresh,
  });

  final List<Promotion> promotions;
  final bool isOwn;
  final PromotionFeedbackMetrics Function(Promotion, bool) metrics;
  final void Function(Promotion, bool) onOpen;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: promotions.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 160),
                Icon(Icons.reviews_outlined, size: 54, color: Colors.grey),
                SizedBox(height: 12),
                Center(child: Text('No hay promociones para mostrar')),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: promotions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final promotion = promotions[index];
                final value = metrics(promotion, isOwn);
                return _PromotionReviewCard(
                  key: Key('promotion-card-${promotion.id.value}'),
                  promotion: promotion,
                  metrics: value,
                  showBusiness: !isOwn,
                  onTap: () => onOpen(promotion, isOwn),
                );
              },
            ),
    );
  }
}

/// Card completa de promoción para la lista de rendimiento/reseñas.
/// Usa los campos del GET (título, negocio, imagen, estado, descuento, fechas).
class _PromotionReviewCard extends StatelessWidget {
  const _PromotionReviewCard({
    super.key,
    required this.promotion,
    required this.metrics,
    required this.showBusiness,
    required this.onTap,
  });

  final Promotion promotion;
  final PromotionFeedbackMetrics metrics;
  final bool showBusiness;
  final VoidCallback onTap;

  bool get _isExpired => promotion.isExpired;

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
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
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
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: PromoColors.textDark,
                          height: 1.15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _StatusPill(
                      label: _statusLabel,
                      status: promotion.status,
                      isActive: promotion.isActive,
                      isExpired: _isExpired,
                    ),
                  ],
                ),
                if (showBusiness && promotion.businessName.isNotEmpty) ...[
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
                          promotion.businessName,
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
                ],
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
                            decoration: BoxDecoration(
                              color: PromoColors.fieldBg,
                            ),
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
                    maxLines: 2,
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
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(
                  color: Color(0xFFEDE5F1),
                  height: 1,
                  thickness: 1.5,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Metric('${metrics.redemptions ?? '--'} canjes'),
                    _Metric(
                      metrics.averageRating == null
                          ? '-- promedio'
                          : '${metrics.averageRating!.toStringAsFixed(1)} promedio',
                    ),
                    _Metric(
                      '${metrics.reviewCount} ${metrics.reviewCount == 1 ? 'reseña' : 'reseñas'}',
                    ),
                    _Metric('${metrics.likeCount} likes'),
                    _Metric(
                      metrics.replyCount == null
                          ? '-- respuestas'
                          : '${metrics.replyCount} ${metrics.replyCount == 1 ? 'respuesta' : 'respuestas'}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

class _Metric extends StatelessWidget {
  const _Metric(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: PromoColors.lavender,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label, style: const TextStyle(color: PromoColors.purpleText)),
  );
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

class _ReviewsDetailScreen extends StatefulWidget {
  const _ReviewsDetailScreen({
    required this.promotion,
    required this.reviews,
    required this.commentsByReview,
    required this.canReply,
    required this.repository,
    required this.onCommentAdded,
  });

  final Promotion promotion;
  final List<Review> reviews;
  final Map<String, List<ReviewComment>> commentsByReview;
  final bool canReply;
  final ReviewsRepository repository;
  final ValueChanged<ReviewComment> onCommentAdded;

  @override
  State<_ReviewsDetailScreen> createState() => _ReviewsDetailScreenState();
}

class _ReviewsDetailScreenState extends State<_ReviewsDetailScreen> {
  final _reply = TextEditingController();
  late final Map<String, List<ReviewComment>> _comments = {
    for (final entry in widget.commentsByReview.entries)
      entry.key: [...entry.value],
  };
  String? _selectedReviewId;
  bool _sending = false;
  bool _refreshing = false;

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _reply.text.trim();
    final reviewId = _selectedReviewId ?? widget.reviews.firstOrNull?.id;
    if (text.isEmpty || reviewId == null || _sending) return;
    setState(() => _sending = true);
    final result = await widget.repository.addComment(reviewId, text);
    if (!mounted) return;
    final comment = result.dataOrNull;
    if (comment == null) {
      setState(() => _sending = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.errorOrNull!.message)));
      return;
    }
    setState(() {
      _comments.putIfAbsent(reviewId, () => []).add(comment);
      _reply.clear();
      _sending = false;
    });
    widget.onCommentAdded(comment);
  }

  Future<void> _reloadComments() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    await Future.wait(
      widget.reviews.map((review) async {
        final result = await widget.repository.getComments(review.id);
        final comments = result.dataOrNull;
        if (comments != null) _comments[review.id] = comments;
      }),
    );
    if (mounted) setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: PromoColors.purple,
        foregroundColor: Colors.white,
        title: const Text('Reseñas'),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _reloadComments,
            child: widget.reviews.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 180),
                      Center(child: Text('Sin reseñas todavía')),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.reviews.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final review = widget.reviews[index];
                      final comments = _comments[review.id] ?? const [];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                review.userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${'★' * review.rating}${'☆' * (5 - review.rating)}',
                              ),
                              const SizedBox(height: 6),
                              Text(review.comment),
                              const SizedBox(height: 8),
                              Text('${review.likeCount} likes'),
                              for (final comment in comments)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 10,
                                    left: 12,
                                  ),
                                  child: Text(
                                    '${comment.userName}: ${comment.comment}',
                                  ),
                                ),
                              if (!_comments.containsKey(review.id))
                                TextButton(
                                  onPressed: _refreshing
                                      ? null
                                      : _reloadComments,
                                  child: const Text('Reintentar respuestas'),
                                ),
                              if (widget.canReply)
                                TextButton(
                                  onPressed: () => setState(() {
                                    _selectedReviewId = review.id;
                                  }),
                                  child: const Text('Responder'),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_refreshing) const LinearProgressIndicator(),
        ],
      ),
      bottomNavigationBar: !widget.canReply || widget.reviews.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('reply-field'),
                        controller: _reply,
                        decoration: const InputDecoration(
                          hintText: 'Responder al cliente',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton.filled(
                      key: const Key('send-reply'),
                      onPressed: _sending ? null : _send,
                      icon: _sending
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
