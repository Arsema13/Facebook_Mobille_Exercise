import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

// Your existing imports
import '../../feed/widgets/post_card.dart';
import '../../../services/firebase/firestore_service.dart';
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

  @override
  void initState() {
    super.initState();
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
      String fileName = 'stories/${DateTime.now().millisecondsSinceEpoch}.jpg';
      TaskSnapshot upload = await FirebaseStorage.instance.ref().child(fileName).putFile(file);
      String downloadUrl = await upload.ref.getDownloadURL();
      final user = FirebaseAuth.instance.currentUser;
      String fullName = userData != null ? "${userData['firstName']} ${userData['lastName']}" : "User";

      await FirebaseFirestore.instance.collection('stories').add({
        'userId': user?.uid ?? 'anonymous',
        'imageUrl': downloadUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'userName': fullName,
        'userProfile': user?.photoURL ?? '',
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _launchMessenger() async {
    final Uri url = Uri.parse("https://play.google.com/store/apps/details?id=com.facebook.orca");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
      builder: (context, snapshot) {
        Map<String, dynamic>? userData;
        if (snapshot.hasData && snapshot.data!.exists) {
          userData = snapshot.data!.data() as Map<String, dynamic>;
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF0F2F5),
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                pinned: true,
                backgroundColor: Colors.white,
                elevation: 0.5,
                title: _isSearching
                    ? TextField(
                  autofocus: true,
                  decoration: const InputDecoration(hintText: "Search posts...", border: InputBorder.none),
                  onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                )
                    : const Text('facebook', style: TextStyle(color: Color(0xFF1877F2), fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -1.2)),
                actions: [
                  _circleIcon(_isSearching ? Icons.close : Icons.search, () {
                    setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) _searchQuery = "";
                    });
                  }),
                  _circleIcon(Icons.messenger, _launchMessenger),
                  _circleIcon(Icons.logout, () async {
                    await FirebaseAuth.instance.signOut();
                    if (mounted) Navigator.of(context).pushReplacementNamed('/login');
                  }),
                ],
              ),
              SliverToBoxAdapter(child: WhatsOnYourMind(userData: userData)),
              const SliverToBoxAdapter(child: Divider(height: 8, thickness: 8, color: Color(0xFFCED0D4))),
              SliverToBoxAdapter(
                child: StoriesSection(
                  userData: userData,
                  onCreateStory: () => _handleCreateStory(context, userData),
                ),
              ),
              const SliverToBoxAdapter(child: Divider(height: 8, thickness: 8, color: Color(0xFFCED0D4))),
              SliverPadding(
                padding: const EdgeInsets.only(top: 0),
                sliver: PostFeedList(searchQuery: _searchQuery, userData: userData),
              ),
            ],
          ),
        );
      },
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
      height: 210,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('stories').orderBy('createdAt', descending: true).limit(10).snapshots(),
        builder: (context, snapshot) {
          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: [
              GestureDetector(onTap: onCreateStory, child: _buildCreateStoryCard()),
              if (snapshot.hasData)
                ...snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildStoryCard(data['imageUrl'], data['userName'] ?? "User", data['userProfile'] ?? "");
                }),
              // RESTORED 5 MOCK STORIES
              _buildStoryCard("https://picsum.photos/400/700?random=1", "Abebe Degu", "https://i.pravatar.cc/150?u=1"),
              _buildStoryCard("https://picsum.photos/400/700?random=2", "Alex Dagne", "https://i.pravatar.cc/150?u=2"),
              _buildStoryCard("https://picsum.photos/400/700?random=3", "Marta Kebede", "https://i.pravatar.cc/150?u=3"),
              _buildStoryCard("https://picsum.photos/400/700?random=4", "Samuel Girma", "https://i.pravatar.cc/150?u=4"),
              _buildStoryCard("https://picsum.photos/400/700?random=5", "Bethlehem T.", "https://i.pravatar.cc/150?u=5"),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCreateStoryCard() {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade300)),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                image: userData?['profilePic'] != null ? DecorationImage(image: NetworkImage(userData!['profilePic']), fit: BoxFit.cover) : null,
                color: Colors.grey.shade200,
              ),
              child: userData?['profilePic'] == null ? const Icon(Icons.person, size: 40, color: Colors.white) : null,
            ),
          ),
          const Expanded(child: Center(child: Text("Create Story", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))),
        ],
      ),
    );
  }

  Widget _buildStoryCard(String bgImage, String name, String profileImage) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), image: DecorationImage(image: NetworkImage(bgImage), fit: BoxFit.cover)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.2), Colors.transparent, Colors.black.withOpacity(0.6)]),
        ),
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(radius: 16, backgroundImage: NetworkImage(profileImage.isNotEmpty ? profileImage : "https://i.pravatar.cc/150")),
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

  @override
  Widget build(BuildContext context) {
    // RESTORED 10 MOCK POSTS
    final List<Map<String, dynamic>> staticMockPosts = [
      {'id': 'm1', 'userName': 'Abebe Degu', 'userProfile': 'https://i.pravatar.cc/150?u=1', 'description': 'Sunset vibes! 🌅 #nature', 'imageUrl': 'https://picsum.photos/id/10/800/600', 'likes': [], 'commentsCount': 5},
      {'id': 'm2', 'userName': 'Sarah Smith', 'userProfile': 'https://i.pravatar.cc/150?u=2', 'description': 'Flutter is awesome! 🚀', 'imageUrl': 'https://picsum.photos/id/1/800/600', 'likes': [], 'commentsCount': 12},
      {'id': 'm3', 'userName': 'Michael welde', 'userProfile': 'https://i.pravatar.cc/150?u=3', 'description': 'Best brunch ever 🥞☕', 'imageUrl': 'https://picsum.photos/id/42/800/600', 'likes': [], 'commentsCount': 2},
      {'id': 'm4', 'userName': 'Tasew bonja', 'userProfile': 'https://i.pravatar.cc/150?u=4', 'description': 'Missing the mountains 🏔️', 'imageUrl': 'https://picsum.photos/id/29/800/600', 'likes': [], 'commentsCount': 8},
      {'id': 'm5', 'userName': 'Tigist kasa', 'userProfile': 'https://i.pravatar.cc/150?u=5', 'description': 'New AI model released!', 'imageUrl': 'https://picsum.photos/id/180/800/600', 'likes': [], 'commentsCount': 15},
      {'id': 'm6', 'userName': 'Marta Kebede', 'userProfile': 'https://i.pravatar.cc/150?u=6', 'description': 'Monday motivation! ☕', 'imageUrl': 'https://picsum.photos/id/63/800/600', 'likes': [], 'commentsCount': 3},
      {'id': 'm7', 'userName': 'Samuel Girma', 'userProfile': 'https://i.pravatar.cc/150?u=7', 'description': 'Rich culture 🏛️🇪🇹', 'imageUrl': 'https://picsum.photos/id/101/800/600', 'likes': [], 'commentsCount': 7},
      {'id': 'm8', 'userName': 'Fitness Junkie', 'userProfile': 'https://i.pravatar.cc/150?u=8', 'description': '10km run done! 🏃‍♂️', 'imageUrl': 'https://picsum.photos/id/108/800/600', 'likes': [], 'commentsCount': 9},
      {'id': 'm9', 'userName': 'Art Lover', 'userProfile': 'https://i.pravatar.cc/150?u=9', 'description': 'Breathtaking abstract art 🎨', 'imageUrl': 'https://picsum.photos/id/152/800/600', 'likes': [], 'commentsCount': 11},
      {'id': 'm10', 'userName': 'Chef Alex', 'userProfile': 'https://i.pravatar.cc/150?u=10', 'description': 'Pasta from scratch! 🍝', 'imageUrl': 'https://picsum.photos/id/163/800/600', 'likes': [], 'commentsCount': 20},
    ];

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('posts').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        List<PostModel> allPosts = [];

        // Add Mock Posts first
        allPosts.addAll(staticMockPosts.map((data) => PostModel.fromMap(data, data['id'])));

        // Add Firestore Posts
        if (snapshot.hasData) {
          allPosts.addAll(snapshot.data!.docs.map((doc) => PostModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)));
        }

        final filteredPosts = allPosts.where((post) {
          final desc = (post.description ?? "").toLowerCase();
          final name = (post.userName ?? "").toLowerCase();
          return desc.contains(searchQuery) || name.contains(searchQuery);
        }).toList();

        return SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              final post = filteredPosts[index];
              final currentName = userData != null ? "${userData!['firstName']} ${userData!['lastName']}" : "User";

              return PostCard(
                post: post,
                onCommentTap: () => _showComments(context, post.id, currentName),
                onShareTap: () => Share.share("Check out ${post.userName}'s post: ${post.description}"),
              );
            },
            childCount: filteredPosts.length,
          ),
        );
      },
    );
  }

  void _showComments(BuildContext context, String postId, String name) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsSheet(postId: postId, currentUserName: name),
    );
  }
}

