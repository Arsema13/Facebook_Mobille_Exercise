import 'package:flutter/material.dart';
import '../constants/fb_colors.dart';
import 'fb_circular_button.dart';

class FBAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FBAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(60.0);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: FBColors.white,
      elevation: 0,
      title: const Text(
        'facebook',
        style: TextStyle(
          color: FBColors.blue,
          fontSize: 28.0,
          fontWeight: FontWeight.bold,
          letterSpacing: -1.2,
        ),
      ),
      centerTitle: false,
      actions: [
        FBCircularButton(icon: Icons.search, onTap: () => print('Search')),
        FBCircularButton(icon: Icons.messenger, onTap: () => print('Messenger')),
      ],
    );
  }
}