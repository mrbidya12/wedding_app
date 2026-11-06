import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/user_service.dart';
import '../services/chat_service.dart';
import '../models/user_model.dart';
import 'package:intl/intl.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final AuthService _auth = AuthService();
  final ChatService _chat = ChatService();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _targetUserIdController = TextEditingController();
  final TextEditingController _vendorIdController = TextEditingController();

  String _log = '';
  AppUser? _user;

  // List of messages for admin monitor view
  final List<Map<String, dynamic>> _allMessages = [];

  void _addLog(String text) {
    if (mounted) {
      setState(() {
        _log = '${DateFormat('HH:mm:ss').format(DateTime.now())}: $text\n$_log';
      });
    }
  }

  Future<void> _register() async {
    try {
      final user = await _auth.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _nameController.text.trim(),
        phone: '9999999999',
        role: UserRole.client,
        country: 'India',
        state: 'Odisha',
        city: 'Bhubaneswar',
        block: 'Central',
        pincode: '751001',
      );
      _addLog(user != null ? '✅ Registration Success' : '❌ Registration Failed');
    } catch (e) {
      _addLog('❌ Register error: $e');
    }
  }

  Future<void> _login() async {
    try {
      final user = await _auth.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (user != null) {
        setState(() => _user = user);
        _addLog('✅ Login OK: ${user.fullName} (${user.role.name})');
      } else {
        _addLog('❌ Login Failed: Check credentials');
      }
    } catch (e) {
      _addLog('❌ Login error: $e');
    }
  }

  Future<void> _createBooking() async {
    try {
      final booking = await BookingService.createBooking({
        'vendor_id': '3208ad53-0edc-4479-aa0f-0ac07195de0a',
        'event_name': 'Debug Wedding',
        'event_type': 'Wedding',
        'guest_count': 150,
        'budget': 75000,
        'event_date': '2026-12-25',
        'notes': 'Created from Test Screen'
      });
      _addLog('✅ Booking created ID: ${booking['id']}');
    } catch (e) {
      _addLog('❌ Booking error: $e');
    }
  }

  Future<void> _getBookings() async {
    try {
      final bookings = await BookingService.getMyBookings();
      _addLog('📦 Found ${bookings.length} bookings');
    } catch (e) {
      _addLog('❌ Get bookings error: $e');
    }
  }

  Future<void> _connectChat() async {
    if (_user == null) {
      _addLog('⚠️ Please login first to get a token');
      return;
    }
    try {
      await _chat.connect(
        userId: _user!.uid,
        role: _user!.role.name,
        onMessageReceived: (msg) {
          _addLog('📩 New Message: ${msg['content']}');
        },
        onAdminMessage: (msg) {
          setState(() => _allMessages.insert(0, msg));
          _addLog('🛡️ Admin Monitor: ${msg['content']}');
        },
        onMessageDeleted: (msgId) {
          setState(() => _allMessages.removeWhere((m) => (m['_id'] ?? m['id']).toString() == msgId.toString()));
          _addLog('🗑️ Message $msgId deleted');
        },
        onUserBlocked: (userId) {
          _addLog('🚫 User $userId blocked');
          if (userId == _user?.uid) _chat.disconnect();
        },
        onUserUnblocked: (userId) => _addLog('✅ User $userId unblocked'),
      );
      _addLog('🔌 Chat connected via WebSocket');
    } catch (e) {
      _addLog('❌ Chat error: $e');
    }
  }

  void _sendChatMessage() {
    final targetId = _targetUserIdController.text.trim();
    final content = _messageController.text.trim();
    if (targetId.isEmpty || content.isEmpty) {
      _addLog('⚠️ Target ID and Message required');
      return;
    }

    _chat.sendMessage(
      toUserId: targetId,
      content: content,
      vendorId: _vendorIdController.text.trim().isNotEmpty ? _vendorIdController.text.trim() : null,
    );
    _addLog('📤 Sent to $targetId: $content');
    _messageController.clear();
  }

  void _adminBlockUser(String userId) async {
    try {
      await UserService.toggleBlockUser(userId, true);
      _addLog('🛡️ Admin restricted user $userId');
    } catch (e) {
      _addLog('❌ Block error: $e');
    }
  }

  @override
  void dispose() {
    _chat.disconnect();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _messageController.dispose();
    _targetUserIdController.dispose();
    _vendorIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('weddingpro_connect Debug Hub')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSectionTitle('1. Auth & Registry'),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()), obscureText: true),
            const SizedBox(height: 8),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Display Name (for Register)', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              ElevatedButton(onPressed: _register, child: const Text('Register')),
              ElevatedButton(onPressed: _login, child: const Text('Login')),
              ElevatedButton(onPressed: _createBooking, child: const Text('Test Booking')),
              ElevatedButton(onPressed: _getBookings, child: const Text('Fetch Bookings')),
              ElevatedButton(onPressed: _connectChat, style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), child: const Text('Connect Chat')),
            ]),
            const Divider(height: 40),
            _buildSectionTitle('2. Real-time Messaging'),
            Row(children: [
              Expanded(child: TextField(controller: _targetUserIdController, decoration: const InputDecoration(labelText: 'Receiver UID'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _vendorIdController, decoration: const InputDecoration(labelText: 'Vendor ID'))),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextField(controller: _messageController, decoration: const InputDecoration(hintText: 'Type message here...'))),
              const SizedBox(width: 8),
              // 🔵 Chat bottom in blue in round
              CircleAvatar(
                backgroundColor: Colors.blue,
                child: IconButton(onPressed: _sendChatMessage, icon: const Icon(Icons.send_rounded, color: Colors.white)),
              ),
            ]),
            if (_user?.role == UserRole.admin) ...[
              const Divider(height: 40),
              _buildSectionTitle('🛡️ Admin Monitor'),
              Container(
                height: 150,
                decoration: BoxDecoration(border: Border.all(color: Colors.blue.withOpacity(0.3)), borderRadius: BorderRadius.circular(10)),
                child: ListView.builder(
                  itemCount: _allMessages.length,
                  itemBuilder: (ctx, idx) {
                    final msg = _allMessages[idx];
                    final senderId = (msg['senderId'] ?? msg['from_user_id']).toString();
                    return ListTile(
                      dense: true,
                      title: Text(msg['content'] ?? ''),
                      subtitle: Text('From: $senderId'),
                      trailing: IconButton(
                        icon: const Icon(Icons.block, color: Colors.red, size: 18), 
                        onPressed: () => _adminBlockUser(senderId)
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 20),
            _buildSectionTitle('System Logs'),
            Container(
              width: double.infinity,
              height: 200,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
              child: SingleChildScrollView(
                child: Text(_log.isEmpty ? 'Waiting for actions...' : _log, style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(alignment: Alignment.centerLeft, child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
    );
  }
}
