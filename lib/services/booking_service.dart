import 'api_service.dart';
import '../models/booking_model.dart';

class BookingService {
  // Create a booking
  static Future<Map<String, dynamic>> createBooking(Map<String, dynamic> bookingData) async {
    final response = await ApiService.post('/bookings', body: bookingData);
    return response ?? {};
  }

  // List bookings
  static Future<List<dynamic>> getBookings({String? status, String? vendorId}) async {
    String url = '/bookings';
    final params = <String>[];
    if (status != null) params.add('status=$status');
    if (vendorId != null) params.add('vendor_id=$vendorId');
    if (params.isNotEmpty) url += '?${params.join('&')}';
    
    final response = await ApiService.get(url);
    return response is List ? response : [];
  }

  // Get current user's bookings
  static Future<List<Booking>> getMyBookings() async {
    final response = await getBookings();
    return response.map((json) => Booking.fromJson(json as Map<String, dynamic>)).toList();
  }

  // Get booking counts
  static Future<Map<String, int>> getBookingCounts() async {
    final response = await ApiService.get('/bookings/counts');
    if (response != null && response is Map) {
      return response.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
    }
    return {'total': 0, 'confirmed': 0, 'pending': 0};
  }

  // Get a single booking
  static Future<Map<String, dynamic>> getBooking(String bookingId) async {
    final response = await ApiService.get('/bookings/$bookingId');
    return response ?? {};
  }

  // Confirm booking
  static Future<void> confirmBooking(String bookingId) async {
    await ApiService.put('/bookings/$bookingId/confirm');
  }

  // Client cancels
  static Future<Map<String, dynamic>> cancelClient(String bookingId, String reason) async {
    final response = await ApiService.post('/bookings/$bookingId/cancel-client', body: {'reason': reason});
    return response ?? {};
  }

  // Vendor cancels
  static Future<Map<String, dynamic>> cancelVendor(String bookingId, String reason) async {
    final response = await ApiService.post('/bookings/$bookingId/cancel-vendor', body: {'reason': reason});
    return response ?? {};
  }
}
