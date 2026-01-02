import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/post_model.dart';
// Note: We removed the FirestoreService import here because we are
// now handling the Like logic via the callback from HomeScreen

class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onLikeTap;    // Added this line
  final VoidCallback onCommentTap;
  final VoidCallback onShareTap;

  const PostCard({
    super.key,
    required this.post,
    required this.onLikeTap,      // Added this line
    required this.onCommentTap,
    required this.onShareTap,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
    // Check if the current user's ID exists in the post's likes list
    final bool isLiked = post.likes.contains(currentUserId);

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(),
          _contentText(),
          if (post.imageUrl.isNotEmpty) _postImage(),
          _stats(),
          const Divider(height: 1, indent: 12, endIndent: 12),
          _reactionRow(isLiked),
        ],
      ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[300],
            backgroundImage:
            post.userProfile.isNotEmpty ? NetworkImage(post.userProfile) : null,
            child: post.userProfile.isEmpty
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        post.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text("•", style: TextStyle(color: Colors.grey)),
                    const SizedBox(width: 6),
                    const Text(
                      "Follow",
                      style: TextStyle(
                        color: Color(0xFF1877F2),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Row(
                  children: [
                    Text(
                      "Recommended post • Just now",
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
          const SizedBox(width: 12),
          const Icon(Icons.close, color: Colors.grey),
        ],
      ),
    );
  }

  // ---------------- TEXT ----------------
  Widget _contentText() {
    if (post.description.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(
        post.description,
        style: const TextStyle(fontSize: 15),
      ),
    );
  }

  // ---------------- IMAGE ----------------
  Widget _postImage() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Image.network(
        post.imageUrl,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 220,
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, size: 40),
        ),
      ),
    );
  }

  // ---------------- STATS ----------------
  Widget _stats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Color(0xFF1877F2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.thumb_up, size: 10, color: Colors.white),
          ),
          const SizedBox(width: 6),
          Text(
            "${post.likes.length}",
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const Spacer(),
          Text(
            "${post.commentsCount} comments",
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ---------------- REACTIONS ----------------
  Widget _reactionRow(bool isLiked) {
    return Row(
      children: [
        _actionButton(
          icon: isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
          label: "Like",
          color: isLiked ? const Color(0xFF1877F2) : Colors.grey[600]!,
          onTap: onLikeTap, // Updated to use the callback
        ),
        _actionButton(
          icon: Icons.mode_comment_outlined,
          label: "Comment",
          color: Colors.grey[600]!,
          onTap: onCommentTap,
        ),
        _actionButton(
          icon: Icons.share_outlined,
          label: "Share",
          color: Colors.grey[600]!,
          onTap: onShareTap,
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}