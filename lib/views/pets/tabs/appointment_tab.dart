import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/appointment.dart';
import '../../../models/clinic.dart'; // Import the Clinic model
import '../../../models/veterinarian.dart'; // Import the Veterinarian model

class AppointmentTab extends StatefulWidget {
  final Map<String, String> pet;

  const AppointmentTab({super.key, required this.pet});

  @override
  State<AppointmentTab> createState() => _AppointmentTabState();
}

class _AppointmentTabState extends State<AppointmentTab> {
  bool _isLoading = true;
  bool _showForm = false; // State variable to control form visibility
  Position? _currentPosition;
  List<Map<String, dynamic>> _nearbyVets = [];
  Map<String, dynamic>? _selectedVet;
  String? _selectedDoctor;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  final TextEditingController _purposeController = TextEditingController();
  final List<String> _purposes = [
    'Vaccination',
    'Regular Checkup',
    'Medical Issue',
    'Grooming',
    'Dental Care',
    'Other'
  ];
  String _selectedPurpose = 'Vaccination';
  List<Appointment> _appointments = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _fetchAppointments();
  }

  @override
  void dispose() {
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Request location permissions
      final status = await Permission.location.request();

      if (status.isGranted) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
        );

        setState(() {
          _currentPosition = position;
        });

        await _getNearbyVets();
      } else {
        _showErrorDialog('Location permission is required to find nearby vets');
      }
    } catch (e) {
      _showErrorDialog('Failed to get current location: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getNearbyVets() async {
    if (_currentPosition == null) return;

    try {
      final clinics = await Clinic.getAllClinics();
      setState(() {
        _nearbyVets = clinics.map((clinic) {
          final distance = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            clinic.latitude,
            clinic.longitude,
          ) / 1000; // Convert to kilometers

          return {
            'id': clinic.id,
            'name': clinic.name,
            'address': clinic.address,
            'distance': '${distance.toStringAsFixed(1)} km',
            'rating': clinic.rating,
            'image': clinic.image,
            'lat': clinic.latitude,
            'lng': clinic.longitude,
            'availableDoctors': clinic.availableDoctors,
          };
        }).toList();
      });
    } catch (e) {
      _showErrorDialog('Failed to load nearby vets: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.purple,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.purple,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _fetchAppointments() async {
    try {
      final appointments = await Appointment.getAppointmentsByPetId(widget.pet['id']!);
      setState(() {
        _appointments = appointments;
      });
    } catch (e) {
      _showErrorDialog('Failed to load appointments: $e');
    }
  }

  Future<void> _bookAppointment() async {
    if (_selectedVet == null || _selectedDoctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vet clinic and a veterinarian')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorDialog('You must be logged in to book an appointment');
      return;
    }

    final appointmentDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final appointment = Appointment(
      id: Uuid().v4(),
      petId: widget.pet['id']!,
      vetId: _selectedDoctor!,
      dateTime: appointmentDateTime,
      purpose: _selectedPurpose,
      status: 'pending',
      createdAt: DateTime.now()
    );

    try {
      await Appointment.createAppointment(appointment);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Appointment Booked'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pet: ${widget.pet['name']}'),
              const SizedBox(height: 8),
              Text('Vet: ${_selectedVet!['name']}'),
              const SizedBox(height: 8),
              Text('Date: ${DateFormat('MMM d, y').format(_selectedDate)}'),
              const SizedBox(height: 8),
              Text('Time: ${_selectedTime.format(context)}'),
              const SizedBox(height: 8),
              Text('Purpose: $_selectedPurpose'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _fetchAppointments(); // Refresh the appointments list
                setState(() {
                  _showForm = false; // Hide the form after booking
                });
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showErrorDialog('Failed to book appointment: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<String?> _getDoctorName(String doctorId) async {
    return await Veterinarian.getFullNameById(doctorId);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.purple));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_showForm) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showForm = true; // Show the form when the button is pressed
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Book Appointment',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Upcoming Appointments',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[700],
                ),
              ),
              const SizedBox(height: 12),
              if (_appointments.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No upcoming appointments'),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _appointments.length,
                  itemBuilder: (context, index) {
                    final appointment = _appointments[index];
                    return FutureBuilder<String?>(
                      future: Veterinarian.getFullNameById(appointment.vetId),
                      builder: (context, vetSnapshot) {
                        final vetName = vetSnapshot.data ?? 'Loading vet info...';
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: appointment.status == 'pending' 
                                  ? Colors.orange.withOpacity(0.5) 
                                  : Colors.green.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        vetName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: appointment.status == 'pending' 
                                            ? Colors.orange.withOpacity(0.2) 
                                            : Colors.green.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        appointment.status.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: appointment.status == 'pending' 
                                              ? Colors.orange[800] 
                                              : Colors.green[800],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Purpose: ${appointment.purpose}',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      DateFormat('MMM d, y').format(appointment.dateTime),
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      DateFormat('h:mm a').format(appointment.dateTime),
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
            ],
            if (_showForm)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple[100]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Book a Vet Appointment',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Nearby Veterinary Clinics:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...List.generate(_nearbyVets.length, (index) {
                          final vet = _nearbyVets[index];
                          final isSelected = _selectedVet != null && _selectedVet!['id'] == vet['id'];

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedVet = isSelected ? null : vet;
                                _selectedDoctor = null; // Reset selected doctor when clinic changes
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.purple[100] : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? Colors.purple : Colors.grey[300]!,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          vet['image'] as String,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              vet['name'] as String,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(vet['address'] as String),
                                            Row(
                                              children: [
                                                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                                Text(vet['distance'] as String),
                                                const SizedBox(width: 8),
                                                const Icon(Icons.star, size: 14, color: Colors.amber),
                                                Text(vet['rating'].toString()),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Radio<String>(
                                        value: vet['id'] as String,
                                        groupValue: _selectedVet?['id'] as String?,
                                        onChanged: (String? value) {
                                          setState(() {
                                            _selectedVet = value == vet['id'] ? vet : null;
                                            _selectedDoctor = null; // Reset selected doctor when clinic changes
                                          });
                                        },
                                        activeColor: Colors.purple,
                                      ),
                                    ],
                                  ),
                                  if (isSelected && vet['availableDoctors'] != null)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Select Veterinarian:',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        FutureBuilder<List<String>>(
                                          future: Future.wait((vet['availableDoctors'] as List<dynamic>).cast<String>().map((doctorId) => _getDoctorName(doctorId).then((name) => name ?? '')).toList()),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState == ConnectionState.waiting) {
                                              return const CircularProgressIndicator();
                                            } else if (snapshot.hasError) {
                                              return Text('Error: ${snapshot.error}');
                                            } else {
                                              final doctorNames = snapshot.data!;
                                              return Wrap(
                                                spacing: 8,
                                                children: List.generate(vet['availableDoctors'].length, (doctorIndex) {
                                                  final doctorId = vet['availableDoctors'][doctorIndex];
                                                  final doctorName = doctorNames[doctorIndex];
                                                  final isSelectedDoctor = _selectedDoctor == doctorId;

                                                  return ChoiceChip(
                                                    label: Text(doctorName ?? doctorId),
                                                    selected: isSelectedDoctor,
                                                    onSelected: (selected) {
                                                      setState(() {
                                                        _selectedDoctor = selected ? doctorId : null;
                                                      });
                                                    },
                                                    selectedColor: Colors.purple[100],
                                                    backgroundColor: Colors.white,
                                                    labelStyle: TextStyle(
                                                      color: isSelectedDoctor ? Colors.purple : Colors.black,
                                                    ),
                                                  );
                                                }),
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Purpose dropdown
                  Text(
                    'Purpose of Visit:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.purple[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedPurpose,
                        items: _purposes.map((purpose) {
                          return DropdownMenuItem<String>(
                            value: purpose,
                            child: Text(purpose),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedPurpose = value;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Date and time selection
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.purple[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () => _selectDate(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 18, color: Colors.purple),
                                    const SizedBox(width: 8),
                                    Text(DateFormat('MMM d, y').format(_selectedDate)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Time:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.purple[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () => _selectTime(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 18, color: Colors.purple),
                                    const SizedBox(width: 8),
                                    Text(_selectedTime.format(context)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _bookAppointment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Book Appointment',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}