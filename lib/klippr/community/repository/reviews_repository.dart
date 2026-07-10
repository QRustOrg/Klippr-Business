import '../../shared/data/network/api_client.dart';
import '../../shared/data/network/api_exceptions.dart';
import '../../shared/data/network/result.dart';
import '../domain/models/review.dart';
import '../domain/models/review_comment.dart';

class ReviewsRepository {
  ReviewsRepository(this._api);

  final ApiClient _api;
  static const String _base = '/api/reviews';

  Future<Result<List<Review>>> getReviews({
    String? promotionId,
    String? userId,
  }) async {
    final result = await _api.get(
      _base,
      query: {
        if (promotionId != null && promotionId.isNotEmpty)
          'promotionId': promotionId,
        if (userId != null && userId.isNotEmpty) 'userId': userId,
      },
    );
    return result.when(
      onSuccess: (json) => _reviewList(json),
      onFailure: (error) => Failure<List<Review>>(error),
    );
  }

  Future<Result<List<ReviewComment>>> getComments(String reviewId) async {
    final result = await _api.get('$_base/$reviewId/comments');
    return result.when(
      onSuccess: (json) => _commentList(json),
      onFailure: (error) => Failure<List<ReviewComment>>(error),
    );
  }

  Future<Result<ReviewComment>> addComment(
    String reviewId,
    String comment,
  ) async {
    final result = await _api.post(
      '$_base/$reviewId/comments',
      body: {'comment': comment.trim()},
    );
    return result.when(
      onSuccess: (json) => json is Map
          ? Success(
              ReviewComment.fromJson(Map<String, dynamic>.from(json)),
            )
          : const Failure(ParseException()),
      onFailure: (error) => Failure<ReviewComment>(error),
    );
  }

  Result<List<Review>> _reviewList(dynamic json) {
    if (json is! List) return const Failure(ParseException());
    return Success(
      json
          .whereType<Map>()
          .map((item) => Review.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false),
    );
  }

  Result<List<ReviewComment>> _commentList(dynamic json) {
    if (json is! List) return const Failure(ParseException());
    return Success(
      json
          .whereType<Map>()
          .map(
            (item) => ReviewComment.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
    );
  }
}
