import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/post_model.dart';
import '../../../services/firebase/firestore_service.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onCommentTap; // New Callback
  final VoidCallback onShareTap;   // New Callback

  const PostCard({
    super.key,
    required this.post,
    required this.onCommentTap,
    required this.onShareTap,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Get current user safely
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String currentUserId = currentUser?.uid ?? "";

    // 2. Determine if liked (Checks the List<String> of UIDs)
    final bool isLiked = post.likes.contains(currentUserId);

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // HEADER SECTION
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: NetworkImage(post.userProfile ?? "https://i.pravatar.cc/150"),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            post.userName ?? "User",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text("•", style: TextStyle(color: Colors.grey)),
                          const SizedBox(width: 8),
                          const Text(
                            "Follow",
                            style: TextStyle(
                                color: Color(0xFF1877F2),
                                fontWeight: FontWeight.bold
                            ),
                          ),
                        ],
                      ),
                      const Row(
                        children: [
                          Text(
                              "Recommended post • ",
                              style: TextStyle(color: Colors.grey, fontSize: 12)
                          ),
                          Text(
                            "Just now", // Replace with real logic if createdAt exists
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.public, size: 12, color: Colors.grey),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.more_horiz, color: Colors.grey),
                const SizedBox(width: 15),
                const Icon(Icons.close, color: Colors.grey),
              ],
            ),
          ),

          // CONTENT TEXT
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            child: Text(
                post.description ?? "",
                style: const TextStyle(fontSize: 15, color: Colors.black)
            ),
          ),

          // POST IMAGE
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Image.network(
                post.imageUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.grey[100],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),

          // STATS ROW (LIKES & COMMENTS)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                      color: Color(0xFF1877F2),
                      shape: BoxShape.circle
                  ),
                  child: const Icon(Icons.thumb_up, size: 10, color: Colors.white),
                ),
                const SizedBox(width: 6),
                Text(
                    "${post.likes.length}",
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)
                ),
                const Spacer(),
                Text(
                    "${post.commentsCount} comments",
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)
                ),
              ],
            ),
          ),

          const Divider(height: 1, indent: 12, endIndent: 12),

          // ACTION BUTTONS ROW
          _buildReactionRow(isLiked, post.id, currentUserId),
        ],
      ),
    );
  }

  Widget _buildReactionRow(bool isLiked, String postId, String currentUid) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _actionButton(
          icon: isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
          label: "Like",
          color: isLiked ? const Color(0xFF1877F2) : Colors.grey[600]!,
          onTap: () {
            if (currentUid.isNotEmpty) {
              FirestoreService().toggleLike(postId, currentUid);
            }
          },
        ),
        _actionButton(
          icon: Icons.mode_comment_outlined,
          label: "Comment",
          color: Colors.grey[600]!,
          onTap: onCommentTap, // Triggers the BottomSheet in HomeScreen
        ),
        _actionButton(
          icon: Icons.share_outlined,
          label: "Share",
          color: Colors.grey[600]!,
          onTap: onShareTap, // Triggers Share Dialog in HomeScreen
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                  label,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 14
                  )
              ),
            ],
          ),
        ),
      ),
    );
  }
}