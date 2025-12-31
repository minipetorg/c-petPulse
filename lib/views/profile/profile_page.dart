import 'package:flutter/material.dart';
import '../../controllers/auth_controller.dart';
import '../../models/user.dart';
import './edit_profile_form.dart';
import '../../services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authController = AuthController();
  final AuthService _authService = AuthService();
  String? userEmail;
  String? userType;

  @override
  void initState() {
    super.initState();
    _authController.initializeUser();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final email = await _authService.getUserEmail();
    final type = await _authService.getUserType();
    if (mounted) {
      setState(() {
        userEmail = email;
        userType = type;
      });
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade100,
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _authService.logoutUser();
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override 
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: User.getCurrentUserInfo(userType ?? 'user'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final currentUser = snapshot.data;
        if (currentUser == null) {
          return const Center(child: Text('No user data found'));
        }

        return buildProfileContent(currentUser);
      },
    );
  }

  Widget buildProfileContent(User currentUser) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 40),
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.purple,
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            currentUser.fullName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          _buildProfileItem('Email', currentUser.email, Icons.email),
          _buildProfileItem('Phone', currentUser.phone, Icons.phone),
          _buildProfileItem('Address', currentUser.address, Icons.location_on),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              _showEditProfileDialog(currentUser);
            },
            child: const Text('Edit Profile'),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                foregroundColor: const Color.fromARGB(255, 250, 245, 245),
                backgroundColor: const Color.fromARGB(255, 243, 64, 70), // Changed from Colors.red.shade400 to pure red
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(String label, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.purple),
      title: Text(label),
      subtitle: Text(value),
    );
  }

  void _showEditProfileDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: EditProfileForm(
          user: user,
          onSuccess: () {
            Navigator.of(context).pop();
            setState(() {});  // Refresh profile page
          },
        ),
      ),
    );
  }
}