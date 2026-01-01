import 'package:flutter/material.dart';

// Ensure these paths match your project structure
import '../feed/ui/feed_screen.dart'; // Contains your HomeScreen
import '../feed/ui/friends_screen.dart';
import '../feed/ui/groups_screen.dart';
import '../feed/ui/notifications_screen.dart';
import '../profile/ui/profile_screen.dart';

class MainNavWrapper extends StatefulWidget {
  const MainNavWrapper({super.key});

  @override
  State<MainNavWrapper> createState() => _MainNavWrapperState();
}

class _MainNavWrapperState extends State<MainNavWrapper> {
  int _selectedIndex = 0;

  // IMPORTANT: The order here MUST match the order of items in the
  // BottomNavigationBar exactly.
  final List<Widget> _screens = [
    const HomeScreen(),          // Index 0 -> Home
    const FriendsScreen(),       // Index 1 -> Friends
    const GroupsScreen(),        // Index 2 -> Groups
    const NotificationsScreen(), // Index 3 -> Notifications
    const ProfileScreen(),       // Index 4 -> Profile
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),

      // IndexedStack is used so the app doesn't refresh every time you switch tabs.
      // It looks at _selectedIndex and shows the widget at that position in _screens.
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFFCED0D4), width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped, // Returns 0, 1, 2, 3, or 4
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF1877F2), // Facebook Blue
          unselectedItemColor: const Color(0xFF65676B), // Facebook Grey
          showSelectedLabels: false,
          showUnselectedLabels: false,
          iconSize: 28,
          items: const [
            // Item 0: Home Icon
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: "Home",
            ),
            // Item 1: Friends Icon
            BottomNavigationBarItem(
              icon: Icon(Icons.group_outlined),
              activeIcon: Icon(Icons.group_rounded),
              label: "Friends",
            ),
            // Item 2: Groups Icon
            BottomNavigationBarItem(
              icon: Icon(Icons.groups_outlined),
              activeIcon: Icon(Icons.groups_rounded),
              label: "Groups",
            ),
            // Item 3: Notifications Icon
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined),
              activeIcon: Icon(Icons.notifications_rounded),
              label: "Notifications",
            ),
            // Item 4: Profile Icon
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_outlined),
              activeIcon: Icon(Icons.account_circle_rounded),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}