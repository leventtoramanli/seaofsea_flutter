import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  // Resim seç ve kırp
  Future<File?> pickAndCropImage({
    required BuildContext context,
    required double aspectRatio,
  }) async {
    try {
      // Resim seçimi
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return null;

      return File(pickedFile.path);
    } catch (e) {
      debugPrint("Image pick or crop error: $e");
      return null;
    }
  }
}
