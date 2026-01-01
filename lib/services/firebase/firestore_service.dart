import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- USER DATA METHODS ---

  /// 1. Save or Update User Profile Data
  Future<void> saveUserData({
    required String uid,
    required String name,
    required String email,
    required String phone,
    String? profilePic,
  }) async {
    try {
      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'profilePic': profilePic ?? 'https://via.placeholder.com/150',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print("Firestore Save User Error: $e");
      rethrow;
    }
  }

  /// 2. Get User Data once
  Future<DocumentSnapshot> getUserData(String uid) async {
    try {
      return await _db.collection('users').doc(uid).get();
    } catch (e) {
      print("Firestore Fetch User Error: $e");
      rethrow;
    }
  }

  /// 3. Stream User Data (Real-time updates for Profile)
  Stream<DocumentSnapshot> streamUserData(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  // --- POST METHODS ---

  /// 4. Create a Post (Matched to your "New Post" UI)
  /// This will save the post globally so it appears for everyone.
  Future<void> createPost({
    required String content,
    String? imageUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User must be logged in to post.");

      // Fetch the latest profile data (e.g., "Li Te")
      final userDoc = await getUserData(user.uid);
      final userData = userDoc.data() as Map<String, dynamic>?;

      await _db.collection('posts').add({
        'uid': user.uid,
        'username': userData?['name'] ?? user.displayName ?? "Anonymous",
        'userImageUrl': userData?['profilePic'] ?? user.photoURL ?? 'https://via.placeholder.com/150',
        'content': content,
        'postImageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(), // Ensures correct sorting in feed
        'likes': [],
        'commentCount': 0,
      });
    } catch (e) {
      print("Firestore Create Post Error: $e");
      rethrow;
    }
  }

  /// 5. Get Global Posts Stream
  /// This returns posts from EVERYONE in the world.
  Stream<QuerySnapshot> getPostsStream() {
    return _db.collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  // --- INTERACTION METHODS ---

  /// 6. Like/Unlike a Post
  Future<void> toggleLike(String postId, String currentUid) async {
    try {
      DocumentReference postRef = _db.collection('posts').doc(postId);
      DocumentSnapshot postSnap = await postRef.get();

      if (!postSnap.exists) return;

      List likes = List<String>.from(postSnap.get('likes') ?? []);

      if (likes.contains(currentUid)) {
        await postRef.update({
          'likes': FieldValue.arrayRemove([currentUid])
        });
      } else {
        await postRef.update({
          'likes': FieldValue.arrayUnion([currentUid])
        });
      }
    } catch (e) {
      print("Firestore Toggle Like Error: $e");
    }
  }
}