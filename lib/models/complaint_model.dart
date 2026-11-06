import 'package:intl/intl.dart';

class Complaint {
  final String id;
  final String clientId;
  final String vendorId;
  final String vendorName;
  final String description;
  final String? imageUrl;
  final DateTime createdAt;
  final String status;

  Complaint({
    required this.id,
    required this.clientId,
    required this.vendorId,
    required this.vendorName,
    required this.description,
    this.imageUrl,
    required this.createdAt,
    this.status = 'pending',
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id']?.toString() ?? '',
      clientId: json['client_id']?.toString() ?? '',
      vendorId: json['vendor_id']?.toString() ?? '',
      vendorName: json['vendor_name'] ?? 'Unknown Vendor',
      description: json['description'] ?? '',
      imageUrl: json['image_url'],
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      status: json['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'vendor_id': vendorId,
      'vendor_name': vendorName,
      'description': description,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'status': status,
    };
  }

  String get formattedDate => DateFormat('dd MMM yyyy, hh:mm a').format(createdAt);
}
