import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class FeatureNotificationService {
  static const String _lastFeatureIndexKey = 'last_feature_index';
  final NotificationService _notificationService;

  FeatureNotificationService(this._notificationService);

  final List<Map<String, String>> _features = [
    {
      'title': 'Find Perfect Pet Matches',
      'message': 'Browse through pets available for adoption and find your perfect companion!'
    },
    {
      'title': 'Health Tracking',
      'message': 'Keep track of your pet\'s vaccinations, medications, and health records!'
    },
    {
      'title': 'Vet Consultation',
      'message': 'Connect with veterinarians for professional advice and consultations!'
    },
    {
      'title': 'Pet Location',
      'message': 'Use our map feature to find nearby pet services and facilities!'
    },
    {
      'title': 'AI Chat Assistant',
      'message': 'Ask our AI assistant any questions about pet care and get instant answers!'
    },
    {
      'title': 'Community Feed',
      'message': 'Share your pet\'s moments and connect with other pet lovers!'
    },
  ];

  Future<void> showNextFeature() async {
    final prefs = await SharedPreferences.getInstance();
    final lastIndex = prefs.getInt(_lastFeatureIndexKey) ?? -1;
    final nextIndex = (lastIndex + 1) % _features.length;

    final feature = _features[nextIndex];
    _notificationService.addNotification(
      title: feature['title']!,
      message: feature['message']!,
    );

    await prefs.setInt(_lastFeatureIndexKey, nextIndex);
  }

  Future<void> resetFeatureIndex() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastFeatureIndexKey, -1);
  }
}
