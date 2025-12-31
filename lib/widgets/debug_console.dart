import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DebugConsole extends StatefulWidget {
  final String error;
  final VoidCallback? onRetry;

  const DebugConsole({
    super.key, 
    required this.error, 
    this.onRetry,
  });

  @override
  State<DebugConsole> createState() => _DebugConsoleState();
}

class _DebugConsoleState extends State<DebugConsole> {
  bool _expanded = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Firebase Error'),
            subtitle: Text(
              widget.error.length > 100 
                  ? '${widget.error.substring(0, 100)}...'
                  : widget.error,
              style: const TextStyle(color: Colors.red),
            ),
            trailing: IconButton(
              icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () => setState(() => _expanded = !_expanded),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Debug Information:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('User ID: ${_auth.currentUser?.uid ?? 'Not signed in'}'),
                  Text('User Email: ${_auth.currentUser?.email ?? 'Not signed in'}'),
                  const SizedBox(height: 16),
                  const Text(
                    'Possible Solutions:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildSolution(
                    '1. Firebase Security Rules',
                    'Your Firestore security rules are restricting access. Update them in Firebase Console.',
                    Icons.security,
                  ),
                  _buildSolution(
                    '2. Authentication',
                    'Make sure you\'re properly authenticated with the right permissions.',
                    Icons.person,
                  ),
                  _buildSolution(
                    '3. Collection/Document Path',
                    'Check if you\'re trying to access the correct path in Firestore.',
                    Icons.folder,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (widget.onRetry != null)
                        ElevatedButton(
                          onPressed: widget.onRetry,
                          child: const Text('Retry'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSolution(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.red.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(description, style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
