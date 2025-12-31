import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/notification_service.dart';
import '../../widgets/notification_badge.dart';
import '../notification/notifications_page.dart';
import '../veterinarian/vet_dashboard_page.dart';
import '../petOwner/petowner_dashboard.dart';
import '../../services/auth_service.dart';
import '../../services/feature_notification_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final AuthService _authService = AuthService();
  String? userEmail;
  String? userType;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    
    // Show welcome notification on first login and feature notification on every app open
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _showWelcomeNotification();
      // Show feature notification
      final featureService = Provider.of<FeatureNotificationService>(context, listen: false);
      await featureService.showNextFeature();
    });
  }

  Future<void> _loadUserData() async {
    final email = await _authService.getUserEmail();
    final type = await _authService.getUserType();
    setState(() {
      userEmail = email;
      userType = type;
      _isLoading = false;
    });
    
    // If user is a veterinarian, navigate to vet dashboard
    if (type == 'Veterinarian') {
      // Use a short delay to ensure the widget is fully built
      Future.delayed(const Duration(milliseconds: 100), () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const VeterinarianDashboardPage(),
          ),
        );
      });
    } else if (type == 'Pet Owner') {
      Future.delayed(const Duration(milliseconds: 100), () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const PetOwnerDashboardPage(),
          ),
        );
      });
    } else {
      // Handle unknown user type
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showWelcomeNotification() async {
    final isFirstTime = await _authService.isFirstTimeLogin();
    if (isFirstTime) {
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      notificationService.addNotification(
        title: 'Welcome to PetPulse!',
        message: 'Thanks for using our app. We hope you enjoy the experience.',
      );
      
      // Schedule feature highlight notification after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          notificationService.addNotification(
            title: 'Feature Highlight',
            message: 'Did you know you can track your pet\'s health records?',
          );
        }
      });

      await _authService.markFirstTimeLoginComplete();
    }
  }

  Future<void> _logout() async {
    await _authService.logoutUser();
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }
  
  void _addTestNotification() {
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    notificationService.addNotification(
      title: 'Test Notification',
      message: 'This is a test notification sent at ${DateTime.now().hour}:${DateTime.now().minute}',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.purple,
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Pulse'),
        actions: [
          NotificationBadge(
            child: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsPage(),
                ),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}
