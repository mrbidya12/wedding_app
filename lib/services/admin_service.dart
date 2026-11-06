import 'api_service.dart';
import '../models/complaint_model.dart';

class AdminService {
  // View all payments
  static Future<List<dynamic>> getAllPayments() async {
    return await ApiService.get('/admin/payments');
  }

  // View pending payouts
  static Future<List<dynamic>> getPendingPayouts() async {
    return await ApiService.get('/admin/pending-payouts');
  }

  // Process a payout
  static Future<Map<String, dynamic>> processPayout(String paymentId, String adminUpiId, String upiPin) async {
    return await ApiService.post('/admin/process-payout', body: {
      'paymentId': paymentId,
      'adminUpiId': adminUpiId,
      'upiPin': upiPin,
    });
  }

  // View all complaints
  static Future<List<Complaint>> getAllComplaints() async {
    final response = await ApiService.get('/admin/complaints');
    if (response is List) {
      return response.map((c) => Complaint.fromJson(c as Map<String, dynamic>)).toList();
    }
    return [];
  }

  // View refund requests
  static Future<List<dynamic>> getRefunds() async {
    return await ApiService.get('/admin/refunds');
  }

  // Process refund (approve/reject)
  static Future<void> processRefund(String refundId, String status) async {
    await ApiService.post('/admin/refund/$refundId/process', body: {'status': status});
  }

  // View pending cancellations
  static Future<List<dynamic>> getPendingCancellations() async {
    return await ApiService.get('/admin/cancellations/pending');
  }

  // Process cancellation (approve/reject)
  static Future<void> processCancellation(String cancellationId, String action) async {
    await ApiService.post('/admin/cancellations/$cancellationId/process', body: {'action': action});
  }

  // Admin view all vendors (for approval)
  static Future<List<dynamic>> getAllVendors() async {
    return await ApiService.get('/admin/vendors');
  }
}
