import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/api_manager.dart';
import 'package:seaofsea/utils/auth_provider.dart';
import 'package:seaofsea/widgets/custom_image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // ignore: unused_field
  File? _coverImage;
  bool _isUploading = false;

  Future<String?> uploadImage(File file) async {
    final apiManager = Provider.of<ApiManager>(context, listen: false);

    final response = await apiManager.uploadImage(
      context,
      endpoint: 'upload_cover_image',
      file: file,
    );

    if (response['success'] == true) {
      debugPrint(
          'Image uploaded successfully: ${response['message']}${response['data']}');
      return response['data']['file_name'];
    } else {
      debugPrint(
          'Image upload failed: ${response['message']}${response['data']}');
      return null;
    }
  }

  Future<void> handleImageUpload(File? file, String? base64Image) async {
    setState(() {
      _isUploading = true;
    });

    try {
      if (file != null) {
        // Mobil: Dosyayı doğrudan yükle
        final fileName = await uploadImage(file);
        print('File name: $fileName');
        if (fileName != null) {
          print('Starting database update...');
          await updateDatabase(fileName);
        }
      } else if (base64Image != null) {
        final apiManager = Provider.of<ApiManager>(context, listen: false);
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userId = authProvider.userInfo!['id'];

        final response = await apiManager.post(context, 'upload_cover_image', {
          'image_base64': base64Image,
          'user_id': userId,
          'meta': {
            'Publisher': 'SeaOfSea',
            'Description': 'Cover image upload',
            'Title': 'User cover image',
            'Author': 'SeaOfSea',
            'UserId': userId.toString(),
          },
        });

        if (response['success'] == true) {
          debugPrint(
              'Base64 image uploaded successfully: ${response['message']}');
          final fileName = response['data']['file_name'];
          await updateDatabase(fileName);
        } else {
          throw Exception('Base64 upload failed: ${response['message']}');
        }
      }
    } catch (e) {
      debugPrint('Error during image upload: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> updateDatabase(String fileName) async {
    final apiManager = Provider.of<ApiManager>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userInfo!['id'];
    print('Update function called with file name: $fileName');
    final response = await apiManager.post(
      context,
      'upload_cover_image',
      {
        'user_id': userId,
        'file_name': fileName,
      },
    );

    if (response['success'] == true) {
      debugPrint('Database updated successfully: ${response['message']}');
    } else {
      debugPrint('Database update failed: ${response['message']}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userInfo!['id'];
    final userName = authProvider.userInfo!['name'];
    final userSurName = authProvider.userInfo!['surname'];

    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              CustomImagePicker(
                aspectRatio: 19 / 3,
                meta: {
                  'Publisher': 'Sea of Sea',
                  'Description': 'Cover Image - $userName $userSurName',
                  'Title': 'Cover Image - $userName $userSurName',
                  'Author': 'Sea of Sea',
                  'UserId': userId.toString(),
                },
                onImagePicked: (file, base64Image) async {
                  if (file != null || base64Image != null) {
                    setState(() {
                      _coverImage = file;
                    });
                    await handleImageUpload(file, base64Image);
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
                  if (_isUploading) const CircularProgressIndicator()
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
