import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../models/user_model.dart';
import '../config/api_config.dart';

class ServerTestScreen extends StatefulWidget {
  const ServerTestScreen({super.key});

  @override
  State<ServerTestScreen> createState() => _ServerTestScreenState();
}

class _ServerTestScreenState extends State<ServerTestScreen> {
  final AuthService _authService = AuthService();
  String _status = "Idle";
  bool _isLoading = false;

  void _updateStatus(String status) {
    if (mounted) {
      setState(() {
        _status = status;
      });
    }
  }

  Future<void> testRegister() async {
    setState(() => _isLoading = true);
    _updateStatus("Registering...");
    try {
      final user = await _authService.signUpWithEmail(
        email: 'flutter@test.com',
        password: 'yourpassword31234',
        fullName: 'Flutter User',
        phone: '9999999999',
        role: UserRole.client,
        country: 'India',
        state: 'Odisha',
        city: 'Bhubaneswar',
        block: 'Central',
        pincode: '751001',
      );
      if (user != null) {
        _updateStatus('✅ Registered Successfully: ${user.fullName}');
      } else {
        _updateStatus('❌ Registration Failed');
      }
    } catch (e) {
      _updateStatus('❌ Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> testLogin() async {
    setState(() => _isLoading = true);
    _updateStatus("Logging in...");
    try {
      final user = await _authService.signInWithEmail('flutter@test.com', 'yourpassword31234');
      if (user != null) {
        _updateStatus('✅ Logged In as ${user.fullName}!');
      } else {
        _updateStatus('❌ Login Failed: check credentials');
      }
    } catch (e) {
      _updateStatus('❌ Login Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> testCreateBooking() async {
    setState(() => _isLoading = true);
    _updateStatus("Creating booking...");
    try {
      // Note: vendor_id needs to be a valid UUID from your database.
      final booking = await BookingService.createBooking({
        'vendor_id': '3208ad53-0edc-4479-aa0f-0ac07195de0a', 
        'event_date': '2026-12-25', 
        'notes': 'Test from Flutter',
        'event_name': 'Test Wedding',
        'event_type': 'Wedding',
        'guest_count': 100,
        'budget': 50000,
        'event_time': '10:00',
        'event_end_time': '22:00',
        'venue_location': 'Bhubaneswar',
        'client_upi_id': 'test@upi',
        'client_upi_name': 'Tester'
      });
      _updateStatus('✅ Booking Created ID: ${booking['id'] ?? 'Success'}');
    } catch (e) {
      _updateStatus('❌ Booking Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> clearToken() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signOut();
      _updateStatus('🗑️ Token cleared (Logged out).');
    } catch (e) {
      _updateStatus('❌ Logout Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Server Connection Test'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(theme),
            const SizedBox(height: 20),
            Text(
              'Target URL: ${ApiConfig.baseUrl}',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.blueGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (_isLoading) 
              const Center(child: Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: CircularProgressIndicator(),
              )),
            _buildActionButtons(),
            const SizedBox(height: 40),
            const Divider(),
            const Text(
              'Note: Android uses 10.0.2.2 to reach localhost.\nEnsure your server is running on port 4000.',
              style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text('Connection Status', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              _status, 
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15, 
                color: _status.contains('✅') ? Colors.green : (_status.contains('❌') ? Colors.red : theme.hintColor),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        _testButton(
          icon: Icons.person_add_outlined,
          label: '1. Test Register',
          onPressed: testRegister,
          color: Colors.blue,
        ),
        const SizedBox(height: 12),
        _testButton(
          icon: Icons.login_outlined,
          label: '2. Test Login',
          onPressed: testLogin,
          color: Colors.indigo,
        ),
        const SizedBox(height: 12),
        _testButton(
          icon: Icons.book_online_outlined,
          label: '3. Test Create Booking',
          onPressed: testCreateBooking,
          color: Colors.teal,
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _isLoading ? null : clearToken,
          icon: const Icon(Icons.logout_rounded, size: 20),
          label: const Text('Logout (Clear Token)'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.all(16), 
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _testButton({required IconData icon, required String label, required VoidCallback onPressed, required Color color}) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }
}
