import 'package:flutter/material.dart';
import '../views/chat/chat_list_page.dart' as chat;

class ChatIconButton extends StatelessWidget {
  const ChatIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const chat.ChatListPage()),
            );
          },
          tooltip: 'Chat with Vets',
        ),
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(6),
            ),
            constraints: const BoxConstraints(
              minWidth: 12,
              minHeight: 12,
            ),
          ),
        ),
      ],
    );
  }
}