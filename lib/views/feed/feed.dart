import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/post.dart' ;
import '../../models/user.dart' as user_;
import '../../models/pet.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../../services/auth_service.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Post> _posts = [];
  List<Post> _myPosts = [];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    try {
      final allPosts = await Post.getPosts();
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      
      if (mounted) {
        setState(() {
          _posts = allPosts;
          if (currentUserId != null) {
            _myPosts = allPosts.where((post) => post.createdBy == currentUserId).toList();
          }
        });
      }
    } catch (e) {
      print('Error loading posts: $e');
    }
  }

  Future<void> _handleDeletePost(Post post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await Post.deletePost(post.id);
      if (success) {
        await _loadPosts();
      }
    }
  }

  Future<void> _handleLikePress(Post post) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final success = await Post.toggleLike(post.id, userId);
    if (success) {
      await _loadPosts();
    }
  }

  Widget _buildPostCard(Post post) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = post.createdBy == currentUserId;
    final authService = AuthService();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isOwner)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _handleDeletePost(post),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            FutureBuilder<String>(
              future: authService.getUserType().then((userType) {
                return user_.User.getUserFullName(post.createdBy, userType ?? 'user');
              }),
              builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return const Text('Error loading user name');
              } else {
                return Text('By ${snapshot.data}');
              }
              },
            ),
            if (post.taggedPets.isNotEmpty)
              FutureBuilder<List<String>>(
              future: Pet.getPetNamesByIds(post.taggedPets),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                return const Text('Error loading pet names');
                } else {
                const SizedBox(height: 8);
                return Text('Tags: ${snapshot.data!.join(', ')}');
                }
              },
              ),
            const SizedBox(height: 8),
            Text(post.content),
            const SizedBox(height: 8),
            if (post.imageUrl != null)
              Image.network(
                post.imageUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM d, y').format(post.createdAt),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        post.likes.contains(FirebaseAuth.instance.currentUser?.uid)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: Colors.red,
                      ),
                      onPressed: () => _handleLikePress(post),
                    ),
                    Text('${post.likes.length} likes'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            border: Border(
              bottom: BorderSide(
                color: Colors.purple.shade100,
                width: 0.5,
              ),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Recent Posts'),
              Tab(text: 'My Posts'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ListView.builder(
            itemCount: _posts.length,
            itemBuilder: (context, index) => _buildPostCard(_posts[index]),
          ),
          ListView.builder(
            itemCount: _myPosts.length,
            itemBuilder: (context, index) => _buildPostCard(_myPosts[index]),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPostDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showPostDialog() {
    List<String> selectedPetIds = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Post'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: "What's on your mind?",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<Pet>>(
                  stream: Pet.getPetsByUser(FirebaseAuth.instance.currentUser!.uid),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tag your pets:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10,),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: snapshot.data!.map((pet) => InkWell(
                            onTap: () {
                              setState(() {
                                if (selectedPetIds.contains(pet.id)) {
                                  selectedPetIds.remove(pet.id);
                                } else {
                                  selectedPetIds.add(pet.id!);
                                }
                              });
                            },
                            child: Chip(
                              //padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              backgroundColor: selectedPetIds.contains(pet.id)
                                  ? Colors.purple[100]
                                  : Colors.grey[200],
                              label: Text(
                                pet.name,
                                style: TextStyle(
                                  color: selectedPetIds.contains(pet.id)
                                      ? Colors.purple
                                      : Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              avatar: Icon(
                                Icons.pets,
                                size: 18,
                                color: selectedPetIds.contains(pet.id)
                                    ? Colors.purple
                                    : Colors.grey,
                              ),
                            ),
                          )).toList(),
                        ),
                      ],
                    );
                  },
                ),
                ElevatedButton(
                  onPressed: () async {
                    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      setState(() {
                        _selectedImage = File(pickedFile.path);
                      });
                    }
                  },
                  child: const Text('Select Image'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (_titleController.text.isNotEmpty && 
                    _contentController.text.isNotEmpty) {
                  final newPost = Post(
                    id: '',
                    createdBy: FirebaseAuth.instance.currentUser!.uid,
                    title: _titleController.text,
                    content: _contentController.text,
                    createdAt: DateTime.now(),
                    imageUrl: null,
                    taggedPets: selectedPetIds,
                  );

                  await Post.createPost(newPost);
                  if (mounted) {
                    Navigator.of(context).pop();
                    _loadPosts();
                  }
                }
              },
              child: const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}