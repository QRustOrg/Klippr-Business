class Review {
  const Review({
    required this.id,
    required this.promotionId,
    required this.promotionTitle,
    required this.businessName,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.verified,
    required this.likeCount,
    this.promotionImage,
    this.userAvatar,
    this.likedByCurrentUser = false,
  });

  final String id;
  final String promotionId;
  final String promotionTitle;
  final String? promotionImage;
  final String businessName;
  final String userId;
  final String userName;
  final String? userAvatar;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final bool verified;
  final int likeCount;
  final bool likedByCurrentUser;

  factory Review.fromJson(Map<String, dynamic> json) => Review(
    id: json['id']?.toString() ?? '',
    promotionId: json['promotionId']?.toString() ?? '',
    promotionTitle: json['promotionTitle']?.toString() ?? '',
    promotionImage: json['promotionImage']?.toString(),
    businessName: json['businessName']?.toString() ?? '',
    userId: json['userId']?.toString() ?? '',
    userName: json['userName']?.toString() ?? '',
    userAvatar: json['userAvatar']?.toString(),
    rating: (json['rating'] as num?)?.toInt() ?? 0,
    comment: json['comment']?.toString() ?? '',
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      (json['createdAt'] as num?)?.toInt() ?? 0,
    ),
    verified: json['verified'] as bool? ?? false,
    likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
    likedByCurrentUser: json['likedByCurrentUser'] as bool? ?? false,
  );
}
