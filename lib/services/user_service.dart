import 'api_service.dart';
import '../models/user_model.dart';

class UserService {
  // Get current logged-in user profile
  static Future<AppUser?> getProfile() async {
    final response = await ApiService.get('/users/profile');
    if (response != null) {
      return AppUser.fromJson(response);
    }
    return null;
  }

  // Get a specific user profile by ID
  static Future<AppUser?> getProfileById(String uid) async {
    final response = await ApiService.get('/users/$uid');
    if (response != null) {
      return AppUser.fromJson(response);
    }
    return null;
  }

  // Update current user profile
  static Future<void> updateProfile(AppUser user) async {
    await ApiService.put('/users/profile', body: user.toUpdateProfileMap());
  }

  // --- ADMIN METHODS ---

  // List all users
  static Future<List<AppUser>> getAllUsers() async {
    final response = await ApiService.get('/admin/users');
    if (response is List) {
      return response.map((u) => AppUser.fromJson(u)).toList();
    }
    return [];
  }

  // Block/Unblock user
  static Future<void> toggleBlockUser(String userId, bool block) async {
    await ApiService.post('/admin/users/$userId/block', body: {'blocked': block});
  }

  // Get system statistics
  static Future<Map<String, dynamic>> getSystemStats() async {
    final response = await ApiService.get('/admin/stats');
    if (response != null) {
      return Map<String, dynamic>.from(response);
    }
    return {'total': 0, 'clients': 0, 'providers': 0};
  }
}
