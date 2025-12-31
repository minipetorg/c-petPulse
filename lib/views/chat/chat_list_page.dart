import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Add missing import
import '../../models/chat.dart';
import '../../services/chat_service.dart';
import '../../widgets/debug_console.dart';
import '../../models/veterinarian.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? userType;
  bool isLoading = true;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<DocumentSnapshot> _searchResults = [];
  List<Map<String, dynamic>> veterinarians = [];

  @override
  void initState() {
    super.initState();
    _loadUserType();
    _tabController = TabController(length: 2, vsync: this);
    _loadVeterinarians();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserType() async {
    final chatService = Provider.of<ChatService>(context, listen: false);
    try {
      final type = await chatService.getCurrentUserType();
      if (mounted) {
        setState(() {
          userType = type;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user type: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadVeterinarians() async {
    final vets = await Veterinarian.getAllVeterinariansDetailed();
    if (mounted) {
      setState(() {
        veterinarians = vets;
        isLoading = false;
      });
    }
  }

  void _searchVets(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final chatService = Provider.of<ChatService>(context, listen: false);
      final result = await chatService.searchVets(query);
      
      if (mounted) {
        setState(() {
          _searchResults = result.docs;
        });
      }
    } catch (e) {
      debugPrint('Error searching vets: $e');
      if (mounted) {
        setState(() {
          _searchResults = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return userType == 'vet' 
      ? const VetChatListView() 
      : PetOwnerChatListView(
          searchController: _searchController,
          isSearching: _isSearching,
          searchResults: _searchResults,
          onSearch: _searchVets,
          tabController: _tabController,
          veterinarians: veterinarians,
        );
  }
}

class VetChatListView extends StatelessWidget {
  const VetChatListView({super.key});

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Patient Chats'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: chatService.getVetChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  ElevatedButton(
                    onPressed: () {
                      // Force refresh
                      (context as Element).markNeedsBuild();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final chatDocs = snapshot.data?.docs ?? [];
          
          if (chatDocs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No chats yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Pet owners will contact you here',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              final chatDoc = chatDocs[index];
              final data = chatDoc.data() as Map<String, dynamic>;
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(Icons.pets, color: Colors.white),
                ),
                title: Text(data['petOwnerEmail'] ?? 'Unknown Pet Owner'),
                subtitle: Text(
                  data['lastMessage'] != null && data['lastMessage'].isNotEmpty
                    ? data['lastMessage']
                    : 'No messages yet',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: data['lastMessageTime'] != null
                    ? Text(
                        _formatTimestamp(data['lastMessageTime'] as Timestamp),
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    : null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        chatId: chatDoc.id,
                        otherUserEmail: data['petOwnerEmail'] ?? 'Unknown Pet Owner',
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateToCheck = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (dateToCheck == today) {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

class PetOwnerChatListView extends StatelessWidget {
  final TextEditingController searchController;
  final bool isSearching;
  final List<DocumentSnapshot> searchResults;
  final Function(String) onSearch;
  final TabController tabController;
  final List<Map<String, dynamic>> veterinarians;

  const PetOwnerChatListView({
    Key? key,
    required this.searchController,
    required this.isSearching,
    required this.searchResults,
    required this.onSearch,
    required this.tabController,
    required this.veterinarians,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat with Vets'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        bottom: TabBar(
          controller: tabController,
          tabs: const [
            Tab(text: 'Chats'),
            Tab(text: 'Find Veterinarians'),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          _buildChatsList(context),
          _buildVeterinariansList(),
        ],
      ),
    );
  }

  Widget _buildChatsList(BuildContext context) {
    final chatService = Provider.of<ChatService>(context);
    
    return StreamBuilder<QuerySnapshot>(
      stream: chatService.getPetOwnerChats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => tabController.animateTo(1),
                  child: const Text('Find a Veterinarian'),
                ),
              ],
            ),
          );
        }

        final chatDocs = snapshot.data?.docs ?? [];
        
        if (chatDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No conversations yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => tabController.animateTo(1),
                  child: const Text('Find a Veterinarian'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: chatDocs.length,
          itemBuilder: (context, index) {
            final chatDoc = chatDocs[index];
            final data = chatDoc.data() as Map<String, dynamic>;
            
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                child: const Icon(Icons.medical_services, color: Colors.white),
              ),
              title: Text(data['vetEmail'] ?? 'Unknown Vet'),
              subtitle: Text(
                data['lastMessage'] != null && data['lastMessage'].isNotEmpty 
                  ? data['lastMessage'] 
                  : 'No messages yet',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: data['lastMessageTime'] != null
                  ? Text(
                      _formatTimestamp(data['lastMessageTime'] as Timestamp),
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  : null,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      chatId: chatDoc.id,
                      otherUserEmail: data['vetEmail'] ?? 'Unknown Vet',
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildVeterinariansList() {
    if (isSearching) {
      return _buildSearchResults();
    }

    if (veterinarians.isEmpty) {
      return const Center(child: Text('No veterinarians available'));
    }

    return ListView.builder(
      itemCount: veterinarians.length,
      itemBuilder: (context, index) {
        final vet = veterinarians[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: vet['photoUrl']?.isNotEmpty == true
                ? NetworkImage(vet['photoUrl'])
                : null,
            child: vet['photoUrl']?.isNotEmpty != true
                ? const Icon(Icons.person)
                : null,
          ),
          title: Text(vet['fullName']),
          subtitle: Text(vet['specialization']),
          trailing: const Icon(Icons.chat_bubble_outline),
          onTap: () async {
            final chatService = Provider.of<ChatService>(context, listen: false);
            try {
              final chatId = await chatService.createOrGetChatId(vet['id']);
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      chatId: chatId,
                      otherUserEmail: vet['fullName'],
                    ),
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error starting chat: $e')),
                );
              }
            }
          },
        );
      },
    );
  }

  Widget _buildSearchResults() {
    if (searchResults.isEmpty) {
      return const Center(
        child: Text('No veterinarians found'),
      );
    }

    return ListView.builder(
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        return _buildVetListItem(context, searchResults[index]);
      },
    );
  }

  Widget _buildVetListItem(BuildContext context, DocumentSnapshot vetDoc) {
    final chatService = Provider.of<ChatService>(context, listen: false);
    final vetData = vetDoc.data() as Map<String, dynamic>;
    final String vetId = vetDoc.id;
    final String vetName = vetData['email'] ?? vetData['displayName'] ?? 'Unknown Vet';
    final String specialization = vetData['specialization'] ?? 'General Veterinarian';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: Text(
          vetName.isNotEmpty ? vetName[0].toUpperCase() : '?',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(vetName),
      subtitle: Text(specialization),
      trailing: const Icon(Icons.chat_bubble_outline),
      onTap: () async {
        try {
          final chatId = await chatService.createOrGetChatId(vetId);
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  chatId: chatId,
                  otherUserEmail: vetName,
                ),
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Unable to start chat: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final formatter = DateFormat('MMM d');
    return formatter.format(dateTime);
  }
}

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserEmail;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserEmail,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    _messageController.clear();
    await _chatService.sendMessage(widget.chatId, messageText);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserEmail),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;
                
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index].data() as Map<String, dynamic>;
                    final isCurrentUser = message['senderId'] == FirebaseAuth.instance.currentUser?.uid;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Align(
                        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isCurrentUser 
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            message['text'] ?? '',
                            style: TextStyle(
                              color: isCurrentUser ? Colors.white : null,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
