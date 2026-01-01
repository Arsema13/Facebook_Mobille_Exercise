import 'package:flutter/material.dart';
import 'package:fast_contacts/fast_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- MAIN FRIENDS PAGE ---
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  List<Contact> _allContacts = [];
  List<Contact> _filteredContacts = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    PermissionStatus status = await Permission.contacts.request();
    if (status.isGranted) {
      final contacts = await FastContacts.getAllContacts();
      setState(() {
        _allContacts = contacts;
        _filteredContacts = contacts;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _filterSearch(String query) {
    setState(() {
      _filteredContacts = _allContacts
          .where((contact) =>
          contact.displayName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
              hintText: "Search friends...", border: InputBorder.none),
          onChanged: _filterSearch,
        )
            : const Text('Friends',
            style: TextStyle(
                color: Colors.black,
                fontSize: 26,
                fontWeight: FontWeight.bold)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle),
            child: IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.black, size: 22),
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _filteredContacts = _allContacts;
                    _searchController.clear();
                  }
                });
              },
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadContacts,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
          children: [
            _buildHeaderButtons(context),
            const Divider(height: 1, thickness: 0.5),
            _buildRealTimeRequests(),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text("People You May Know",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            ..._filteredContacts.map((contact) => _buildContactCard(contact)),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _topPillButton("Suggestions", () {}),
          const SizedBox(width: 8),
          _topPillButton("Your friends", () {
            // NAVIGATE TO YOUR FRIENDS LIST
            Navigator.push(context, MaterialPageRoute(builder: (context) => const YourFriendsScreen()));
          }),
        ],
      ),
    );
  }

  // --- (Existing _buildRealTimeRequests, _buildRequestRow, _buildContactCard, _fbButton, _topPillButton, _showSnackBar remain exactly the same as previous code) ---
  // ... Paste the rest of your previous code here ...

  Widget _buildRealTimeRequests() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('friend_requests')
          .where('receiverId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();
        final requestCount = snapshot.data!.docs.length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text("Friend Requests", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Text("$requestCount", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
                    ],
                  ),
                  TextButton(onPressed: () {}, child: const Text("See all", style: TextStyle(color: Color(0xFF1877F2))))
                ],
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var doc = snapshot.data!.docs[index];
                var data = doc.data() as Map<String, dynamic>;
                return _buildRequestRow(doc.id, data['senderName'] ?? "User");
              },
            ),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Divider(height: 32, thickness: 0.5)),
          ],
        );
      },
    );
  }

  Widget _buildRequestRow(String docId, String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const CircleAvatar(radius: 45, backgroundColor: Color(0xFFE4E6EB), child: Icon(Icons.person, size: 40, color: Colors.white)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _fbButton("Confirm", const Color(0xFF1877F2), Colors.white, () {
                      FirebaseFirestore.instance.collection('friend_requests').doc(docId).update({'status': 'accepted'});
                    })),
                    const SizedBox(width: 8),
                    Expanded(child: _fbButton("Delete", const Color(0xFFE4E6EB), Colors.black, () {
                      FirebaseFirestore.instance.collection('friend_requests').doc(docId).delete();
                    })),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildContactCard(Contact contact) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const CircleAvatar(radius: 45, backgroundColor: Color(0xFFF0F2F5), child: Icon(Icons.person, size: 45, color: Color(0xFF8D949E))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact.displayName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _fbButton("Add friend", const Color(0xFF1877F2), Colors.white, () {
                      _showSnackBar("Request sent to ${contact.displayName}");
                    })),
                    const SizedBox(width: 8),
                    Expanded(child: _fbButton("Remove", const Color(0xFFE4E6EB), Colors.black, () {
                      setState(() {
                        _filteredContacts.remove(contact);
                        _allContacts.remove(contact);
                      });
                    })),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fbButton(String label, Color bg, Color txt, VoidCallback onTap) {
    return SizedBox(
      height: 36,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(backgroundColor: bg, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: EdgeInsets.zero),
        child: Text(label, style: TextStyle(color: txt, fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    );
  }

  Widget _topPillButton(String label, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(backgroundColor: const Color(0xFFE4E6EB), padding: const EdgeInsets.symmetric(horizontal: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      child: Text(label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 1), behavior: SnackBarBehavior.floating));
  }
}

// --- NEW SCREEN: YOUR FRIENDS LIST ---
class YourFriendsScreen extends StatelessWidget {
  const YourFriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: const Text("All Friends", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Query friend_requests where I am either the sender or receiver and status is accepted
        stream: FirebaseFirestore.instance
            .collection('friend_requests')
            .where('status', isEqualTo: 'accepted')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          // Filter documents where currentUserId is involved
          final friendsDocs = snapshot.data!.docs.where((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            return data['senderId'] == currentUserId || data['receiverId'] == currentUserId;
          }).toList();

          if (friendsDocs.isEmpty) {
            return const Center(child: Text("You haven't added any friends yet.", style: TextStyle(color: Colors.grey)));
          }

          return ListView.builder(
            itemCount: friendsDocs.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> data = friendsDocs[index].data() as Map<String, dynamic>;

              // If I was the sender, show the receiver's name. If I was the receiver, show sender's name.
              String friendName = (data['senderId'] == currentUserId)
                  ? (data['receiverName'] ?? "Friend")
                  : (data['senderName'] ?? "Friend");

              return ListTile(
                leading: const CircleAvatar(radius: 30, backgroundColor: Color(0xFFF0F2F5), child: Icon(Icons.person, color: Colors.grey)),
                title: Text(friendName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                trailing: const Icon(Icons.more_horiz),
                onTap: () {
                  // Navigate to individual friend profile
                },
              );
            },
          );
        },
      ),
    );
  }
}