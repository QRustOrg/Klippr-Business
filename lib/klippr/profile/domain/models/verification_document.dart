class VerificationDocument {
  const VerificationDocument({
    required this.profileId,
    required this.documentUrl,
  });

  final String profileId;
  final String documentUrl;

  Map<String, dynamic> toJson() => {
    'profileId': profileId,
    'documentUrl': documentUrl,
  };
}
