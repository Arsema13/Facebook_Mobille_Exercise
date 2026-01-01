import 'package:flutter/material.dart';
import '../constants/fb_colors.dart';

class FBCircularButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double iconSize;

  const FBCircularButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.iconSize = 25,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(6.0),
      decoration: const BoxDecoration(
        color: FBColors.lightGrey,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: FBColors.blackText),
        iconSize: iconSize,
        onPressed: onTap,
      ),
    );
  }
}