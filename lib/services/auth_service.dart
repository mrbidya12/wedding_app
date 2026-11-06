import 'package:weddingpro_connect/services/api_service.dart';
import '../models/user_model.dart';
import 'dart:async';

class AuthService {
  // Checks if the user has an admin email (optional)
  bool _isAdminEmail(String? email) {
    if (email == null) return false;
    final adminEmails = ['admin@gmail.com', 'razz@gmail.com', 'bichitra@gmail.com'];
    return adminEmails.contains(email.toLowerCase().trim());
  }

  // ================================================================
  // SIGN UP – MATCHES SERVER REQUIREMENTS
  // ================================================================
  Future<AppUser?> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required UserRole role,
    required String country,
    required String state,
    required String city,
    required String block,          // was 'village' – renamed
    required String pincode,
    String? category,               // optional for vendors
    String? yearsOfExperience,      // was 'experience' – renamed
    int? minPrice,
    int? maxPrice,
  }) async {
    try {
      final Map<String, dynamic> userData = {
        'email': email.trim().toLowerCase(),
        'password': password,
        'name': fullName,
        'phone': phone,
        'role': role == UserRole.serviceProvider ? 'vendor' : role.name,
        'country': country,
        'state': state,
        'city': city,
        'block': block,
        'pincode': pincode,
      };

      // Vendor-specific optional fields
      if (role == UserRole.serviceProvider) {
        if (category != null) userData['category'] = category;
        if (yearsOfExperience != null) userData['yearsOfExperience'] = yearsOfExperience;
        if (minPrice != null) userData['minPrice'] = minPrice;
        if (maxPrice != null) userData['maxPrice'] = maxPrice;
      }

      final success = await ApiService.post('/users/register', body: userData);

      if (success != null) {
        // Auto-login after successful registration
        return await signInWithEmail(email, password);
      }
      return null;
    } catch (e) {
      throw e.toString();
    }
  }

  // ================================================================
  // SIGN IN
  // ================================================================
  Future<AppUser?> signInWithEmail(String email, String password) async {
    try {
      final response = await ApiService.post('/users/login', body: {
        'email': email.trim().toLowerCase(),
        'password': password,
      });

      if (response != null && response['token'] != null) {
        final user = AppUser.fromJson(response['user']);
        await ApiService.saveUserData(response['user'], response['token']);
        return user;
      }
      return null;
    } catch (e) {
      throw "Invalid email or password.";
    }
  }

  // ================================================================
  // SIGNOUT & SESSION
  // ================================================================
  Future<void> signOut() async {
    await ApiService.clearAuth();
  }

  Future<AppUser?> getCurrentUser() async {
    final userMap = await ApiService.getStoredUser();
    if (userMap != null) {
      return AppUser.fromJson(userMap);
    }
    return null;
  }
}