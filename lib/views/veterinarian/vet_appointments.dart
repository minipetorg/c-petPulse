import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/appointment.dart';
import '../../../models/pet.dart'; // Import the Pet model
import 'package:intl/intl.dart';
import 'vet_medicalrecord.dart';

class VetAppointmentsPage extends StatefulWidget {
  final String vetId;

  const VetAppointmentsPage({super.key, required this.vetId});

  @override
  _VetAppointmentsPageState createState() => _VetAppointmentsPageState();
}

class _VetAppointmentsPageState extends State<VetAppointmentsPage> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  List<Appointment> _appointments = [];
  Map<String, String?> _petNames = {};
  bool _isLoading = true;
  String? _error;
  bool _initialLoadComplete = false;

  @override
  bool get wantKeepAlive => true; // Keep state when tab changes

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Add listener to tab controller to detect tab changes
    _tabController.addListener(_handleTabChange);
    // Load appointments immediately when widget initializes
    _loadAppointments();
  }

  void _handleTabChange() {
    // Force refresh when tab changes (optional)
    if (_tabController.indexIsChanging) {
      _loadAppointments();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only reload if we haven't done our initial load
    if (!_initialLoadComplete) {
      _loadAppointments();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Add a slight delay to ensure Firebase is ready
      await Future.delayed(const Duration(milliseconds: 200));

      final appointmentsList = await Appointment.getAppointmentsByVetId(widget.vetId);
      final petIds = appointmentsList.map((appointment) => appointment.petId).toList();
      final petNames = await Future.wait(petIds.map((petId) => Pet.getPetNameById(petId)));

      final petNamesMap = Map.fromIterables(petIds, petNames);

      if (mounted) {
        setState(() {
          _appointments = appointmentsList;
          _petNames = petNamesMap;
          _isLoading = false;
          _initialLoadComplete = true;
        });
      }
    } catch (e) {
      print("Error loading appointments: $e");
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _initialLoadComplete = true;
        });
      }
    }
  }

  Future<void> _updateAppointmentStatus(String appointmentId, String status) async {
    try {
      await Appointment.updateAppointmentStatus(appointmentId, status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Appointment status updated to $status'),
          backgroundColor: Colors.green,
        ),
      );
      _loadAppointments();
    } catch (e) {
      print("Error updating appointment status: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating appointment status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _createMedicalRecord(Appointment appointment) {
    // Navigate to medical record creation page
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VetMedicalRecordPage(appointment: appointment),
      ),
    ).then((result) {
      // Refresh appointments when returning from medical record page
      if (result == true) {
        _loadAppointments();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: const [
            Tab(text: 'PENDING'),
            Tab(text: 'CONFIRMED'),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAppointments,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No appointments found.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAppointments,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    final pendingAppointments = _appointments
        .where((app) => app.status.toLowerCase() == 'pending')
        .toList();

    final confirmedAppointments = _appointments
        .where((app) => app.status.toLowerCase() == 'confirmed')
        .toList();

    return TabBarView(
      controller: _tabController,
      children: [
        // Pending Appointments Tab
        _buildAppointmentsList(pendingAppointments, isPending: true),

        // Confirmed Appointments Tab
        _buildAppointmentsList(confirmedAppointments, isPending: false),
      ],
    );
  }

  Widget _buildAppointmentsList(List<Appointment> appointments, {required bool isPending}) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('No ${isPending ? 'pending' : 'confirmed'} appointments found.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAppointments,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(), // Allows pull-to-refresh even when content doesn't fill screen
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appointment = appointments[index];
          final petName = _petNames[appointment.petId] ?? 'Loading...';
          return Card(
            margin: const EdgeInsets.all(8.0),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pet: $petName', 
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Purpose: ${appointment.purpose}'),
                  Text('Date: ${DateFormat('MMM d, y').format(appointment.dateTime)}'),
                  Text('Time: ${DateFormat('hh:mm a').format(appointment.dateTime)}'),
                  const SizedBox(height: 12),

                  // Action buttons based on appointment status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: isPending 
                      ? [
                          // Buttons for pending appointments
                          ElevatedButton(
                            onPressed: () => _updateAppointmentStatus(appointment.id, 'declined'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Decline'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _updateAppointmentStatus(appointment.id, 'confirmed'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Confirm'),
                          ),
                        ]
                      : [
                          // Buttons for confirmed appointments
                          ElevatedButton(
                            onPressed: () => _createMedicalRecord(appointment),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Create Medical Record'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _updateAppointmentStatus(appointment.id, 'completed'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Complete'),
                          ),
                        ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}