class CommentsSheet extends StatefulWidget {
  final String postId;
  final String currentUserName;
  const CommentsSheet({super.key, required this.postId, required this.currentUserName});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();

  void _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;
    String text = _commentController.text.trim();
    _commentController.clear();

    // Note: Mock posts (m1-m10) won't save comments to Firebase unless they exist in the DB
    await FirebaseFirestore.instance.collection('posts').doc(widget.postId).collection('comments').add({
      'userName': widget.currentUserName,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection('posts').doc(widget.postId).update({
      'commentsCount': FieldValue.increment(1),
    }).catchError((e) => debugPrint("Mock post comment count not updated in DB"));
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
          const Padding(padding: EdgeInsets.all(16), child: Text("Comments", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('posts').doc(widget.postId).collection('comments').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      leading: const CircleAvatar(radius: 18, child: Icon(Icons.person, size: 20)),
                      title: Text(data['userName'] ?? "User", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text(data['text'] ?? ""),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                IconButton(onPressed: _submitComment, icon: const Icon(Icons.send, color: Color(0xFF1877F2))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WhatsOnYourMind extends StatelessWidget {
  final Map<String, dynamic>? userData;
  const WhatsOnYourMind({super.key, this.userData});

  @override
  Widget build(BuildContext context) {
    String firstName = userData != null ? userData!['firstName'] : "";
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePostScreen())),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            const CircleAvatar(radius: 20, backgroundColor: Color(0xFF8D949E), child: Icon(Icons.person, color: Colors.white)),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE4E6EB)), borderRadius: BorderRadius.circular(25)),
                child: Text(firstName.isEmpty ? "What's on your mind?" : "What's on your mind, $firstName?", style: const TextStyle(fontSize: 15, color: Colors.black87)),
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.photo_library, color: Color(0xFF45BD62)),
          ],
        ),
      ),
    );
  }
}