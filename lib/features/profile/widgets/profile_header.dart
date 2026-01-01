import 'package:flutter/material.dart';
import '../../../core/constants/fb_colors.dart';

class ProfileHeader extends StatelessWidget {
  final String coverImageUrl;
  final String profileImageUrl;
  final String name;

  const ProfileHeader({
    super.key,
    required this.coverImageUrl,
    required this.profileImageUrl,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Cover Photo
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: FBColors.lightGrey,
                image: DecorationImage(
                  image: NetworkImage(coverImageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Profile Picture (Overlapping)
            Positioned(
              bottom: -60,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: CircleAvatar(
                  radius: 80,
                  backgroundColor: FBColors.lightGrey,
                  backgroundImage: NetworkImage(profileImageUrl),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 70), // Spacer for the overlapping avatar
        Text(
          name,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}