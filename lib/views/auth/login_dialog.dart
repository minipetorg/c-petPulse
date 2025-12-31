import 'package:flutter/material.dart';
import '../../controllers/auth_controller.dart';

const double _maxDialogWidth = 400;


class LoginDialog extends StatefulWidget {

  final void Function(String email, String userType) onLoginSuccess;
  
  const LoginDialog({super.key, required this.onLoginSuccess});

  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxDialogWidth),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: LoginForm(
              onLoginSuccess: (email, userType) => widget.onLoginSuccess(email, userType),
            ),
          ),
        ),
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  final void Function(String email, String userType) onLoginSuccess;
  const LoginForm({super.key, required this.onLoginSuccess});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedUserType = 'Pet Owner';  // Fixed capitalization
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Ensure Pet Owner is selected by default
    _selectedUserType = 'Pet Owner';
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'Pet Owner',
                label: Text('Pet Owner'),
                icon: Icon(Icons.pets),
              ),
              ButtonSegment(
                value: 'Veterinarian',
                label: Text('Veterinarian'),
                icon: Icon(Icons.medical_services),
              ),
            ],
            selected: {_selectedUserType},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                _selectedUserType = newSelection.first;
              });
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
              return null;
            },
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
              onPressed: _isLoading ? null : _handleLogin,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Login'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authController = AuthController();
      final success = await authController.login(
        _emailController.text.trim(),
        _passwordController.text,
        _selectedUserType,
      );

      if (success && mounted) {
        Navigator.of(context).pop();
        widget.onLoginSuccess(_emailController.text.trim(), _selectedUserType);
      } else {
        setState(() {
          _errorMessage = 'Invalid email or password';
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}