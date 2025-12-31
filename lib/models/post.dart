import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Post {
  final String id;
  final String createdBy;
  final int likeCount;
  final String content;
  final DateTime createdAt;
  final String? imageUrl;
  final List<String> likes;
  final String type; // 'text', 'image', etc.
  final String title;  // Added title
  final List<String> taggedPets; // Add tagged pets list

  Post({
    required this.id,
    required this.createdBy,
    required this.content,
    required this.createdAt,
    required this.title,  // Added title parameter
    this.likeCount = 0,
    this.imageUrl,
    List<String>? likes,
    this.type = 'text',
    List<String>? taggedPets, // Add to constructor
  }) : likes = likes ?? [],
       taggedPets = taggedPets ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'createdBy': createdBy,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'likeCount': likeCount,
      'imageUrl': imageUrl,
      'likes': likes,
      'type': type,
      'title': title,  // Added title to map
      'taggedPets': taggedPets, // Add to map
    };
  }

  factory Post.fromMap(Map<String, dynamic> map, String documentId) {
    return Post(
      id: documentId,
      createdBy: map['createdBy'] ?? '',
      content: map['content'] ?? '',
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      likeCount: map['likeCount']?.toInt() ?? 0,
      imageUrl: map['imageUrl'],
      likes: List<String>.from(map['likes'] ?? []),
      type: map['type'] ?? 'text',
      title: map['title'] ?? '',  // Added title from map
      taggedPets: List<String>.from(map['taggedPets'] ?? []), // Add to fromMap
    );
  }

  static Future<String> createPost(Post post) async {
    try {
      final docRef = await FirebaseFirestore.instance
          .collection('posts')
          .add(post.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating post: $e');
      return '';
    }
  }

  static Future<List<Post>> getPosts() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Post.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error fetching posts: $e');
      return [];
    }
  }

  static Future<List<Post>> getPostsByTaggedPet(String petId) async {
    try {
      print("Querying posts for petId: $petId");
      
      // Query will work once index is built
      final querySnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('taggedPets', arrayContains: petId)
          .orderBy('createdAt', descending: true)
          .get();

      print("Found ${querySnapshot.docs.length} posts");
      return querySnapshot.docs
          .map((doc) => Post.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error fetching posts by pet: $e');
      return [];
    }
  }

  static Future<bool> deletePost(String postId) async {
    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .delete();
      return true;
    } catch (e) {
      print('Error deleting post: $e');
      return false;
    }
  }

  static Future<bool> toggleLike(String postId, String userId) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('posts')
          .doc(postId);
      
      final doc = await docRef.get();
      if (!doc.exists) return false;

      final post = Post.fromMap(doc.data()!, doc.id);
      final likes = post.likes;

      if (likes.contains(userId)) {
        likes.remove(userId);
      } else {
        likes.add(userId);
      }

      await docRef.update({
        'likes': likes,
        'likeCount': likes.length,
      });

      return true;
    } catch (e) {
      print('Error toggling like: $e');
      return false;
    }
  }
}