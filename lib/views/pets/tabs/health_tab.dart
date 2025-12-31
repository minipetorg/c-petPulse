import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/appointment.dart';
import '../../../models/medical_record.dart';
import '../../../models/vaccination.dart';
import '../../../models/clinic.dart';
import '../../../models/veterinarian.dart';

class HealthTab extends StatelessWidget {
  final Map<String, String> pet;

  const HealthTab({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        FutureBuilder<Vaccination?>(
          future: Vaccination.getLatestVaccinationByPetId(pet['id'] ?? ''),
          builder: (context, snapshot) {
            String status = 'No vaccination records found';
            if (snapshot.connectionState == ConnectionState.waiting) {
              status = 'Loading...';
            } else if (snapshot.hasError) {
              status = 'Error loading vaccination';
              print(snapshot.error);
            } else if (snapshot.hasData && snapshot.data != null) {
              final now = DateTime.now();
              final nextDoseDate = snapshot.data!.nextDoseDate;
              if (nextDoseDate.isAfter(now)) {
                status = 'Next dose due on ${DateFormat('MMM d, y').format(nextDoseDate)}';
              } else {
                status = 'Vaccination overdue since ${DateFormat('MMM d, y').format(nextDoseDate)}';
              }
            }
            return HealthCard(
              title: 'Vaccination Status',
              status: status,
              icon: Icons.verified,
              color: Colors.green,
              onTap: () => _showVaccinationHistory(context),
            );
          },
        ),
        FutureBuilder<Appointment?>(
          future: Appointment.getLastCompletedAppointment(pet['id'] ?? ''),
          builder: (context, snapshot) {
            String status = 'No check-ups found';
            if (snapshot.connectionState == ConnectionState.waiting) {
              status = 'Loading...';
            } else if (snapshot.hasError) {
              status = 'Error loading check-up';
              print(snapshot.error);
            } else if (snapshot.hasData && snapshot.data != null) {
              status = Appointment.timeAgoSinceDate(snapshot.data!.dateTime);
            }
            return HealthCard(
              title: 'Last Check-up',
              status: status,
              icon: Icons.calendar_today,
              color: Colors.blue,
              onTap: () => _showCheckupHistory(context),
            );
          },
        ),
        FutureBuilder<MedicalRecord?>(
          future: MedicalRecord.getLatestMedicalRecordByPetId(pet['id'] ?? ''),
          builder: (context, snapshot) {
            String status = 'No weight records found';
            if (snapshot.connectionState == ConnectionState.waiting) {
              status = 'Loading...';
            } else if (snapshot.hasError) {
              status = 'Error loading weight';
              print(snapshot.error);
            } else if (snapshot.hasData && snapshot.data != null) {
              status = '${snapshot.data!.petWeight} kg';
            }
            return HealthCard(
              title: 'Weight',
              status: status,
              icon: Icons.monitor_weight,
              color: Colors.orange,
            );
          },
        ),
      ],
    );
  }

  void _showVaccinationHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Vaccination History',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: VaccinationHistoryList(
                  petId: pet['id'] ?? '',
                  scrollController: ScrollController(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCheckupHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Check-up History',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: CheckupHistoryList(
                  petId: pet['id'] ?? '',
                  scrollController: ScrollController(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HealthCard extends StatelessWidget {
  final String title;
  final String status;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const HealthCard({
    super.key,
    required this.title,
    required this.status,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple[50],
          child: Icon(icon, color: Colors.purple),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.purple,
          ),
        ),
        subtitle: Text(status),
        trailing: onTap != null ? const Icon(Icons.arrow_forward_ios, size: 16) : null,
        onTap: onTap,
      ),
    );
  }
}

class VaccinationHistoryList extends StatelessWidget {
  final String petId;
  final ScrollController scrollController;

