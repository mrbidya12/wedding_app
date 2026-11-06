class Vendor {
  final String id;
  final String name;
  final String category;
  final double rating;
  final int reviewCount;
  final String description;
  final List<String> tags;
  final int minPrice;
  final int? maxPrice;
  final int yearsOfExperience; 
  final String imageUrl;
  final String country;
  final String state;
  final String city;
  final String block;
  final String pincode;
  final List<String> portfolio;
  final int weddingsCount;
  final int satisfactionRate;
  final String status;
  final int viewsCount;

  Vendor({
    required this.id,
    required this.name,
    required this.category,
    required this.rating,
    required this.reviewCount,
    this.description = '',
    required this.tags,
    required this.minPrice,
    this.maxPrice,
    this.yearsOfExperience = 0,
    required this.imageUrl,
    this.country = 'India',
    required this.state,
    required this.city,
    required this.block,
    required this.pincode,
    this.portfolio = const [],
    this.weddingsCount = 0,
    this.satisfactionRate = 100,
    this.status = 'Online',
    this.viewsCount = 0,
  });

  factory Vendor.fromFirestore(Map<String, dynamic> data, String id) {
    return Vendor(
      id: id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      description: data['description'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      minPrice: data['minPrice'] ?? 0,
      maxPrice: data['maxPrice'],
      yearsOfExperience: data['yearsOfExperience'] ?? data['experience'] ?? 0,
      imageUrl: data['imageUrl'] ?? '',
      country: data['country'] ?? 'India',
      state: data['state'] ?? '',
      city: data['city'] ?? '',
      block: data['block'] ?? data['village'] ?? '',
      pincode: data['pincode'] ?? '',
      portfolio: List<String>.from(data['portfolio'] ?? []),
      weddingsCount: data['weddingsCount'] ?? 0,
      satisfactionRate: data['satisfactionRate'] ?? 100,
      status: data['status'] ?? 'Online',
      viewsCount: data['viewsCount'] ?? 0,
    );
  }

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? json['review_count'] ?? 0,
      description: json['description'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      minPrice: json['minPrice'] ?? json['min_price'] ?? 0,
      maxPrice: json['maxPrice'] ?? json['max_price'],
      yearsOfExperience: json['yearsOfExperience'] ?? json['experience'] ?? 0,
      imageUrl: json['imageUrl'] ?? json['image_url'] ?? '',
      country: json['country'] ?? 'India',
      state: json['state'] ?? '',
      city: json['city'] ?? '',
      block: json['block'] ?? json['village'] ?? '',
      pincode: json['pincode'] ?? '',
      portfolio: List<String>.from(json['portfolio'] ?? []),
      weddingsCount: json['weddingsCount'] ?? 0,
      satisfactionRate: json['satisfactionRate'] ?? 100,
      status: json['status'] ?? 'Online',
      viewsCount: json['viewsCount'] ?? 0,
    );
  }
}
