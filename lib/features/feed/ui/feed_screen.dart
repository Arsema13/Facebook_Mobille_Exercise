import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart'; // Added for Share

import '../../feed/widgets/post_card.dart';
import '../../feed/data/post_model.dart';
import '../../feed/ui/create_post_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSearching = false;
  String _searchQuery = "";

  String _getSafeFullName(Map<String, dynamic>? data) {
    if (data == null) return "User";
    final fName = data['firstName']?.toString() ?? "";
    final lName = data['lastName']?.toString() ?? "";
    final name = "$fName $lName".trim();
    return name.isEmpty ? "User" : name;
  }

  // 1. MESSENGER PLAY STORE ICON LINK
  Future<void> _launchMessenger() async {
    final Uri url = Uri.parse("https://play.google.com/store/apps/details?id=com.facebook.orca");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _handleCreateStory(BuildContext context, Map<String, dynamic>? userData) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF1877F2))),
    );

    try {
      File file = File(image.path);
      String fileName = 'story/${DateTime.now().millisecondsSinceEpoch}.jpg';
      TaskSnapshot upload = await FirebaseStorage.instance.ref().child(fileName).putFile(file);
      String downloadUrl = await upload.ref.getDownloadURL();
      final user = FirebaseAuth.instance.currentUser;

      String fullName = _getSafeFullName(userData);

      await FirebaseFirestore.instance.collection('story').add({
        'userId': user?.uid ?? 'anonymous',
        'imageUrl': downloadUrl,
        'userName': fullName,
        'userProfile': userData?['profilePic']?.toString() ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        Map<String, dynamic>? userData;
        if (snapshot.hasData && snapshot.data!.exists) {
          userData = snapshot.data!.data() as Map<String, dynamic>;
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF0F2F5),
          body: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(child: WhatsOnYourMind(userData: userData)),
              const SliverToBoxAdapter(child: Divider(height: 8, thickness: 8, color: Color(0xFFCED0D4))),
              SliverToBoxAdapter(
                child: StoriesSection(
                  userData: userData,
                  onCreateStory: () => _handleCreateStory(context, userData),
                ),
              ),
              const SliverToBoxAdapter(child: Divider(height: 8, thickness: 8, color: Color(0xFFCED0D4))),
              PostFeedList(searchQuery: _searchQuery, userData: userData),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true, pinned: true,
      backgroundColor: Colors.white,
      elevation: 0.5,
      title: _isSearching
          ? TextField(
        autofocus: true,
        decoration: const InputDecoration(hintText: "Search posts...", border: InputBorder.none),
        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
      )
          : const Text('facebook', style: TextStyle(color: Color(0xFF1877F2), fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -1.2)),
      actions: [
        _circleIcon(_isSearching ? Icons.close : Icons.search, () {
          setState(() {
            _isSearching = !_isSearching;
            if (!_isSearching) _searchQuery = "";
          });
        }),
        _circleIcon(Icons.messenger, _launchMessenger), // Added Messenger Action
        _circleIcon(Icons.logout, () async {
          await FirebaseAuth.instance.signOut();
          if (mounted) Navigator.of(context).pushReplacementNamed('/login');
        }),
      ],
    );
  }

  Widget _circleIcon(IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      decoration: const BoxDecoration(color: Color(0xFFE4E6EB), shape: BoxShape.circle),
      child: IconButton(icon: Icon(icon, color: Colors.black, size: 20), onPressed: onTap),
    );
  }
}

