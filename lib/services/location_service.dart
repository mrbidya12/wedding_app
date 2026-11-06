import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class LocationService {
  static Timer? _timer;
  static bool isTracking = false;
  static String? _currentBookingId;

  static String? get currentBookingId => _currentBookingId;

  static Future<void> startTracking(String bookingId) async {
    _currentBookingId = bookingId;
    isTracking = true;

    // Request location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        isTracking = false;
        _currentBookingId = null;
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      isTracking = false;
      _currentBookingId = null;
      return;
    }

    // Start periodic location updates (every 30 seconds)
    _timer?.cancel(); 
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (!isTracking) {
        timer.cancel();
        return;
      }
      await _updateLocation();
    });

    // Send initial location
    await _updateLocation();
  }

  static Future<void> _updateLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await ApiService.post('/vendor/update-location', body: {
        'bookingId': _currentBookingId,
        'latitude': position.latitude,
        'longitude': position.longitude,
      });
    } catch (e) {
      debugPrint('Location update failed: $e');
    }
  }

  static void stopTracking() {
    isTracking = false;
    _timer?.cancel();
    _timer = null;
    _currentBookingId = null;
  }
}