  const VaccinationHistoryList({
    super.key,
    required this.petId,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Vaccination>>(
      future: Vaccination.getAllVaccinationsByPetId(petId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No vaccination records found.'));
        } else {
          final vaccinations = snapshot.data!;
          return ListView.builder(
            controller: scrollController,
            itemCount: vaccinations.length,
            itemBuilder: (context, index) {
              final vaccination = vaccinations[index];
              final DateTime date = vaccination.nextDoseDate;
              final DateTime validUntil = vaccination.nextDoseDate;

              return FutureBuilder<Map<String, String>>(
                future: _fetchClinicAndVetInfo(vaccination.vetId, vaccination.medicalRecordId),
                builder: (context, infoSnapshot) {
                  if (infoSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (infoSnapshot.hasError) {
                    return Center(child: Text('Error: ${infoSnapshot.error}'));
                  } else if (!infoSnapshot.hasData) {
                    return const Center(child: Text('No additional info found.'));
                  } else {
                    final info = infoSnapshot.data!;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.medical_services, color: Colors.purple),
                                const SizedBox(width: 8),
                                Text(
                                  vaccination.vaccineType,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(Icons.calendar_today, 'Date', DateFormat('MMM d, y').format(date)),
                            _buildInfoRow(Icons.event_available, 'Valid Until', DateFormat('MMM d, y').format(validUntil)),
                            _buildInfoRow(Icons.person, 'Vet', 'Dr. ${info['vetName']}' ?? 'Unknown Vet'),
                            _buildInfoRow(Icons.local_hospital, 'Clinic', info['clinicName'] ?? 'Unknown Clinic'),
                          ],
                        ),
                      ),
                    );
                  }
                },
              );
            },
          );
        }
      },
    );
  }

  Future<Map<String, String>> _fetchClinicAndVetInfo(String vetId, String medicalRecordId) async {
    final vetName = await Veterinarian.getFullNameById(vetId);
    final clinic = await Clinic.getClinicByVetId(vetId);
    return {
      'vetName': vetName ?? 'Unknown Vet',
      'clinicName': clinic?.name ?? 'Unknown Clinic',
    };
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CheckupHistoryList extends StatelessWidget {
  final String petId;
  final ScrollController scrollController;

  const CheckupHistoryList({
    super.key,
    required this.petId,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MedicalRecord>>(
      future: MedicalRecord.getAllMedicalRecordsByPetId(petId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No check-up records found.'));
        } else {
          final checkups = snapshot.data!;
          return ListView.builder(
            controller: scrollController,
            itemCount: checkups.length,
            itemBuilder: (context, index) {
              final checkup = checkups[index];
              final DateTime date = checkup.dateTime;

              return FutureBuilder<Map<String, String>>(
                future: _fetchClinicAndVetInfo(checkup.vetId, checkup.appointmentId),
                builder: (context, infoSnapshot) {
                  if (infoSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (infoSnapshot.hasError) {
                    return Center(child: Text('Error: ${infoSnapshot.error}'));
                  } else if (!infoSnapshot.hasData) {
                    return const Center(child: Text('No additional info found.'));
                  } else {
                    final info = infoSnapshot.data!;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, color: Colors.blue),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('MMM d, y').format(date),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(Icons.person, 'Vet', 'Dr. ${info['vetName']}' ?? 'Unknown Vet'),
                            _buildInfoRow(Icons.local_hospital, 'Clinic', info['clinicName'] ?? 'Unknown Clinic'),
                            _buildInfoRow(Icons.notes, 'Medical Notes', checkup.medicalNotes),
                            _buildInfoRow(Icons.medical_services, 'Prescription', checkup.treatments.join(', ')),
                          ],
                        ),
                      ),
                    );
                  }
                },
              );
            },
          );
        }
      },
    );
  }

  Future<Map<String, String>> _fetchClinicAndVetInfo(String vetId, String appointmentId) async {
    final vetName = await Veterinarian.getFullNameById(vetId);
    final clinic = await Clinic.getClinicByVetId(vetId);
    return {
      'vetName': vetName ?? 'Unknown Vet',
      'clinicName': clinic?.name ?? 'Unknown Clinic',
    };
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
