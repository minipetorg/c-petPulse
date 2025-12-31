import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './pets_page.dart';
import '../../models/pet.dart';
import 'package:intl/intl.dart';
import '../../models/user.dart' as petpulse_user;
import 'tabs/health_tab.dart';
import 'tabs/companion_tab.dart';
import 'tabs/memory_tab.dart';
import 'tabs/appointment_tab.dart';

class PetDetailsPage extends StatefulWidget {
  final Map<String, String> pet;
  const PetDetailsPage({super.key, required this.pet});

  @override
  State<PetDetailsPage> createState() => _PetDetailsPageState();
}

class _PetDetailsPageState extends State<PetDetailsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Use imported calculateAge function
  String get petAge => Pet.calculateAge(widget.pet['birthday'] ?? '');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pet Profile',
          style: TextStyle(
            fontWeight: FontWeight.w700
          ),
        ),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.delete,
              color: Colors.white,
              ),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Pet'),
                  content: const Text('Are you sure you want to delete this pet?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                final success = await Pet.deletePet(
                  widget.pet['id'] ?? '',
                  FirebaseAuth.instance.currentUser?.uid ?? '',
                );

                if (success && mounted) {
                  Navigator.pop(context, true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pet deleted successfully')),
                  );
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to delete pet')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.purple[50]!,
                  Colors.purple[100]!,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  offset: const Offset(5, 5),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
                const BoxShadow(
                  color: Colors.white,
                  offset: Offset(-5, -5),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: widget.pet['image']?.isNotEmpty == true
                      ? NetworkImage(widget.pet['image']!)
                      : Pet.getPetIcon(widget.pet['type']),
                  backgroundColor: Colors.purple[100],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.pet['name'] ?? 'No Name',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            widget.pet['gender']?.toLowerCase() == 'male' ? Icons.male : Icons.female,
                            size: 16,
                            color: widget.pet['gender']?.toLowerCase() == 'male' ? Colors.blue : Colors.pink,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.pet['breed'] ?? 'Unknown Breed',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.purple[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        petAge,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.purple[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: Colors.purple,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.purple,
            tabs: const [
              Tab(text: 'Health', icon: Icon(Icons.health_and_safety)),
              Tab(text: 'Find Companion', icon: Icon(Icons.pets)),
              Tab(text: 'Memories', icon: Icon(Icons.history)),
              Tab(text: 'Appointment', icon: Icon(Icons.calendar_month)),
            ],
          ),
          // Tab Views with matching card styles
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                HealthTab(pet: widget.pet),
                CompanionTab(currentPet: widget.pet),
                MemoryTab(currentPet: widget.pet),
                AppointmentTab(pet: widget.pet),
              ],
            ),
          ),
        ],
      ),
    );
  }
}