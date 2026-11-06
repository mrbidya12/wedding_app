enum BookingStatus { pending, confirmed, cancelled }

class Booking {
  final String id;
  final String userId;
  final String vendorId;
  final String vendorName;
  final String vendorCategory;
  final String note;
  final int price;
  final DateTime createdAt;
  final BookingStatus status;

  Booking({
    required this.id,
    required this.userId,
    required this.vendorId,
    required this.vendorName,
    required this.vendorCategory,
    required this.note,
    required this.price,
    required this.createdAt,
    required this.status,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      vendorId: json['vendorId'] ?? json['vendor_id'] ?? '',
      vendorName: json['vendorName'] ?? json['vendor_name'] ?? 'Vendor',
      vendorCategory: json['vendorCategory'] ?? json['vendor_category'] ?? 'Service',
      note: json['note'] ?? json['notes'] ?? '',
      price: (json['price'] ?? 0).toInt(),
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      status: _stringToStatus(json['status'] ?? 'pending'),
    );
  }

  static BookingStatus _stringToStatus(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'cancelled':
        return BookingStatus.cancelled;
      default:
        return BookingStatus.pending;
    }
  }

  // Simplified factory for server data
  factory Booking.fromMap(Map<String, dynamic> data, String id) {
    return Booking.fromJson({...data, 'id': id});
  }
}
