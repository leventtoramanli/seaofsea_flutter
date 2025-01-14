import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/api_manager.dart';
import 'package:seaofsea/widgets/custom_image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _coverImage;
  bool _isUploading = false;

  Future<void> uploadImage(File imageFile) async {
    setState(() {
      _isUploading = true;
    });

    try {
      final apiManager = Provider.of<ApiManager>(context, listen: false);
      final response = await apiManager.uploadFile(
        context,
        endpoint: 'upload_cover_image',
        file: imageFile,
      );

      if (response['success'] == true) {
        debugPrint('Image uploaded successfully: ${response['message']}');
      } else {
        debugPrint('Image upload failed: ${response['message']}');
      }
    } catch (e) {
      debugPrint('Error during upload: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              CustomImagePicker(
                aspectRatio: 4.0,
                onImagePicked: (file) async {
                  if (file != null) {
                    setState(() {
                      _coverImage = file;
                    });
                    await uploadImage(file);
                  }
                },
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 5,
                            offset: Offset(0, 0),
                          ),
                        ]),
                    child: Image.asset(
                      'assets/sailorHat.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Levent TORAMANLI',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          'Sailor',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  if (_isUploading)
                    const CircularProgressIndicator()
                  else
                    ElevatedButton(
                      onPressed: _coverImage != null
                          ? () => uploadImage(_coverImage!)
                          : null,
                      child: const Text("Upload"),
                    ),
                ],
              ),
              Divider(
                thickness: 2,
                color: Colors.grey[300],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
