import 'api_service.dart';

class PaymentService {
  // Vendor requests payment
  static Future<Map<String, dynamic>> requestPayment(String clientId, String bookingId, double amount) async {
    return await ApiService.post('/payments/request', body: {
      'clientId': clientId,
      'bookingId': bookingId,
      'amount': amount,
    });
  }

  // Admin confirms payment
  static Future<void> confirmPayment(String paymentId) async {
    await ApiService.post('/payments/$paymentId/confirm');
  }

  // Vendor starts work (OTP sent to client)
  static Future<void> startWork(String bookingId, {double? lat, double? lng}) async {
    await ApiService.post('/vendor/start-work', body: {
      'bookingId': bookingId,
      'latitude': lat,
      'longitude': lng,
    });
  }

  // Vendor confirms start (enters OTP)
  static Future<void> confirmStart(String bookingId, String otp, {int duration = 2}) async {
    await ApiService.post('/vendor/confirm-start', body: {
      'bookingId': bookingId,
      'otp': otp,
      'duration': duration,
    });
  }

  // Vendor completes work (sends second OTP)
  static Future<void> completeWorkOtp(String bookingId) async {
    await ApiService.post('/vendor/complete-work-otp', body: {'bookingId': bookingId});
  }

  // Vendor confirms completion (enters second OTP)
  static Future<Map<String, dynamic>> confirmCompletion(String bookingId, String otp) async {
    return await ApiService.post('/vendor/confirm-completion', body: {
      'bookingId': bookingId,
      'otp': otp,
    });
  }

  // Client refund request
  static Future<Map<String, dynamic>> requestRefund(String paymentId, String reason) async {
    return await ApiService.post('/client/refund', body: {
      'paymentId': paymentId,
      'reason': reason,
    });
  }

  // Vendor UPI update
  static Future<void> updateVendorUpi(String upiId, String upiName) async {
    await ApiService.put('/vendor/upi', body: {
      'upiId': upiId,
      'upiName': upiName,
    });
  }

  // Vendor payment history
  static Future<List<dynamic>> getVendorPayments() async {
    return await ApiService.get('/vendor/payments');
  }

  // Vendor payout history
  static Future<List<dynamic>> getVendorPayoutHistory() async {
    return await ApiService.get('/vendor/payout-history');
  }

  // Client payment history
  static Future<List<dynamic>> getClientPayments() async {
    return await ApiService.get('/client/payments');
  }

  // Client verifies OTP (releases payment)
  static Future<void> verifyOtp(String bookingId, String otp) async {
    await ApiService.post('/client/verify-otp', body: {
      'bookingId': bookingId,
      'otp': otp,
    });
  }
}
