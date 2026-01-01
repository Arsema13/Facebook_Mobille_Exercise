import 'package:flutter/material.dart';
import '../constants/fb_colors.dart';

class FBAvatar extends StatelessWidget {
  final String imageUrl;
  final bool hasStory;
  final bool isOnline;

  const FBAvatar({
    super.key,
    required this.imageUrl,
    this.hasStory = false,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 20.0,
          backgroundColor: FBColors.blue,
          child: CircleAvatar(
            radius: hasStory ? 17.0 : 20.0,
            backgroundColor: FBColors.lightGrey,
            backgroundImage: NetworkImage(imageUrl),
          ),
        ),
        if (isOnline)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              height: 12,
              width: 12,
              decoration: BoxDecoration(
                color: FBColors.greenOnline,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}