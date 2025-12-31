import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';

class NotificationBadge extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;

  const NotificationBadge({
    Key? key,
    required this.child,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationService>(
      builder: (context, notificationService, _) {
        final unreadCount = notificationService.unreadCount;
        
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: child,
              onPressed: onPressed,
              padding: EdgeInsets.zero,
            ),
            if (unreadCount > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 14,
                    minHeight: 14,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
