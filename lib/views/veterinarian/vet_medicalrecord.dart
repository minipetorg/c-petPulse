import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/appointment.dart';
import '../../../models/medical_record.dart';
import 'package:intl/intl.dart';

class VetMedicalRecordPage extends StatefulWidget {
  final Appointment appointment;

  const VetMedicalRecordPage({super.key, required this.appointment});

  @override
  _VetMedicalRecordPageState createState() => _VetMedicalRecordPageState();
}

class _VetMedicalRecordPageState extends State<VetMedicalRecordPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  String? _error;
  
  // Form fields
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _treatmentController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  
  // Vaccination fields
  bool _isVaccinated = false;
  final TextEditingController _vaccineTypeController = TextEditingController();
  final TextEditingController _nextDoseController = TextEditingController();
  DateTime? _nextDoseDate;

  @override
  void dispose() {
    _notesController.dispose();
    _diagnosisController.dispose();
    _treatmentController.dispose();
    _weightController.dispose();
    _vaccineTypeController.dispose();
    _nextDoseController.dispose();
    super.dispose();
  }

  Future<void> _selectNextDoseDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _nextDoseDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _nextDoseDate) {
      setState(() {
        _nextDoseDate = picked;
        _nextDoseController.text = DateFormat('MMM d, y').format(picked);
      });
    }
  }

  // Convert treatment string to a list of treatments
  List<String> _parseTreatments(String treatmentText) {
    if (treatmentText.isEmpty) return [];
    
    // Split by new lines or semicolons to separate treatments
    final treatments = treatmentText
        .split(RegExp(r'[\n;]'))
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    
    return treatments;
  }

  Future<void> _saveMedicalRecord() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    
    try {
      // Create the medical record object
      final medicalRecord = MedicalRecord(
        vetId: widget.appointment.vetId,
        petId: widget.appointment.petId,
        appointmentId: widget.appointment.id,
        dateTime: DateTime.now(),
        petWeight: _weightController.text.isNotEmpty ? double.parse(_weightController.text) : 0.0,
        medicalNotes: _notesController.text,
        treatments: _parseTreatments(_treatmentController.text),
        isVaccined: _isVaccinated,
        vaccineType: _vaccineTypeController.text,
        nextDoseDate: _nextDoseDate,
      );
      
      // Save to Firestore using the createMedicalRecord method
      final success = await MedicalRecord.createMedicalRecord(medicalRecord);
      
      if (success) {
        // Show success message and navigate back
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Medical record saved successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        }
      } else {
        throw Exception('Failed to create medical record');
      }
    } catch (e) {
      print('Error saving medical record: $e');
      setState(() {
        _error = e.toString();
        _isSubmitting = false;
      });
    }
  }

  Widget _buildVaccinationSection() {
    if (!widget.appointment.purpose.toLowerCase().contains('vaccin') &&
        !widget.appointment.purpose.toLowerCase().contains('medical issue')) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vaccination Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          
          const SizedBox(height: 16),
          
          SwitchListTile(
            title: const Text('Vaccination Administered'),
            subtitle: const Text('Toggle on if vaccine was given today'),
            value: _isVaccinated,
            activeColor: Theme.of(context).primaryColor,
            contentPadding: EdgeInsets.zero,
            onChanged: (value) {
              setState(() {
                _isVaccinated = value;
              });
            },
          ),
          
          if (_isVaccinated) ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: _vaccineTypeController,
              decoration: InputDecoration(
                labelText: 'Vaccine Type',
                prefixIcon: const Icon(Icons.medication_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (_isVaccinated && (value == null || value.isEmpty)) {
                  return 'Please enter the vaccine type';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _nextDoseController,
              decoration: InputDecoration(
                labelText: 'Next Dose Date (if applicable)',
                prefixIcon: const Icon(Icons.event),
                suffixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              readOnly: true,
              onTap: () => _selectNextDoseDate(context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCheckupSection() {
    if (!widget.appointment.purpose.toLowerCase().contains('check')) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Checkup Results',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _diagnosisController,
            decoration: InputDecoration(
              labelText: 'Diagnosis',
              hintText: 'Enter findings from examination',
              prefixIcon: const Icon(Icons.fact_check_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            maxLines: 3,
            validator: (value) {
              if (widget.appointment.purpose.toLowerCase().contains('check') && 
                  (value == null || value.isEmpty)) {
                return 'Please enter diagnosis or "No issues found"';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Medical Record'),
        elevation: 2,
      ),
      body: _isSubmitting 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Saving medical record...',
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
              ],
            ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pet and appointment info in a decorated card
                  Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.pets, color: Theme.of(context).primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                'Pet ID: ${widget.appointment.petId}',
                                style: const TextStyle(
                                  fontSize: 16, 
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.medical_services_outlined, color: Theme.of(context).primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                'Purpose: ${widget.appointment.purpose}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                'Date: ${DateFormat('MMM d, y').format(widget.appointment.dateTime)}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.access_time, color: Theme.of(context).primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                'Time: ${DateFormat('h:mm a').format(widget.appointment.dateTime)}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Weight input in a styled container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.monitor_weight, color: Colors.amber[800]),
                            const SizedBox(width: 8),
                            const Text(
                              'Pet Weight',
                              style: TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _weightController,
                                decoration: InputDecoration(
                                  labelText: 'Weight (kg)',
                                  hintText: 'e.g., 5.2',
                                  prefixIcon: const Icon(Icons.scale),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    try {
                                      double.parse(value);
                                    } catch (e) {
                                      return 'Please enter a valid number';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'kg', 
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Notes & Treatment section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Clinical Notes',
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _notesController,
                          decoration: InputDecoration(
                            labelText: 'Medical Notes',
                            hintText: 'Enter observations or notes about the pet',
                            prefixIcon: const Icon(Icons.notes),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          maxLines: 3,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _treatmentController,
                          decoration: InputDecoration(
                            labelText: 'Treatments/Prescriptions',
                            hintText: 'Enter each treatment on a new line or separate with semicolons',
                            prefixIcon: const Icon(Icons.medication),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            helperText: 'Example: Antibiotics 500mg\nPain medication\nDietary changes',
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                  
                  // Conditional sections based on appointment purpose
                  _buildVaccinationSection(),
                  
                  _buildCheckupSection(),
                  
                  // Error message if any
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Error: $_error',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  // Submit button
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _saveMedicalRecord,
                      icon: const Icon(Icons.save),
                      label: const Text(
                        'SAVE MEDICAL RECORD',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 3,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
    );
  }
}