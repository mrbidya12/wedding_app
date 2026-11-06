import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<AppNotification>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = NotificationService.getNotifications();
  }

  Future<void> _refresh() async {
    setState(() {
      _notificationsFuture = NotificationService.getNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryPurple = const Color(0xFF6A1B9A);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              await NotificationService.markAllAsRead();
              _refresh();
            },
            child: const Text('Mark all as read', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<AppNotification>>(
          future: _notificationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final notifications = snapshot.data ?? [];
            if (notifications.isEmpty) {
              return const Center(child: Text('No notifications yet.'));
            }

            return ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final isRead = notification.readAt != null;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isRead ? Colors.grey[200] : primaryPurple.withOpacity(0.1),
                    child: Icon(
                      _getIconForType(notification.type),
                      color: isRead ? Colors.grey : primaryPurple,
                    ),
                  ),
                  title: Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(notification.content),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM d, h:mm a').format(notification.createdAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  onTap: () {
                    if (!isRead) {
                      NotificationService.markAsRead(notification.id);
                    }
                    NotificationService.handleDeepLink(context, notification);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'chat':
        return Icons.chat_bubble_outline;
      case 'booking':
        return Icons.calendar_today;
      case 'payment':
        return Icons.payment;
      default:
        return Icons.notifications_none;
    }
  }
}
