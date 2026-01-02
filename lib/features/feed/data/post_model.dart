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

  // --------------------------------------------------
  // COMPATIBILITY GETTERS (DO NOT REMOVE)
  // --------------------------------------------------
  String get userName => username;
  String get userProfile => userImageUrl;
  String get description => content;
  String get imageUrl => postImageUrl ?? "";
  int get commentsCount => commentCount;

  // --------------------------------------------------
  // FROM FIRESTORE (FIXED FOR TYPE SAFETY)
  // --------------------------------------------------
  factory PostModel.fromMap(Map<String, dynamic> map, String documentId) {
    // 1. Safety for createdAt
    DateTime created;
    if (map['createdAt'] is Timestamp) {
      created = (map['createdAt'] as Timestamp).toDate();
    } else {
      created = DateTime.now();
    }

    // 2. Safety for likes list (Common source of subtype errors)
    List<String> likesList = [];
    if (map['likes'] is List) {
      likesList = (map['likes'] as List)
          .map((item) => item.toString()) // Forces everything in list to String
          .toList();
    }

    // 3. Safety for commentCount (Ensure it's always an int)
    int count = 0;
    var rawCount = map['commentCount'] ?? map['commentsCount'];
    if (rawCount is num) {
      count = rawCount.toInt();
    } else if (rawCount is String) {
      count = int.tryParse(rawCount) ?? 0;
    }

    return PostModel(
      id: documentId,
      // .toString() forces numbers like 123 into "123" to satisfy String type
      uid: map['uid']?.toString() ?? '',

      username: (map['username'] ?? map['userName'] ?? 'Anonymous').toString(),

      userImageUrl: (map['userImageUrl'] ?? map['userProfile'] ?? '').toString(),

      createdAt: created,

      content: (map['content'] ?? map['description'] ?? '').toString(),

      postImageUrl: map['postImageUrl']?.toString() ?? map['imageUrl']?.toString(),

      likes: likesList,

      commentCount: count,
    );
  }

  // --------------------------------------------------
  // TO FIRESTORE
  // --------------------------------------------------
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'userImageUrl': userImageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'content': content,
      'postImageUrl': postImageUrl,
      'likes': likes,
      'commentCount': commentCount,
    };
  }
}