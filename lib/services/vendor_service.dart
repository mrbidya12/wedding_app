import 'api_service.dart';
import '../models/complaint_model.dart';
import '../models/vendor_model.dart';
import 'dart:async';

class VendorService {
  static final List<Vendor> _dummyVendors = [
    Vendor(
      id: 'mock1', name: 'Royal Wedding Decor', category: 'Florist', rating: 4.9, reviewCount: 128,
      description: 'Award-winning wedding decorations capturing timeless moments with artistic vision.',
      tags: ['Luxury', 'Grand'], minPrice: 50000, maxPrice: 500000, yearsOfExperience: 8,
      imageUrl: 'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?w=800',
      portfolio: [],
      state: 'Odisha', city: 'Bhubaneswar', block: 'Nayapalli', pincode: '751012',
      weddingsCount: 245, satisfactionRate: 98, status: 'Online',
    ),
    Vendor(
      id: 'mock2', name: 'Elite Catering', category: 'Catering', rating: 4.9, reviewCount: 150,
      description: 'Gourmet dining experiences and bespoke wedding cakes.',
      tags: ['Gourmet'], minPrice: 800, maxPrice: 2500, yearsOfExperience: 10,
      imageUrl: 'https://images.unsplash.com/photo-1530101978244-671bf320edc0?w=800',
      state: 'Odisha', city: 'Bhubaneswar', block: 'Saheed Nagar', pincode: '751007',
      weddingsCount: 320, satisfactionRate: 99, status: 'Online',
    ),
  ];

  static List<Vendor> getLocalVendors() => List.from(_dummyVendors);

  static Future<List<Vendor>> getVendors({String? category, String? query}) async {
    List<Vendor> vendors = List.from(_dummyVendors);
    final Map<String, String> params = {};
    if (category != null && category != 'All') params['category'] = category;
    if (query != null && query.isNotEmpty) params['search'] = query;
    
    try {
      final response = await ApiService.get('/vendors');
      if (response is List) {
        final serverVendors = response.map((v) => Vendor.fromJson(v as Map<String, dynamic>)).toList();
        vendors.addAll(serverVendors);
      }
    } catch (e) {
      print('Load error: $e');
    }

    if (category != null && category != 'All') {
      vendors = vendors.where((v) => v.category.toLowerCase().contains(category.toLowerCase())).toList();
    }
    if (query != null && query.isNotEmpty) {
      vendors = vendors.where((v) => v.name.toLowerCase().contains(query.toLowerCase())).toList();
    }

    final ids = <String>{};
    vendors.retainWhere((x) => ids.add(x.id));
    return vendors;
  }

  static Future<Map<String, dynamic>> getVendor(String vendorId) async {
    final response = await ApiService.get('/vendors/$vendorId');
    return response is Map<String, dynamic> ? response : {};
  }

  static Future<Map<String, dynamic>> createVendor(Map<String, dynamic> data) async {
    final response = await ApiService.post('/vendors', body: data);
    return response is Map<String, dynamic> ? response : {};
  }

  static Future<Map<String, dynamic>> updateVendor(String vendorId, Map<String, dynamic> data) async {
    final response = await ApiService.put('/vendors/$vendorId', body: data);
    return response is Map<String, dynamic> ? response : {};
  }

  static Future<void> approveVendor(String vendorId) async {
    await ApiService.patch('/vendors/$vendorId/approve', body: {'approved': true});
  }

  static Future<List<Complaint>> getMyComplaints() async {
    final response = await ApiService.get('/complaints/my');
    if (response is List) {
      return response.map((c) => Complaint.fromJson(c as Map<String, dynamic>)).toList();
    }
    return [];
  }

  static Future<bool> submitComplaint({
    required String vendorId,
    required String vendorName,
    required String description,
    String? imageUrl,
  }) async {
    final response = await ApiService.post('/complaints', body: {
      'vendor_id': vendorId,
      'vendor_name': vendorName,
      'description': description,
      'image_url': imageUrl,
    });
    return response != null;
  }
}
