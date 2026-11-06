import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../models/vendor_model.dart';
import '../services/user_service.dart';
import '../services/vendor_service.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  // Theme Colors
  final Color primaryPurple = const Color(0xFF6A1B9A);
  final Color subTitleColor = Colors.grey.shade600;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final bool isAdmin = auth.userData?.role == UserRole.admin;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Text(
          isAdmin ? 'Kbidu Admin' : 'Kbidu',
          style: TextStyle(
            color: primaryPurple,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // WhatsApp Style Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Ask Meta AI or Search',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          
          Expanded(
            child: isAdmin ? _buildAdminMonitor() : _buildUserChatList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryPurple,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_comment, color: Colors.white),
        onPressed: () {},
      ),
    );
  }

  Widget _buildAdminMonitor() {
    return FutureBuilder<List<AppUser>>(
      future: UserService.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primaryPurple));
        }
        
        final users = (snapshot.data ?? [])
            .where((u) => u.role != UserRole.admin)
            .toList();
        
        if (users.isEmpty) return const Center(child: Text('No users available'));

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return _buildChatItem(
              name: user.fullName,
              subtitle: 'Role: ${user.role.name}',
              onTap: () => _openChat(context, user.uid, user.fullName),
            );
          },
        );
      },
    );
  }

  Widget _buildUserChatList() {
    return FutureBuilder<List<dynamic>>(
      future: VendorService.getVendors(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primaryPurple));
        }
        
        final vendors = (snapshot.data ?? []).map((v) => Vendor.fromJson(v)).toList();
        
        return ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            // Archived Section
            _buildArchivedRow(),
            
            // Fixed Admin Chat
            _buildChatItem(
              name: 'Kbidu Support (Admin)',
              subtitle: '👋 Hello! How can we help you today?',
              isPinned: true,
              isRead: false,
              onTap: () => _openChat(context, 'admin_main', 'Kbidu Admin'),
            ),
            
            // Vendor Chats
            ...vendors.map((vendor) => _buildChatItem(
              name: vendor.name,
              subtitle: 'Sent a photo',
              imageUrl: vendor.imageUrl,
              hasAttachment: true,
              isRead: true,
              onTap: () => _openChat(context, vendor.id, vendor.name, vendorId: vendor.id),
            )),
          ],
        );
      },
    );
  }

  Widget _buildArchivedRow() {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.archive_outlined, color: Colors.grey.shade700, size: 22),
            const SizedBox(width: 32),
            const Text(
              'Archived',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const Spacer(),
            Text(
              '3',
              style: TextStyle(color: primaryPurple, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatItem({
    required String name,
    required String subtitle,
    String? imageUrl,
    required VoidCallback onTap,
    bool isPinned = false,
    bool isRead = true,
    bool hasAttachment = false,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey[200],
            backgroundImage: (imageUrl != null && imageUrl.isNotEmpty) ? NetworkImage(imageUrl) : null,
            child: (imageUrl == null || imageUrl.isEmpty) ? Icon(Icons.person, color: Colors.grey.shade400, size: 30) : null,
          ),
          if (isPinned)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Icon(Icons.push_pin, size: 14, color: Colors.grey.shade600),
              ),
            ),
        ],
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ),
          Text(
            DateFormat('hh:mm a').format(DateTime.now()),
            style: TextStyle(
              fontSize: 12, 
              color: isRead ? subTitleColor : primaryPurple,
              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          if (isRead)
            const Padding(
              padding: EdgeInsets.only(right: 4.0),
              child: Icon(Icons.done_all, size: 18, color: Colors.blue),
            ),
          if (hasAttachment)
            Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: Icon(Icons.image, size: 16, color: subTitleColor),
            ),
          Expanded(
            child: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: subTitleColor, 
                fontSize: 14,
                fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
              ),
            ),
          ),
          if (!isRead)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: primaryPurple, shape: BoxShape.circle),
              child: const Text('1', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  void _openChat(BuildContext context, String id, String name, {String? vendorId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(
          receiverId: id,
          receiverName: name,
          vendorId: vendorId,
        ),
      ),
    );
  }
}
