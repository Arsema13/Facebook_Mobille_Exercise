import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
  bool _showJoinedOnly = false;
  bool _isSearching = false;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  // --- LOGIC: Create Group ---
  Future<void> _showCreateGroupDialog() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20, right: 20, top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            const Text("Create Group", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: "Group Name", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: descController,
              decoration: InputDecoration(labelText: "Description", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1877F2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) return;

                  // Create the Group Document
                  final docRef = await FirebaseFirestore.instance.collection('groups').add({
                    'name': nameController.text.trim(),
                    'description': descController.text.trim(),
                    'imageUrl': 'https://picsum.photos/seed/${nameController.text.trim()}/600/400',
                    'memberCount': 1,
                    'creatorId': currentUserId,
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                  // Add the creator as the first member
                  await FirebaseFirestore.instance
                      .collection('groups')
                      .doc(docRef.id)
                      .collection('members')
                      .doc(currentUserId)
                      .set({
                    'userId': currentUserId,
                    'joinedAt': FieldValue.serverTimestamp(),
                  });

                  if (mounted) Navigator.pop(context);
                },
                child: const Text("Create Group", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- LOGIC: JOIN/LEAVE (Targeted) ---
  Future<void> _toggleGroupJoin(String groupId, String groupName, bool currentlyJoined) async {
    // We use the specific group reference to ensure we only touch ONE group
    final groupRef = FirebaseFirestore.instance.collection('groups').doc(groupId);
    final memberRef = groupRef.collection('members').doc(currentUserId);

    try {
      if (currentlyJoined) {
        await memberRef.delete();
        await groupRef.update({'memberCount': FieldValue.increment(-1)});
        _showToast("Left $groupName");
      } else {
        await memberRef.set({
          'userId': currentUserId,
          'joinedAt': FieldValue.serverTimestamp(),
        });
        await groupRef.update({'memberCount': FieldValue.increment(1)});
        _showToast("Joined $groupName!");
      }
    } catch (e) {
      _showToast("Connection error. Try again.");
    }
  }

  void _showToast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 1), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          _buildFilterBar(),
          _buildGroupsGrid(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true, pinned: true,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      title: _isSearching
          ? TextField(
        controller: _searchController,
        autofocus: true,
        decoration: const InputDecoration(hintText: "Search groups...", border: InputBorder.none),
        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
      )
          : const Text('Groups', style: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
      actions: [
        _circleActionIcon(Icons.add_box_rounded, _showCreateGroupDialog),
        _circleActionIcon(_isSearching ? Icons.close : Icons.search, () {
          setState(() {
            _isSearching = !_isSearching;
            if (!_isSearching) { _searchQuery = ""; _searchController.clear(); }
          });
        }),
      ],
    );
  }

  Widget _buildFilterBar() {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            _filterChip('Discover', isSelected: !_showJoinedOnly, onTap: () => setState(() => _showJoinedOnly = false)),
            const SizedBox(width: 8),
            _filterChip('Your groups', isSelected: _showJoinedOnly, onTap: () => setState(() => _showJoinedOnly = true)),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('groups').snapshots(),
      builder: (context, groupsSnapshot) {
        if (!groupsSnapshot.hasData) return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));

        return StreamBuilder<QuerySnapshot>(
          // Specifically only watch member docs belonging to this user
          stream: FirebaseFirestore.instance.collectionGroup('members').where('userId', isEqualTo: currentUserId).snapshots(),
          builder: (context, memberSnapshot) {

            // MAP JOINED IDS: We extract exactly which group IDs this user belongs to
            final Set<String> joinedGroupIds = {};
            if (memberSnapshot.hasData) {
              for (var doc in memberSnapshot.data!.docs) {
                // IMPORTANT: Use the parent document ID to avoid mixups
                final groupId = doc.reference.parent.parent?.id;
                if (groupId != null) joinedGroupIds.add(groupId);
              }
            }

            final filteredGroups = groupsSnapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = (data['name'] ?? "").toString().toLowerCase();
              final matchesSearch = name.contains(_searchQuery);
              final isJoined = joinedGroupIds.contains(doc.id);

              return _showJoinedOnly ? (matchesSearch && isJoined) : matchesSearch;
            }).toList();

            if (filteredGroups.isEmpty) {
              return const SliverFillRemaining(child: Center(child: Text("No groups to show")));
            }

            return SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final doc = filteredGroups[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final groupId = doc.id;
                    final isJoined = joinedGroupIds.contains(groupId);

                    // KEY: The ValueKey ensures that Group A's card is NEVER confused with Group B's card
                    return _buildGroupCard(groupId, data, isJoined);
                  },
                  childCount: filteredGroups.length,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGroupCard(String groupId, Map<String, dynamic> data, bool isJoined) {
    return Container(
      key: ValueKey('card_$groupId'), // Unique ID for each card
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                data['imageUrl'] ?? "https://picsum.photos/200",
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (c, e, s) => Container(color: Colors.grey[200]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['name'] ?? "New Group", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('${data['memberCount'] ?? 0} members', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _toggleGroupJoin(groupId, data['name'] ?? "", isJoined),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isJoined ? Colors.grey[200] : const Color(0xFF1877F2),
                      foregroundColor: isJoined ? Colors.black87 : Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(isJoined ? 'Joined' : 'Join', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, {required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE7F3FF) : const Color(0xFFE4E6EB),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? const Color(0xFF1877F2) : Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _circleActionIcon(IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      decoration: const BoxDecoration(color: Color(0xFFE4E6EB), shape: BoxShape.circle),
      child: IconButton(icon: Icon(icon, color: Colors.black, size: 20), onPressed: onTap),
    );
  }
}