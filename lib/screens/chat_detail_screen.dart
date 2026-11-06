import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../services/chat_service.dart';
import '../services/location_service.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';

class ChatDetailScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String? vendorId;
  final String? bookingId;

  const ChatDetailScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    this.vendorId,
    this.bookingId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  // WhatsApp Style Colors
  final Color waGreen = const Color(0xFFE7FFDB); // Sent bubble
  final Color waWhite = Colors.white; // Received bubble
  final Color waTeal = const Color(0xFF075E54); // AppBar
  final Color waBackground = const Color(0xFFE5DDD5); // Chat background
  final Color waCheckColor = const Color(0xFF34B7F1); // Blue ticks

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.userData == null) return;

    try {
      await _chatService.connect(
        userId: auth.userData!.uid,
        role: auth.userData!.role.name,
        onMessageReceived: (data) {
          if (mounted) {
            setState(() {
              _messages.add(data);
            });
            _scrollToBottom();
          }
        },
        onAdminMessage: (data) {},
        onMessageDeleted: (msgId) {
          if (mounted) {
            setState(() {
              _messages.removeWhere((m) => m['_id'].toString() == msgId.toString());
            });
          }
        },
        onUserBlocked: (userId) {
          if (mounted && userId == auth.userData?.uid) {
            Navigator.pop(context);
          }
        },
        onUserUnblocked: (userId) {},
      );

      final history = await _chatService.getConversation(widget.receiverId);
      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(history);
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage({String? type, String? customContent}) {
    final content = customContent ?? _messageController.text.trim();
    if (content.isEmpty) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.userData == null) return;
    
    _chatService.sendMessage(
      toUserId: widget.receiverId,
      content: content,
      type: type,
      vendorId: widget.vendorId,
    );

    setState(() {
      _messages.add({
        '_id': DateTime.now().millisecondsSinceEpoch.toString(), 
        'senderId': auth.userData!.uid,
        'receiverId': widget.receiverId,
        'content': content,
        'type': type ?? 'text',
        'timestamp': DateTime.now().toIso8601String(),
        'isMe': true,
      });
    });

    if (customContent == null) _messageController.clear();
    _scrollToBottom();
  }

  @override
  void dispose() {
    _chatService.disconnect();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: waBackground,
      appBar: AppBar(
        backgroundColor: waTeal,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white24,
              child: Text(widget.receiverName[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.receiverName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Text('Online', style: TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.videocam), onPressed: () {}),
          IconButton(icon: const Icon(Icons.call), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF075E54)))
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isMe = msg['senderId'] == auth.userData?.uid || msg['isMe'] == true;
                    
                    // Logic for showing Date Separator
                    bool showDate = false;
                    if (index == 0) {
                      showDate = true;
                    } else {
                      final prevMsg = _messages[index - 1];
                      final prevDate = DateTime.parse(prevMsg['timestamp']).toLocal();
                      final currDate = DateTime.parse(msg['timestamp']).toLocal();
                      if (prevDate.day != currDate.day || prevDate.month != currDate.month || prevDate.year != currDate.year) {
                        showDate = true;
                      }
                    }

                    return Column(
                      children: [
                        if (showDate) _buildDateSeparator(msg['timestamp']),
                        _buildWhatsAppBubble(msg, isMe),
                      ],
                    );
                  },
                ),
          ),
          _buildWhatsAppInput(auth),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(String timestamp) {
    final date = DateTime.parse(timestamp).toLocal();
    final now = DateTime.now();
    String text = DateFormat('MMMM dd, yyyy').format(date);
    
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      text = 'Today';
    } else if (date.day == now.day - 1 && date.month == now.month && date.year == now.year) {
      text = 'Yesterday';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFD4EAF4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF506169))),
    );
  }

  Widget _buildWhatsAppBubble(Map<String, dynamic> msg, bool isMe) {
    final String content = msg['content']?.toString() ?? "";
    final bool isPayment = msg['type'] == 'payment_request';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: isMe ? waGreen : waWhite,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(12),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isPayment) ...[
              const Text('PAYMENT REQUEST', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.orange)),
              const SizedBox(height: 8),
              QrImageView(data: content, version: QrVersions.auto, size: 120.0),
              const SizedBox(height: 8),
            ],
            Text(content, style: const TextStyle(fontSize: 16, color: Colors.black87)),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(msg['timestamp']),
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.done_all, size: 15, color: waCheckColor),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final dt = DateTime.parse(timestamp.toString()).toLocal();
      return DateFormat('hh:mm a').format(dt);
    } catch (e) { return ''; }
  }

  Widget _buildWhatsAppInput(AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 20),
      color: Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.grey), onPressed: () {}),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Message',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.attach_file, color: Colors.grey), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.camera_alt, color: Colors.grey), onPressed: () {}),
                ],
              ),
            ),
          ),
          const SizedBox(width: 5),
          CircleAvatar(
            backgroundColor: const Color(0xFF075E54),
            radius: 25,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () => _sendMessage(),
            ),
          ),
        ],
      ),
    );
  }
}
