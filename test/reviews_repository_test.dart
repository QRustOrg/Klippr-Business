import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:klippr/klippr/community/domain/models/promotion_feedback_metrics.dart';
import 'package:klippr/klippr/community/domain/models/review.dart';
import 'package:klippr/klippr/community/domain/models/review_comment.dart';
import 'package:klippr/klippr/community/repository/reviews_repository.dart';
import 'package:klippr/klippr/shared/data/network/api_client.dart';
import 'package:klippr/klippr/shared/data/pref/prefs_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'getReviews sends optional filters and parses the live contract',
    () async {
      SharedPreferences.setMockInitialValues({'session_token': 'token'});
      final prefs = PrefsHelper.test(await SharedPreferences.getInstance());
      final client = MockClient((request) async {
        expect(request.url.path, '/api/reviews');
        expect(request.url.queryParameters, {
          'promotionId': 'promo-1',
          'userId': 'user-1',
        });
        return http.Response(
          '[{"id":"review-1","promotionId":"promo-1",'
          '"promotionTitle":"Pizza 2x1","promotionImage":"comida_pizza",'
          '"businessName":"Klippr Cafe","userId":"user-1",'
          '"userName":"Ana","userAvatar":null,"rating":4,'
          '"comment":"Muy buena","createdAt":1783695614354,'
          '"verified":true,"likeCount":3,"likedByCurrentUser":false}]',
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final repository = ReviewsRepository(
        ApiClient(client: client, prefs: prefs),
      );

      final result = await repository.getReviews(
        promotionId: 'promo-1',
        userId: 'user-1',
      );
      final review = result.dataOrNull!.single;

      expect(review.id, 'review-1');
      expect(review.promotionTitle, 'Pizza 2x1');
      expect(review.createdAt.millisecondsSinceEpoch, 1783695614354);
      expect(review.likeCount, 3);
      expect(review.verified, isTrue);
    },
  );

  test('comments are parsed and a trimmed reply is posted', () async {
    SharedPreferences.setMockInitialValues({'session_token': 'token'});
    final prefs = PrefsHelper.test(await SharedPreferences.getInstance());
    var call = 0;
    final client = MockClient((request) async {
      call += 1;
      expect(request.url.path, '/api/reviews/review-1/comments');
      if (call == 1) {
        expect(request.method, 'GET');
        return http.Response(
          '[{"id":"comment-1","reviewId":"review-1",'
          '"userId":"business-1","userName":"Cafe",'
          '"comment":"Gracias","createdAt":"2026-07-10T12:30:00Z"}]',
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      expect(request.method, 'POST');
      expect(jsonDecode(request.body), {'comment': 'Vuelve pronto'});
      return http.Response(
        '{"id":"comment-2","reviewId":"review-1",'
        '"userId":"business-1","userName":"Cafe",'
        '"comment":"Vuelve pronto","createdAt":"2026-07-10T12:35:00Z"}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final repository = ReviewsRepository(
      ApiClient(client: client, prefs: prefs),
    );

    final comments = await repository.getComments('review-1');
    final added = await repository.addComment('review-1', '  Vuelve pronto  ');

    expect(comments.dataOrNull!.single.comment, 'Gracias');
    expect(added.dataOrNull!.id, 'comment-2');
  });

  test('promotion feedback keeps reviews and replies as separate metrics', () {
    final reviews = [
      Review(
        id: 'r1',
        promotionId: 'p1',
        promotionTitle: 'Promo',
        businessName: 'Cafe',
        userId: 'u1',
        userName: 'Ana',
        rating: 5,
        comment: 'Excelente',
        createdAt: DateTime.utc(2026, 7, 10),
        verified: true,
        likeCount: 2,
      ),
      Review(
        id: 'r2',
        promotionId: 'p1',
        promotionTitle: 'Promo',
        businessName: 'Cafe',
        userId: 'u2',
        userName: 'Luis',
        rating: 3,
        comment: 'Regular',
        createdAt: DateTime.utc(2026, 7, 9),
        verified: false,
        likeCount: 1,
      ),
    ];
    final comments = {
      'r1': [
        ReviewComment(
          id: 'c1',
          reviewId: 'r1',
          userId: 'business-1',
          userName: 'Cafe',
          comment: 'Gracias',
          createdAt: DateTime.utc(2026, 7, 10),
        ),
      ],
      'r2': <ReviewComment>[],
    };

    final metrics = PromotionFeedbackMetrics.fromReviews(
      reviews: reviews,
      commentsByReview: comments,
      redemptions: 9,
    );

    expect(metrics.redemptions, 9);
    expect(metrics.reviewCount, 2);
    expect(metrics.averageRating, 4);
    expect(metrics.likeCount, 3);
    expect(metrics.replyCount, 1);
  });

  test('promotion feedback has no average when there are no reviews', () {
    final metrics = PromotionFeedbackMetrics.fromReviews(
      reviews: const [],
      commentsByReview: const {},
    );

    expect(metrics.reviewCount, 0);
    expect(metrics.averageRating, isNull);
    expect(metrics.likeCount, 0);
    expect(metrics.replyCount, 0);
    expect(metrics.redemptions, isNull);
  });
}
