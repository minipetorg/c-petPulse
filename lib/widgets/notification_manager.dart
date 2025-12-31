import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import './popup_notification.dart';
import 'package:provider/provider.dart';

class NotificationManager extends StatefulWidget {
  final Widget child;
  
  const NotificationManager({
    Key? key,
    required this.child,
  }) : super(key: key);
  
  @override
  State<NotificationManager> createState() => _NotificationManagerState();
}

class _NotificationManagerState extends State<NotificationManager> {
  final List<AppNotification> _activeNotifications = [];
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenForNotifications();
    });
  }

  void _listenForNotifications() {
    // Use the Provider to access the notification service
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    notificationService.notificationStream.listen((notification) {
      setState(() {
        _activeNotifications.add(notification);
        
        // Auto-remove notification after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _activeNotifications.removeWhere((n) => n.id == notification.id);
            });
          }
        });
      });
    });
  }
  
  void _removeNotification(String id) {
    setState(() {
      _activeNotifications.removeWhere((notification) => notification.id == id);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Material(
      child: Stack(
        children: [
          widget.child,
          if (_activeNotifications.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 0,
              right: 0,
              child: Column(
                children: _activeNotifications.map((notification) {
                  return PopupNotification(
                    key: ValueKey(notification.id),
                    notification: notification,
                    onTap: () {
                      // Navigate to notifications page
                      Navigator.of(context).pushNamed('/notifications');
                      _removeNotification(notification.id);
                    },
                    onDismiss: () {
                      _removeNotification(notification.id);
                    },
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
