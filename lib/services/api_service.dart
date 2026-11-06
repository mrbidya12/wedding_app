import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class ApiService {
  static const _storage = FlutterSecureStorage();
  static const String _userKey = 'user_data';
  
  static const Duration timeoutDuration = Duration(seconds: 15); 

  // --- GENERIC HTTP HELPERS ---
  static Future<String?> getToken() async => await _storage.read(key: 'jwt_token');

  static Future<dynamic> get(String endpoint) async {
    final token = await getToken();
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token'
        },
      ).timeout(timeoutDuration);
      return _handleResponse(response);
    } on TimeoutException {
      return null; 
    } catch (e) {
      return null;
    }
  }

  static Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    final token = await getToken();
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: body != null ? jsonEncode(body) : null,
      ).timeout(timeoutDuration);
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  static Future<dynamic> put(String endpoint, {Map<String, dynamic>? body}) async {
    final token = await getToken();
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: body != null ? jsonEncode(body) : null,
      ).timeout(timeoutDuration);
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  static Future<dynamic> patch(String endpoint, {Map<String, dynamic>? body}) async {
    final token = await getToken();
    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: body != null ? jsonEncode(body) : null,
      ).timeout(timeoutDuration);
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      throw Exception('Server Error: ${response.statusCode}');
    }
  }

  // --- STORAGE HELPERS ---
  static Future<void> saveUserData(Map<String, dynamic> user, String token) async {
    await _storage.write(key: 'jwt_token', value: token);
    await _storage.write(key: _userKey, value: jsonEncode(user));
  }

  static Future<Map<String, dynamic>?> getStoredUser() async {
    final userJson = await _storage.read(key: _userKey);
    return userJson != null ? jsonDecode(userJson) : null;
  }

  static Future<void> clearAuth() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: _userKey);
  }
}
