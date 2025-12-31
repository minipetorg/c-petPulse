import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/notification_badge.dart';
import '../../views/chatbot/chatbot_page.dart';
import '../pets/pets_page.dart';
import '../profile/profile_page.dart';
import '../map/map.dart';
import '../feed/feed.dart';
import '../notification/notifications_page.dart';
import '../chat/chat_list_page.dart' as chat;

class PetOwnerDashboardPage extends StatefulWidget {
  const PetOwnerDashboardPage({super.key});

  @override
  State<PetOwnerDashboardPage> createState() => _PetOwnerDashboardPageState();
}

class _PetOwnerDashboardPageState extends State<PetOwnerDashboardPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    PetsPage(),
    const FeedPage(),
    const chat.ChatListPage(),
    const MapPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Add this method to test notifications
  void _addVetAppointmentNotification() {
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    notificationService.addNotification(
      title: 'Vet Appointment Reminder',
      message: 'Don\'t forget your upcoming appointment tomorrow at 3:00 PM',
      redirectRoute: '/appointments',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple[800]!, Colors.purple[300]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "PetPulse",
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    NotificationBadge(
                      child: const Icon(
                        Icons.notifications,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationsPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _pages[_selectedIndex],
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.purple,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.pets),
              label: 'Pets',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.feed),
              label: 'Feed',
            ),
            BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map),
              label: 'Map',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          onTap: _onItemTapped,
        ),
      ),
      floatingActionButton: (_selectedIndex == 0) 
          ? SizedBox(
              height: 56,
              width: 56,
              child: FloatingActionButton(
                onPressed: () => Navigator.of(context).push(
                  PageRouteBuilder(
                    opaque: false,
                    pageBuilder: (context, _, __) => Center(
                      child: Container(
                        margin: const EdgeInsets.all(32),
                        constraints: const BoxConstraints(
                          maxWidth: 350,
                          maxHeight: 600,
                        ),
                        child: const ChatbotPage(),
                      ),
                    ),
                  ),
                ),
                backgroundColor: Colors.purple,
                child: const Icon(
                  Icons.auto_awesome,
                  size: 26,
                ),
              ),
            )
          : null,
    );
  }

}