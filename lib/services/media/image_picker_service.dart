import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  // Pick an image from the Gallery
  Future<File?> pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // Compresses image to save Firebase storage space
    );

    if (image != null) {
      return File(image.path);
    }
    return null;
  }

  // Capture a new photo from the Camera
  Future<File?> capturePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) return File(photo.path);
    return null;
  }
}