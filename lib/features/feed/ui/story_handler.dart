import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 1. THE MODEL
class StoryModel {
  final String id;
  final String userId;
  final String imageUrl;
  final DateTime createdAt;

  StoryModel({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.createdAt,
  });

  // Convert Firestore document to Model
  factory StoryModel.fromMap(Map<String, dynamic> map, String documentId) {
    return StoryModel(
      id: documentId,
      userId: map['userId'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convert Model to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

// 2. THE UI & LOGIC HANDLER
class StoryUIHandler {
  static Future<void> handleCreateStory(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final FirebaseStorage storage = FirebaseStorage.instance;
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final User? user = FirebaseAuth.instance.currentUser;

    // A. Pick the Image
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // Compressing for faster upload
    );

    if (image == null) return; // User cancelled

    // B. Show Loading Feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(width: 20),
            Text("Uploading your story..."),
          ],
        ),
        duration: Duration(seconds: 10), // Will be dismissed manually
      ),
    );

    try {
      File file = File(image.path);
      String fileName = 'stories/${DateTime.now().millisecondsSinceEpoch}.jpg';

      // C. Upload to Firebase Storage
      //
      TaskSnapshot uploadTask = await storage.ref().child(fileName).putFile(file);
      String downloadUrl = await uploadTask.ref.getDownloadURL();

      // D. Save Reference to Firestore
      await firestore.collection('stories').add({
        'userId': user?.uid ?? 'anonymous',
        'imageUrl': downloadUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // E. Success Feedback
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Story Shared!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e"), backgroundColor: Colors.red),
      );
    }
  }
}