import 'package:flutter/material.dart';

final List<Map<String, dynamic>> profileConfig = [
    {
      'type': 'imagePicker',
      'name': 'coverImage',
      'label': 'Cover Image',
      'placeholder': 'assets/cover.jpg',
      'width': double.infinity,
      'height': 200.0,
      'onComplete': (String? path) {
        debugPrint('Cover Image Saved: $path');
      },
    },
    {
      'type': 'imagePicker',
      'name': 'profileImage',
      'label': 'Profile Image',
      'placeholder': 'assets/sailorHat.png',
      'width': 100.0,
      'height': 100.0,
      'onComplete': (String? path) {
        debugPrint('Profile Image Saved: $path');
      },
    },
  ];