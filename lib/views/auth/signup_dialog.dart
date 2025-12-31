import 'package:flutter/material.dart';
import '../../controllers/auth_controller.dart';
import '../../models/clinic.dart';

const double _maxDialogWidth = 400;

class SignupDialog extends StatelessWidget {
  final void Function(String email, String userType) onSignupSuccess;
  
  const SignupDialog({super.key, required this.onSignupSuccess});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxDialogWidth),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SignupForm(onSignupSuccess: onSignupSuccess),
          ),
        ),
      ),
    );
  }
}

class SignupForm extends StatefulWidget {
  final void Function(String email, String userType) onSignupSuccess;
  
  const SignupForm({super.key, required this.onSignupSuccess});

  @override
  State<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<SignupForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _clinicNameController = TextEditingController(); 
  String _selectedUserType = 'Pet Owner';
  bool _isLoading = false;
  String? _errorMessage;
  
  // Clinic data
  List<Map<String, String>> _clinics = [];
  List<Map<String, String>> _filteredClinics = [];
  bool _isLoadingClinics = false;
  bool _showClinicSuggestions = false;

  final List<String> _userTypes = ['Pet Owner', 'Veterinarian'];

  @override
  void initState() {
    super.initState();
    _clinicNameController.addListener(_onClinicSearchChanged);
  }
  
  // Load clinics when user type changes to Veterinarian
  void _loadClinics() async {
    if (_selectedUserType == 'Veterinarian' && _clinics.isEmpty) {
      setState(() {
        _isLoadingClinics = true;
      });
      
      try {
        _clinics = await Clinic.getAllClinicNamesAndLicenseNumbers();
        // Don't show suggestions immediately after loading
        // Only filter if there's text already in the field
        if (_clinicNameController.text.isNotEmpty) {
          _filterClinics(_clinicNameController.text);
        }
      } catch (e) {
        // Handle error silently
      } finally {
        if (mounted) {
          setState(() {
            _isLoadingClinics = false;
          });
        }
      }
    }
  }
  
  void _onClinicSearchChanged() {
    if (_selectedUserType == 'Veterinarian') {
      _filterClinics(_clinicNameController.text);
    }
  }
  
  void _filterClinics(String query) {
    setState(() {
      if (query.isEmpty) {
        // When the field is empty, don't show any suggestions
        _showClinicSuggestions = false;
      } else {
        // Filter clinics based on query
        final lowercaseQuery = query.toLowerCase();
        _filteredClinics = _clinics.where((clinic) {
          final name = clinic['name']?.toLowerCase() ?? '';
          final license = clinic['licenseNumber']?.toLowerCase() ?? '';
          return name.contains(lowercaseQuery) || license.contains(lowercaseQuery);
        }).toList();
        // Only show suggestions if we have results or if the user is actively typing
        _showClinicSuggestions = _filteredClinics.isNotEmpty;
      }
    });
  }
  
  void _selectClinic(Map<String, String> clinic) {
    setState(() {
      _clinicNameController.text = clinic['name'] ?? '';
      _showClinicSuggestions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Create Account',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _selectedUserType,
            decoration: const InputDecoration(
              labelText: 'User Type',
              border: OutlineInputBorder(),
            ),
            items: _userTypes.map((String type) {
              return DropdownMenuItem<String>(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedUserType = newValue!;
                if (_selectedUserType == 'Veterinarian') {
                  _loadClinics();
                } else {
                  // Clear clinic field when switching to pet owner
                  _clinicNameController.clear();
                  _showClinicSuggestions = false;
                }
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a user type';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _fullNameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your full name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Clinic name field with autocomplete
          if (_selectedUserType == 'Veterinarian')
            Column(
              children: [
                TextFormField(
                  controller: _clinicNameController,
                  decoration: InputDecoration(
                    labelText: 'Clinic Name',
                    border: const OutlineInputBorder(),
                    suffixIcon: _isLoadingClinics 
                        ? const SizedBox(
                            width: 20, 
                            height: 20, 
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ) 
                        : null,
                    hintText: 'Enter clinic name or license number',
                  ),
                  onTap: () {
                    if (_clinics.isEmpty) {
                      _loadClinics();  // Load clinics if they haven't been loaded yet
                    }
                    // Don't show suggestions on tap - wait for user to type
                  },
                  onChanged: (_) => _onClinicSearchChanged(),
                  validator: (value) {
                    if (_selectedUserType == 'Veterinarian' && (value == null || value.isEmpty)) {
                      return 'Please enter your clinic name';
                    }
                    return null;
                  },
                ),
                if (_showClinicSuggestions && _filteredClinics.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _filteredClinics.length,
                      itemBuilder: (context, index) {
                        final clinic = _filteredClinics[index];
                        return ListTile(
                          dense: true,
                          title: Text(
                            clinic['name'] ?? '',
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            'License: ${clinic['licenseNumber'] ?? ''}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          onTap: () => _selectClinic(clinic),
                          hoverColor: Colors.grey.shade200,
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSignup,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Sign Up'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authController = AuthController();
      bool success;
      
      if (_selectedUserType == 'Veterinarian') {
        // Find the clinic license number based on the clinic name entered/selected
        String clinicLicenseNumber = '';
        
        // Look through filtered clinics or all clinics to find matching clinic
        final clinicsList = _filteredClinics.isNotEmpty ? _filteredClinics : _clinics;
        for (var clinic in clinicsList) {
          if (clinic['name'] == _clinicNameController.text) {
            clinicLicenseNumber = clinic['licenseNumber'] ?? '';
            break;
          }
        }
        
        // If no license number found, show error
        if (clinicLicenseNumber.isEmpty) {
          setState(() {
            _errorMessage = 'Unable to find clinic license number. Please select a clinic from the dropdown.';
            _isLoading = false;
          });
          return;
        }
        
        success = await authController.registerVets(
          _emailController.text.trim(),
          _passwordController.text,
          _fullNameController.text,
          clinicLicenseNumber, // Pass the license number instead of clinic ID
        );
      } else {
        success = await authController.registerPetOwner(
          _emailController.text.trim(),
          _passwordController.text,
          _fullNameController.text,
        );
      }

      if (success && mounted) {
        Navigator.of(context).pop();
        widget.onSignupSuccess(_emailController.text.trim(), _selectedUserType);
      } else {
        setState(() {
          _errorMessage = 'Failed to create account';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _clinicNameController.removeListener(_onClinicSearchChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _clinicNameController.dispose();
    super.dispose();
  }
}