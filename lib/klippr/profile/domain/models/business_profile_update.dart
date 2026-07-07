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

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': profileId,
      'profileId': profileId,
    };

    if (businessName != null && businessName!.isNotEmpty) {
      json['businessName'] = businessName;
    }

    if (category != null && category!.isNotEmpty) {
      json['category'] = {'name': category};
    }

    if (description != null && description!.isNotEmpty) {
      json['description'] = description;
    }

    final location = <String, dynamic>{};
    if (street != null && street!.isNotEmpty) location['street'] = street;
    if (city != null && city!.isNotEmpty) location['city'] = city;
    if (state != null && state!.isNotEmpty) location['state'] = state;
    if (country != null && country!.isNotEmpty) location['country'] = country;
    if (zipCode != null && zipCode!.isNotEmpty) location['postalCode'] = zipCode;

    if (location.isNotEmpty) {
      json['location'] = location;
    }

    return json;
  }
}
