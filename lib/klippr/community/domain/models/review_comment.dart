class ReviewComment {
  const ReviewComment({
    required this.id,
    required this.reviewId,
    required this.userId,
    required this.userName,
    required this.comment,
    required this.createdAt,
  });

  final String id;
  final String reviewId;
  final String userId;
  final String userName;
  final String comment;
  final DateTime createdAt;

  factory ReviewComment.fromJson(Map<String, dynamic> json) => ReviewComment(
    id: json['id']?.toString() ?? '',
    reviewId: json['reviewId']?.toString() ?? '',
    userId: json['userId']?.toString() ?? '',
    userName: json['userName']?.toString() ?? '',
    comment: json['comment']?.toString() ?? '',
    createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );
}
