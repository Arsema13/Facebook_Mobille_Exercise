import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

  // Pointing exactly to your 'notification' collection
  final CollectionReference notificationsRef =
  FirebaseFirestore.instance.collection('notification');

  // --- LOGIC: Add Test Notification ---
  Future<void> _addTestNotification() async {
    if (currentUserId.isEmpty) return;
    try {
      await notificationsRef.add({
        'userId': currentUserId,
        'title': 'Sent you a friend request.',
        'type': 'friend',
        'isRead': false,
        'imageUrl': 'https://i.pravatar.cc/150?u=${DateTime.now().millisecond}',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error adding notification: $e");
    }
  }

  // --- LOGIC: Mark as Read ---
  Future<void> _markAsRead(String docId) async {
    await notificationsRef.doc(docId).update({'isRead': true});
  }

  // --- LOGIC: Delete ---
  Future<void> _deleteNotification(String docId) async {
    await notificationsRef.doc(docId).delete();
  }

  // --- LOGIC: Mark All as Read ---
  Future<void> _markAllRead() async {
    final snap = await notificationsRef
        .where('userId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    if (snap.docs.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    for (var doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: false,
        title: const Text(
          "Notifications",
          style: TextStyle(
              color: Colors.black,
              fontSize: 26,
              fontWeight: FontWeight.bold
          ),
        ),
        actions: [
          _circleIconButton(Icons.add, _addTestNotification),
          _circleIconButton(Icons.done_all, _markAllRead),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: notificationsRef
            .where('userId', isEqualTo: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return _buildEmptyState();

          // Client-side sorting (Newest first)
          final sortedDocs = docs.toList()
            ..sort((a, b) {
              Timestamp? t1 = (a.data() as Map<String, dynamic>)['createdAt'];
              Timestamp? t2 = (b.data() as Map<String, dynamic>)['createdAt'];
              if (t1 == null) return -1;
              if (t2 == null) return 1;
              return t2.compareTo(t1);
            });

          return ListView.builder(
            itemCount: sortedDocs.length,
            itemBuilder: (context, index) {
              final doc = sortedDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              return _buildFacebookTile(doc.id, data);
            },
          );
        },
      ),
    );
  }

  // --- UI: FACEBOOK STYLE NOTIFICATION TILE ---
  Widget _buildFacebookTile(String id, Map<String, dynamic> data) {
    final bool isRead = data['isRead'] ?? false;
    final String type = data['type'] ?? 'alert';

    return Slidable(
      key: ValueKey(id),
      endActionPane: ActionPane(
        extentRatio: 0.25,
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _deleteNotification(id),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Remove',
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _markAsRead(id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: isRead ? Colors.white : const Color(0xFFE7F3FF),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Picture + Icon Badge
              Stack(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: data['imageUrl'] != null
                        ? NetworkImage(data['imageUrl'])
                        : null,
                    child: data['imageUrl'] == null
                        ? const Icon(Icons.person, color: Colors.white, size: 30)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _getIconColor(type),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(_getIconData(type), color: Colors.white, size: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'] ?? "Notification",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black,
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTimestamp(data['createdAt']),
                      style: TextStyle(
                        color: isRead ? Colors.grey[600] : const Color(0xFF1877F2),
                        fontSize: 13,
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Indicators
              if (!isRead)
                const Icon(Icons.circle, color: Color(0xFF1877F2), size: 12),

              const SizedBox(width: 8),
              const Icon(Icons.more_horiz, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI HELPERS ---
  Widget _circleIconButton(IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle),
      child: IconButton(
        icon: Icon(icon, color: Colors.black, size: 22),
        onPressed: onTap,
        constraints: const BoxConstraints(),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "Just now";
    DateTime date = (timestamp as Timestamp).toDate();
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }

  IconData _getIconData(String type) {
    switch (type) {
      case 'friend': return Icons.person_add_alt_1;
      case 'group': return Icons.groups;
      case 'like': return Icons.thumb_up_sharp;
      default: return Icons.notifications;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'friend': return const Color(0xFF1877F2); // FB Blue
      case 'group': return const Color(0xFF42B72A); // FB Green
      case 'like': return const Color(0xFF1877F2);
      default: return Colors.redAccent;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 10),
          const Text("No new notifications", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}