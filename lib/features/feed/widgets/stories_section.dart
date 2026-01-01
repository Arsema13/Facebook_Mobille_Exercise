import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StoriesSection extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final VoidCallback onCreateStory;

  const StoriesSection({
    super.key,
    this.userData,
    required this.onCreateStory
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 230,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: StreamBuilder<QuerySnapshot>(
        // Fetch real stories from Firestore
        stream: FirebaseFirestore.instance
            .collection('stories')
            .orderBy('createdAt', descending: true)
            .limit(10)
            .snapshots(),
        builder: (context, snapshot) {
          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              // 1. Your custom Create Story Card
              GestureDetector(
                onTap: onCreateStory,
                child: _buildCreateStoryCard(),
              ),

              const SizedBox(width: 10),

              // 2. Real Stories from Firestore
              if (snapshot.hasData)
                ...snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildUserStoryCard(
                    data['imageUrl'] ?? "",
                    data['userName'] ?? "User",
                    data['userProfile'] ?? "",
                  );
                }),

              // 3. Your custom "Find Friends" Card
              _buildFindFriendsCard(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCreateStoryCard() {
    return Container(
      width: 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    image: (userData?['profilePic'] != null)
                        ? DecorationImage(
                      image: NetworkImage(userData!['profilePic']),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: userData?['profilePic'] == null
                      ? const Center(child: Icon(Icons.person, size: 50, color: Colors.grey))
                      : null,
                ),
                Positioned(
                  bottom: -15,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Container(
                      decoration: const BoxDecoration(color: Color(0xFF1877F2), shape: BoxShape.circle),
                      child: const Icon(Icons.add, color: Colors.white, size: 25),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Expanded(
            flex: 1,
            child: Padding(
              padding: EdgeInsets.only(top: 15),
              child: Text(
                "Create story",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // New Widget for actual stories
  Widget _buildUserStoryCard(String bgImage, String name, String profileImage) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        image: DecorationImage(
          image: NetworkImage(bgImage.isNotEmpty ? bgImage : "https://picsum.photos/200/300"),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.3), Colors.transparent, Colors.black.withOpacity(0.6)],
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF1877F2),
              child: CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(profileImage.isNotEmpty ? profileImage : "https://i.pravatar.cc/150"),
              ),
            ),
            Text(
              name,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFindFriendsCard() {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.video_call, color: Colors.grey),
              Icon(Icons.close, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 10),
          const Icon(Icons.people, size: 40, color: Colors.orangeAccent),
          const SizedBox(height: 8),
          const Text(
            "Facebook is better with friends",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const Text(
            "See stories from friends by adding people you know.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE7F3FF),
              elevation: 0,
              minimumSize: const Size(double.infinity, 36),
            ),
            child: const Text("Find friends", style: TextStyle(color: Color(0xFF1877F2))),
          ),
        ],
      ),
    );
  }
}