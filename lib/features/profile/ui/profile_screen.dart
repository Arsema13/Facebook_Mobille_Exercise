import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  // --- LOGIC: Save Local Path to Firestore ---
  Future<void> _updateImageLocal(bool isProfile) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      await FirebaseFirestore.instance.collection('users').doc(currentUserId).set({
        isProfile ? 'photoUrl' : 'coverUrl': image.path,
      }, SetOptions(merge: true));

      _showToast("Image updated locally");
    } catch (e) {
      _showToast("Error selecting image: $e");
    }
  }

  // --- LOGIC: Add to Story ---
  Future<void> _addToStory() async {
    final XFile? storyImage = await _picker.pickImage(source: ImageSource.gallery);
    if (storyImage != null) {
      _showToast("Story image selected!");
    }
  }

  // --- LOGIC: Edit Bio Dialog ---
  void _showEditBioDialog(String currentBio) {
    TextEditingController bioController = TextEditingController(text: currentBio);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Bio"),
        content: TextField(
            controller: bioController,
            maxLength: 100,
            decoration: const InputDecoration(hintText: "Describe yourself...")
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(currentUserId).set({
                'bio': bioController.text
              }, SetOptions(merge: true));
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showToast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    const Color fbBlue = Color(0xFF1877F2);
    const Color lightGrey = Color(0xFFE4E6EB);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUserId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        var userData = snapshot.data?.data() as Map<String, dynamic>?;

        // Fetch name from Firestore -> Fallback to Auth -> Fallback to "User"
        String name = userData?['displayName'] ??
            FirebaseAuth.instance.currentUser?.displayName ??
            "User";

        String? profilePath = userData?['photoUrl'];
        String? coverPath = userData?['coverUrl'];
        String bioText = userData?['bio'] ?? "Edit bio to tell people about yourself";

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            centerTitle: false,
            // Search icon removed from here
            title: Text(
                name,
                style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)
            ),
            iconTheme: const IconThemeData(color: Colors.black),
          ),
          body: NestedScrollView(
            headerSliverBuilder: (context, innerScrolled) => [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildHeader(profilePath, coverPath),
                    const SizedBox(height: 60),
                    _buildProfileInfo(name, bioText),
                    _buildActionButtons(fbBlue, lightGrey, bioText),
                    const Divider(thickness: 6, color: Color(0xFFF0F2F5)),
                  ],
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabDelegate(
                  TabBar(
                    controller: _tabController,
                    indicatorColor: fbBlue,
                    labelColor: fbBlue,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [Tab(text: "Posts"), Tab(text: "Photos"), Tab(text: "Reels")],
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildTabContent("No posts yet"),
                _buildTabContent("No photos yet"),
                _buildTabContent("No reels yet"),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(String? profilePath, String? coverPath) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Cover Photo
        GestureDetector(
          onTap: () => _updateImageLocal(false),
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              image: (coverPath != null && File(coverPath).existsSync())
                  ? DecorationImage(image: FileImage(File(coverPath)), fit: BoxFit.cover)
                  : null,
            ),
            child: (coverPath == null || !File(coverPath).existsSync())
                ? const Icon(Icons.camera_alt, color: Colors.grey)
                : null,
          ),
        ),
        // Profile Photo
        Positioned(
          bottom: -50,
          left: 16,
          child: GestureDetector(
            onTap: () => _updateImageLocal(true),
            child: CircleAvatar(
              radius: 84,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 80,
                backgroundColor: Colors.grey[300],
                backgroundImage: (profilePath != null && File(profilePath).existsSync())
                    ? FileImage(File(profilePath))
                    : null,
                child: (profilePath == null || !File(profilePath).existsSync())
                    ? const Icon(Icons.person, size: 80, color: Colors.white)
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfo(String name, String bio) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(bio, style: const TextStyle(fontSize: 16, color: Colors.black87)),
          const SizedBox(height: 20),
          _detailRow(Icons.home, "Lives in Addis Ababa"),
          _detailRow(Icons.access_time, "Joined the Community"),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 22),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Color blue, Color grey, String currentBio) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // ADD STORY BUTTON
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _addToStory,
              icon: const Icon(Icons.add_circle, color: Colors.white, size: 20),
              label: const Text("Add to Story", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: blue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
              ),
            ),
          ),
          const SizedBox(width: 8),
          // EDIT BUTTON
          IconButton(
            onPressed: () => _showEditBioDialog(currentBio),
            icon: const Icon(Icons.edit, size: 20),
            style: IconButton.styleFrom(
                backgroundColor: grey,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
            ),
          ),
          // Three dots button removed from here
        ],
      ),
    );
  }

  Widget _buildTabContent(String msg) {
    return Center(child: Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 16)));
  }
}

class _SliverTabDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _SliverTabDelegate(this.tabBar);
  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  Widget build(context, shrink, overlaps) => Container(color: Colors.white, child: tabBar);
  @override
  bool shouldRebuild(_SliverTabDelegate old) => false;
}