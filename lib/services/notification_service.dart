import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationService extends ChangeNotifier {
  final List<AppNotification> _notifications = [];
  final StreamController<AppNotification> _notificationStreamController = 
      StreamController<AppNotification>.broadcast();

  UnmodifiableListView<AppNotification> get notifications => 
      UnmodifiableListView(_notifications);
  
  Stream<AppNotification> get notificationStream => 
      _notificationStreamController.stream;
  
  int get unreadCount => 
      _notifications.where((notification) => !notification.isRead).length;

  NotificationService() {
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = prefs.getStringList('notifications') ?? [];
    
    _notifications.clear();
    for (var json in notificationsJson) {
      try {
        final Map<String, dynamic> data = jsonDecode(json);
        _notifications.add(AppNotification.fromMap(data));
      } catch (e) {
        debugPrint('Error parsing notification: $e');
      }
    }
    
    notifyListeners();
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = _notifications
        .map((notification) => jsonEncode(notification.toMap()))
        .toList();
    
    await prefs.setStringList('notifications', notificationsJson);
  }

  void addNotification({
    required String title,
    required String message,
    String? imageUrl,
    String? redirectRoute,
    Map<String, dynamic>? data,
  }) {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      timestamp: DateTime.now(),
      imageUrl: imageUrl,
      isRead: false,
      redirectRoute: redirectRoute,
      data: data,
    );
    
    _notifications.insert(0, notification);
    _notificationStreamController.add(notification);
    notifyListeners();
    
    _saveNotifications();
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((notification) => notification.id == id);
    if (index != -1) {
      final notification = _notifications[index];
      _notifications[index] = notification.copyWith(isRead: true);
      notifyListeners();
      
      _saveNotifications();
    }
  }

  void markAllAsRead() {
    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    notifyListeners();
    
    _saveNotifications();
  }

  void removeNotification(String id) {
    _notifications.removeWhere((notification) => notification.id == id);
    notifyListeners();
    
    _saveNotifications();
  }

  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
    
    _saveNotifications();
  }

  @override
  void dispose() {
    _notificationStreamController.close();
    super.dispose();
  }
}
