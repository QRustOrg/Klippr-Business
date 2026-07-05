class BusinessProfileUpdate {
  const BusinessProfileUpdate({
    required this.profileId,
    this.businessName,
    this.category,
    this.description,
    this.street,
    this.city,
    this.state,
    this.country,
    this.zipCode,
  });

  final String profileId;
  final String? businessName;
  final String? category;
  final String? description;
  final String? street;
  final String? city;
  final String? state;
  final String? country;
  final String? zipCode;

  Map<String, dynamic> toJson() => {
    'profileId': profileId,
    'businessName': businessName,
    'category': category,
    'description': description,
    'street': street,
    'city': city,
    'state': state,
    'country': country,
    'zipCode': zipCode,
  };
}
