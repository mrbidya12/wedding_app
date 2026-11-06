import 'package:weddingpro_connect/models/user_model.dart';
import 'package:weddingpro_connect/models/vendor_model.dart';
import 'package:weddingpro_connect/models/booking_model.dart';
import 'package:weddingpro_connect/services/user_service.dart';
import 'package:weddingpro_connect/services/vendor_service.dart';
import 'package:weddingpro_connect/services/booking_service.dart';
import 'dart:async';

class FirestoreService {
  /// NOTE: This class now acts as a COMPATIBILITY BRIDGE to your Node.js backend.
  /// Standard REST APIs use Future instead of Stream. 
  /// Replace StreamBuilder with FutureBuilder in your UI files.

  // --- ADMIN STATISTICS ---
  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      return await UserService.getSystemStats();
    } catch (e) {
      print("❌ [Bridge] Admin Stats Error: $e");
      return {'total': 0, 'clients': 0, 'providers': 0, 'admins': 0};
    }
  }

  // --- USER PROFILE METHODS ---
  Future<AppUser?> getUserProfile(String uid) async {
    try {
      return await UserService.getProfileById(uid);
    } catch (e) {
      print("❌ [Bridge] Get User Error: $e");
      return null;
    }
  }

  Future<void> updateUserProfile(AppUser user) async {
    try {
      await UserService.updateProfile(user);
    } catch (e) {
      print("❌ [Bridge] Update Profile Error: $e");
    }
  }

  Future<List<AppUser>> getAllUsers() async {
    try {
      return await UserService.getAllUsers();
    } catch (e) {
      print("❌ [Bridge] Get All Users Error: $e");
      return [];
    }
  }

  // --- BOOKING METHODS ---
  Future<Map<String, int>> getBookingCounts(String userId) async {
    try {
      return await BookingService.getBookingCounts();
    } catch (e) { 
      print("❌ [Bridge] Booking Counts Error: $e");
      return {'total': 0, 'confirmed': 0, 'pending': 0}; 
    }
  }

  Future<List<Booking>> getUserBookings(String userId) async {
    try {
      return await BookingService.getMyBookings();
    } catch (e) {
      print("❌ [Bridge] Get Bookings Error: $e");
      return [];
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    try {
      await BookingService.cancelClient(bookingId, "Cancelled via mobile app");
    } catch (e) {
      print("❌ [Bridge] Cancel Booking Error: $e");
    }
  }

  // --- VENDOR METHODS ---
  Future<List<Vendor>> getVendors({
    String? searchQuery, 
    String? category, 
    String? country,
    String? state, 
    String? city,
    String? village,
  }) async {
    try {
      final response = await VendorService.getVendors(category: category);
      if (response == null) return [];
      
      final List<Vendor> vendors = (response as List<dynamic>)
          .map((v) => Vendor.fromJson(v as Map<String, dynamic>))
          .toList();

      List<Vendor> filtered = vendors;

      if (searchQuery != null && searchQuery.isNotEmpty) {
        filtered = filtered.where((v) => v.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();
      }
      if (state != null && state.isNotEmpty) {
        filtered = filtered.where((v) => v.state == state).toList();
      }
      if (city != null && city.isNotEmpty) {
        filtered = filtered.where((v) => v.city == city).toList();
      }
      if (village != null && village.isNotEmpty) {
        filtered = filtered.where((v) => v.block == village).toList();
      }
      if (country != null && country.isNotEmpty) {
        filtered = filtered.where((v) => v.country == country).toList();
      }
      
      return filtered;
    } catch (e) {
      print("❌ [Bridge] Get Vendors Error: $e");
      return [];
    }
  }

  Future<int> getRawVendorCount() async {
    try {
      final vendors = await VendorService.getVendors();
      return vendors.length;
    } catch (e) {
      return 0;
    }
  }
}
