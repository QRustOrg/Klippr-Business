import 'review.dart';
import 'review_comment.dart';

class PromotionFeedbackMetrics {
  const PromotionFeedbackMetrics({
    required this.redemptions,
    required this.reviewCount,
    required this.averageRating,
    required this.likeCount,
    required this.replyCount,
  });

  final int? redemptions;
  final int reviewCount;
  final double? averageRating;
  final int likeCount;
  final int replyCount;

  factory PromotionFeedbackMetrics.fromReviews({
    required List<Review> reviews,
    required Map<String, List<ReviewComment>> commentsByReview,
    int? redemptions,
  }) {
    final ratingTotal = reviews.fold<int>(0, (sum, review) => sum + review.rating);
    final likes = reviews.fold<int>(0, (sum, review) => sum + review.likeCount);
    final replies = reviews.fold<int>(
      0,
      (sum, review) => sum + (commentsByReview[review.id]?.length ?? 0),
    );
    return PromotionFeedbackMetrics(
      redemptions: redemptions,
      reviewCount: reviews.length,
      averageRating: reviews.isEmpty ? null : ratingTotal / reviews.length,
      likeCount: likes,
      replyCount: replies,
    );
  }
}
