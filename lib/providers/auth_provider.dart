import 'dart:async';
import 'package:flutter/material.dart';
import 'package:weddingpro_connect/models/user_model.dart';
import 'package:weddingpro_connect/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  AppUser? _userData;
  bool _isLoading = false;
  String? _errorMessage;

  AppUser? get userData => _userData;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _userData != null;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _initializeUser();
  }

  // Load user from storage on startup
  Future<void> _initializeUser() async {
    _userData = await _authService.getCurrentUser();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final user = await _authService.signInWithEmail(email, password);
      if (user != null) {
        _userData = user;
        _setLoading(false);
        return true;
      } else {
        _errorMessage = "Invalid credentials";
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required UserRole role,
    required String country,
    required String state,
    required String city,
    required String block,
    required String pincode,
    String? category,
    String? yearsOfExperience,
    int? minPrice,
    int? maxPrice,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final user = await _authService.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        role: role,
        country: country,
        state: state,
        city: city,
        block: block,
        pincode: pincode,
        category: category,
        yearsOfExperience: yearsOfExperience,
        minPrice: minPrice,
        maxPrice: maxPrice,
      );

      if (user != null) {
        _userData = user;
        _setLoading(false);
        return true;
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    await _authService.signOut();
    _userData = null;
    _setLoading(false);
    notifyListeners();
  }

  void _setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }
}
