enum UserRole { client, serviceProvider, admin }

class AppUser {
  final String uid;
  final String email;
  String fullName;
  String phone;
  DateTime? weddingDate;
  DateTime? createdAt;
  String country;
  String state;
  String city;
  String block;
  String pincode;
  UserRole role;
  bool isBlocked;

  AppUser({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.phone,
    this.weddingDate,
    this.createdAt,
    required this.country,
    required this.state,
    required this.city,
    required this.block,
    required this.pincode,
    required this.role,
    this.isBlocked = false,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic date) {
      if (date == null) return null;
      return DateTime.tryParse(date.toString());
    }

    String roleStr = (json['role'] ?? 'client').toString().toLowerCase().trim();
    UserRole parsedRole = UserRole.client;
    if (roleStr.contains('admin')) {
      parsedRole = UserRole.admin;
    } else if (roleStr.contains('provider') || roleStr.contains('service') || roleStr.contains('vendor')) {
      parsedRole = UserRole.serviceProvider;
    }

    return AppUser(
      uid: json['id']?.toString() ?? json['uid']?.toString() ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? json['full_name'] ?? json['name'] ?? 'User',
      phone: json['phone'] ?? '',
      weddingDate: parseDate(json['weddingDate'] ?? json['wedding_date']),
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
      country: json['country'] ?? 'India',
      state: json['state'] ?? '',
      city: json['city'] ?? '',
      block: json['block'] ?? json['village'] ?? '',
      pincode: json['pincode'] ?? '',
      role: parsedRole,
      isBlocked: json['is_blocked'] ?? json['blocked'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'weddingDate': weddingDate?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'country': country,
      'state': state,
      'city': city,
      'block': block,
      'pincode': pincode,
      'role': role.name,
      'is_blocked': isBlocked,
    };
  }

  Map<String, dynamic> toUpdateProfileMap() {
    return {
      'fullName': fullName,
      'phone': phone,
      'weddingDate': weddingDate?.toIso8601String(),
      'country': country,
      'state': state,
      'city': city,
      'block': block,
      'pincode': pincode,
    };
  }
}