class StoriesSection extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final VoidCallback onCreateStory;
  const StoriesSection({super.key, this.userData, required this.onCreateStory});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210, color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('story').snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.hasData ? snapshot.data!.docs : [];
          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: [
              GestureDetector(onTap: onCreateStory, child: _buildCreateStoryCard()),
              ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _buildStoryCard(
                  data['imageUrl']?.toString() ?? "",
                  data['userName']?.toString() ?? "User",
                  data['userProfile']?.toString() ?? "",
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCreateStoryCard() {
    final profilePic = userData?['profilePic']?.toString();
    return Container(
      width: 110, margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade300)),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                image: (profilePic != null && profilePic.isNotEmpty)
                    ? DecorationImage(image: NetworkImage(profilePic), fit: BoxFit.cover)
                    : null,
                color: Colors.grey.shade200,
              ),
              child: (profilePic == null || profilePic.isEmpty) ? const Icon(Icons.person, size: 40, color: Colors.white) : null,
            ),
          ),
          const Expanded(child: Center(child: Text("Create Story", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))),
        ],
      ),
    );
  }

  Widget _buildStoryCard(String bgImage, String name, String profileImage) {
    return Container(
      width: 110, margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        image: bgImage.isNotEmpty ? DecorationImage(image: NetworkImage(bgImage), fit: BoxFit.cover) : null,
        color: Colors.grey.shade300,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black26, Colors.transparent, Colors.black54]),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(radius: 16, backgroundImage: profileImage.isNotEmpty ? NetworkImage(profileImage) : null, child: profileImage.isEmpty ? const Icon(Icons.person, size: 16) : null),
            Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class PostFeedList extends StatelessWidget {
  final String searchQuery;
  final Map<String, dynamic>? userData;
  const PostFeedList({super.key, required this.searchQuery, this.userData});

  // 2. LIKE LOGIC FOR ALL POSTS
  Future<void> _handleLike(String postId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);
    final doc = await postRef.get();
    if (doc.exists) {
      List<dynamic> likes = doc.data()?['likes'] ?? [];
      if (likes.contains(user.uid)) {
        await postRef.update({'likes': FieldValue.arrayRemove([user.uid])});
      } else {
        await postRef.update({'likes': FieldValue.arrayUnion([user.uid])});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('posts').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));

        final docs = snapshot.data?.docs ?? [];
        final filteredDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final desc = (data['description']?.toString() ?? data['content']?.toString() ?? "").toLowerCase();
          final name = (data['userName']?.toString() ?? data['username']?.toString() ?? "").toLowerCase();
          return desc.contains(searchQuery) || name.contains(searchQuery);
        }).toList();

        return SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              final doc = filteredDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              final post = PostModel.fromMap(data, doc.id);

              String currentName = "User";
              String currentProfile = "";
              if (userData != null) {
                currentName = "${userData!['firstName'] ?? ''} ${userData!['lastName'] ?? ''}".trim();
                currentProfile = userData!['profilePic']?.toString() ?? "";
              }

              return PostCard(
                post: post,
                onLikeTap: () => _handleLike(post.id),
                onCommentTap: () => _showComments(context, post.id, currentName, currentProfile),
                onShareTap: () => Share.share("Check out this post: ${post.description}"), // Enabled Share
              );
            },
            childCount: filteredDocs.length,
          ),
        );
      },
    );
  }

  void _showComments(BuildContext context, String postId, String name, String profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsSheet(postId: postId, currentUserName: name, currentUserProfile: profile),
    );
  }
}

class WhatsOnYourMind extends StatelessWidget {
  final Map<String, dynamic>? userData;
  const WhatsOnYourMind({super.key, this.userData});

  @override
  Widget build(BuildContext context) {
    String firstName = userData?['firstName']?.toString() ?? "";
    String? profilePic = userData?['profilePic']?.toString();

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePostScreen())),
      child: Container(
        color: Colors.white, padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: (profilePic != null && profilePic.isNotEmpty) ? NetworkImage(profilePic) : null,
              child: (profilePic == null || profilePic.isEmpty) ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE4E6EB)), borderRadius: BorderRadius.circular(25)),
                child: Text(firstName.isEmpty ? "What's on your mind?" : "What's on your mind, $firstName?"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 3. UPDATED STANDARD COMMENTS SHEET
class CommentsSheet extends StatefulWidget {
  final String postId;
  final String currentUserName;
  final String currentUserProfile;
  const CommentsSheet({super.key, required this.postId, required this.currentUserName, required this.currentUserProfile});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();

  void _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;
    String text = _commentController.text.trim();
    _commentController.clear();

    await FirebaseFirestore.instance.collection('posts').doc(widget.postId).collection('comments').add({
      'userName': widget.currentUserName,
      'userProfile': widget.currentUserProfile,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection('posts').doc(widget.postId).update({
      'commentCount': FieldValue.increment(1),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
          const Padding(padding: EdgeInsets.all(16), child: Text("Comments", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('posts').doc(widget.postId).collection('comments').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundImage: data['userProfile'] != null && data['userProfile'].isNotEmpty ? NetworkImage(data['userProfile']) : null,
                        child: data['userProfile'] == null || data['userProfile'].isEmpty ? const Icon(Icons.person) : null,
                      ),
                      title: Text(data['userName']?.toString() ?? "User", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text(data['text']?.toString() ?? ""),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                    child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: "Write a comment...",
                          filled: true,
                          fillColor: const Color(0xFFF0F2F5),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                        )
                    )
                ),
                IconButton(onPressed: _submitComment, icon: const Icon(Icons.send, color: Color(0xFF1877F2))),
              ],
            ),
          )
        ],
      ),
    );
  }
}