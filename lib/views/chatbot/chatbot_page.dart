import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});
  @override
  ChatbotPageState createState() => ChatbotPageState();
}

class ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final String apiKey = const String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'YOUR_API_KEY_HERE',
  );

  void _sendMessage(String text) async {
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': text});
    });
    _controller.clear();

    try {
      final response = await http.post(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key=$apiKey',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text":
                      "You are a helpful assistant knowledgeable about pets, pet diseases, and pet care.\n\nUser: $text",
                },
              ],
            },
          ],
          "generationConfig": {"temperature": 0.7, "maxOutputTokens": 800},
        }),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final botMessage = data['candidates'][0]['content']['parts'][0]['text']
            .toString()
            .trim();
        setState(() {
          _messages.add({'sender': 'bot', 'text': botMessage});
        });
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          _messages.add({
            'sender': 'bot',
            'text': 'Error: ${errorData['error']['message']}',
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'sender': 'bot',
          'text': 'Error: Unable to fetch response. Exception: $e',
        });
      });
      print('Exception: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 151, 136, 250),
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(106, 16, 3, 75),
          title: const Text(
            'AI Companion',
            style: TextStyle(color: Colors.white),
          ),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return Align(
                    alignment: message['sender'] == 'user'
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: message['sender'] == 'user'
                            ? Colors.white.withOpacity(0.9)
                            : Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        message['text']!,
                        style: TextStyle(
                          color: message['sender'] == 'user'
                              ? const Color.fromARGB(255, 32, 6, 227)
                              : Colors.black87,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.white.withOpacity(0.1),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: Colors.white70),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () => _sendMessage(_controller.text),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
