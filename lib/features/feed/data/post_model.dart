import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String uid;
  final String username;
  final String userImageUrl;
  final DateTime createdAt;
  final String content;
  final String? postImageUrl;
  final List<String> likes;
  final int commentCount;

  PostModel({
    required this.id,
    required this.uid,
    required this.username,
    required this.userImageUrl,
    required this.createdAt,
    required this.content,
    this.postImageUrl,
    required this.likes,
    required this.commentCount,
  });

  // --- COMPATIBILITY GETTERS ---
  // These allow your HomeScreen and PostCard to work without changing their code
  String get userName => username;
  String get userProfile => userImageUrl;
  String get description => content;
  String get imageUrl => postImageUrl ?? "";
  int get commentsCount => commentCount;

  factory PostModel.fromMap(Map<String, dynamic> map, String documentId) {
    DateTime date;
    if (map['createdAt'] != null && map['createdAt'] is Timestamp) {
      date = (map['createdAt'] as Timestamp).toDate();
    } else {
      date = DateTime.now();
    }

    return PostModel(
      id: documentId,
      uid: map['uid'] ?? '',
      // Handling both naming conventions in case Firestore has mixed data
      username: map['username'] ?? map['userName'] ?? 'Anonymous',
      userImageUrl: map['userImageUrl'] ?? map['userProfile'] ?? 'https://i.pravatar.cc/150',
      createdAt: date,
      content: map['content'] ?? map['description'] ?? '',
      postImageUrl: map['postImageUrl'] ?? map['imageUrl'],
      likes: List<String>.from(map['likes'] ?? []),
      commentCount: map['commentCount'] ?? map['commentsCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'userImageUrl': userImageUrl,
      'createdAt': createdAt,
      'content': content,
      'postImageUrl': postImageUrl,
      'likes': likes,
      'commentCount': commentCount,
    };
  }
}