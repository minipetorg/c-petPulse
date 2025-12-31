import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/notification_service.dart';
import '../../widgets/notification_item.dart';
import '../../models/notification_model.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'), // Changed from 'Notifications' to 'Alerts'
        actions: [
          Consumer<NotificationService>(
            builder: (context, notificationService, child) {
              if (notificationService.notifications.isNotEmpty) {
                return PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Text('Mark all as read'),
                      onTap: () {
                        notificationService.markAllAsRead();
                      },
                    ),
                    PopupMenuItem(
                      child: const Text('Clear all'),
                      onTap: () {
                        notificationService.clearNotifications();
                      },
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<NotificationService>(
        builder: (context, notificationService, child) {
          final notifications = notificationService.notifications;
          
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return NotificationItem(
                notification: notification,
                onTap: () => _handleNotificationTap(context, notification),
                onDismiss: () => notificationService.removeNotification(notification.id),
              );
            },
          );
        },
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, AppNotification notification) {
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    notificationService.markAsRead(notification.id);

    if (notification.redirectRoute != null) {
      // Handle navigation to the specified route
      // This will vary based on your app's navigation structure
      // Navigator.of(context).pushNamed(notification.redirectRoute!);
    }
    
    // For now, just show a dialog with the notification details
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Text(notification.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }
}
