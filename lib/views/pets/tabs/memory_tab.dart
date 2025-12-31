import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/post.dart';

class MemoryTab extends StatelessWidget {
  final Map<String, String> currentPet;

  const MemoryTab({
    Key? key,
    required this.currentPet,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print("PetID:: ${currentPet['id']}");
    return FutureBuilder<List<Post>>(
      future: Post.getPostsByTaggedPet(currentPet['id'] ?? ''),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading memories: ${snapshot.error}'),
          );
        }

        final posts = snapshot.data ?? [];
        if (posts.isEmpty) {
          return const Center(
            child: Text('No memories found for this pet'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(post.content),
                      ],
                    ),
                  ),
                  if (post.imageUrl != null)
                    Image.network(
                      post.imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
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
                            const Icon(Icons.favorite, color: Colors.red),
                            const SizedBox(width: 4),
                            Text('${post.likes.length}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
