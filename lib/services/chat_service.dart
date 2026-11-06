import 'dart:async';
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ChatService {
  IO.Socket? _socket;
  final storage = const FlutterSecureStorage();

  bool get connected => _socket?.connected ?? false;

  Future<void> connect({
    required String userId,
    required String role,
    required Function(Map<String, dynamic>) onMessageReceived,
    required Function(Map<String, dynamic>) onAdminMessage,
    required Function(String) onMessageDeleted,
    required Function(String) onUserBlocked,
    required Function(String) onUserUnblocked,
    // WebRTC Callbacks
    Function(Map<String, dynamic>)? onCallOffer,
    Function(Map<String, dynamic>)? onCallAnswer,
    Function(Map<String, dynamic>)? onIceCandidate,
    Function(Map<String, dynamic>)? onCallEnd,
  }) async {
    // 1. Clean up existing connection to prevent leaks
    disconnect();

    final token = await storage.read(key: 'jwt_token');
    if (token == null) {
      print('❌ Chat: No JWT token found');
      return;
    }

    try {
      // 2. Initialize Socket.IO
      _socket = IO.io(ApiConfig.wsUrl, IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .build());

      _socket!.connect();

      // 3. Set up event listeners
      _socket!.onConnect((_) {
        print('✅ Chat: Connected via Socket.IO');
        
        _socket!.emit('join', 'user_$userId');
        if (role == 'admin') {
          _socket!.emit('join', 'admin_monitor');
        }
      });

      // --- Message Listeners ---
      _socket!.on('receive_message', (data) {
        onMessageReceived(Map<String, dynamic>.from(data));
      });

      _socket!.on('admin_receive_message', (data) {
        if (role == 'admin') {
          onAdminMessage(Map<String, dynamic>.from(data));
        }
      });

      _socket!.on('message_deleted', (data) => onMessageDeleted(data.toString()));
      _socket!.on('user_blocked', (data) => onUserBlocked(data.toString()));
      _socket!.on('user_unblocked', (data) => onUserUnblocked(data.toString()));

      // --- WebRTC Signaling Listeners ---
      _socket!.on('call_offer', (data) {
        onCallOffer?.call(Map<String, dynamic>.from(data));
      });

      _socket!.on('call_answer', (data) {
        onCallAnswer?.call(Map<String, dynamic>.from(data));
      });

      _socket!.on('ice_candidate', (data) {
        onIceCandidate?.call(Map<String, dynamic>.from(data));
      });

      _socket!.on('call_end', (data) {
        onCallEnd?.call(Map<String, dynamic>.from(data));
      });

      _socket!.onDisconnect((_) => print('ℹ️ Chat: Disconnected'));
      _socket!.onConnectError((err) => print('❌ Chat Connection Error: $err'));
      _socket!.onError((err) => print('❌ Chat Error: $err'));

    } catch (e) {
      print('❌ Chat Exception: $e');
    }
  }

  void sendMessage({
    required String toUserId,
    required String content,
    String? type,
    String? vendorId,
  }) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('send_message', {
        'toUserId': toUserId,
        'vendorId': vendorId,
        'content': content,
        'type': type ?? 'text',
      });
    }
  }

  // ---------- WebRTC Signaling Events ----------
  void sendCallOffer(String toUserId, Map<String, dynamic> offer) {
    _socket?.emit('call_offer', {
      'toUserId': toUserId,
      'offer': offer,
    });
  }

  void sendCallAnswer(String toUserId, Map<String, dynamic> answer) {
    _socket?.emit('call_answer', {
      'toUserId': toUserId,
      'answer': answer,
    });
  }

  void sendIceCandidate(String toUserId, Map<String, dynamic> candidate) {
    _socket?.emit('ice_candidate', {
      'toUserId': toUserId,
      'candidate': candidate,
    });
  }

  void endCall(String toUserId) {
    _socket?.emit('call_end', {'toUserId': toUserId});
  }

  Future<List<Map<String, dynamic>>> getConversation(String withUserId) async {
    final token = await storage.read(key: 'jwt_token');
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/chat/conversation/$withUserId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
    } catch (e) {
      print('❌ Chat History Error: $e');
    }
    return [];
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.clearListeners();
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
  }
}
