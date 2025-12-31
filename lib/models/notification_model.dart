class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final String? imageUrl;
  final bool isRead;
  final String? redirectRoute;
  final Map<String, dynamic>? data;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.imageUrl,
    this.isRead = false,
    this.redirectRoute,
    this.data,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    String? imageUrl,
    bool? isRead,
    String? redirectRoute,
    Map<String, dynamic>? data,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      imageUrl: imageUrl ?? this.imageUrl,
      isRead: isRead ?? this.isRead,
      redirectRoute: redirectRoute ?? this.redirectRoute,
      data: data ?? this.data,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'imageUrl': imageUrl,
      'isRead': isRead,
      'redirectRoute': redirectRoute,
      'data': data,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'],
      title: map['title'],
      message: map['message'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      imageUrl: map['imageUrl'],
      isRead: map['isRead'] ?? false,
      redirectRoute: map['redirectRoute'],
      data: map['data'],
    );
  }
}
