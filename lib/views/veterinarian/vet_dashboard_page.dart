import 'package:flutter/material.dart';
import 'package:petpulse/models/veterinarian.dart';
import '../../services/auth_service.dart';
import 'vet_profile.dart';
import 'vet_appointments.dart';
import 'vet_patients.dart';
import '../chat/chat_list_page.dart' as chat;

class VeterinarianDashboardPage extends StatefulWidget {
  const VeterinarianDashboardPage({super.key});

  @override
  State<VeterinarianDashboardPage> createState() => _VeterinarianDashboardPageState();
}

class _VeterinarianDashboardPageState extends State<VeterinarianDashboardPage> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();
  String? userEmail;
  String? userFullName; 
  String? userType;
  String? userId;
  Veterinarian? currentUser; // Change to Veterinarian

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final email = await _authService.getUserEmail();
    final type = await _authService.getUserType();
    final user = await Veterinarian.getCurrentUserInfo();
    setState(() {
      userEmail = email;
      userFullName = user?.fullName;
      userType = type;
      userId = user?.uid;
      currentUser = user; // Set the current user
    });
  }

  Future<void> _logout() async {
    await _authService.logoutUser();
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      VetAppointmentsPage(vetId: userId ?? ''),
      VetPatientsPage(),
      const chat.ChatListPage(),
      currentUser != null
          ? VetProfilePage(currentUser: currentUser!, onProfileUpdated: _loadUserData)
          : const Center(child: CircularProgressIndicator()), // Placeholder widget
    ];

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 16),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          userFullName ?? 'Loading...',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white),
                          onPressed: _logout,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      userEmail ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _pages[_selectedIndex],
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 7,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            elevation: 8,
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.purple,
            unselectedItemColor: Colors.grey,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today),
                label: 'Appointments',
                backgroundColor: Colors.white,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.pets),
                label: 'Patients',
                backgroundColor: Colors.white,
              ),
              BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              label: 'Chat',
              backgroundColor: Colors.white,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
                backgroundColor: Colors.white,
              ),
            ],
            onTap: (index) => setState(() => _selectedIndex = index),
          ),
        ),
      ),
    );
  }
}