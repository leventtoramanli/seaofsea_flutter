import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/api_manager.dart';
import 'package:seaofsea/utils/auth_provider.dart';
import 'package:seaofsea/utils/secure_storage.dart';
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
  bool _isLoading = true;
  late final ApiManager _apiManager;
  late final AuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
    _apiManager = Provider.of<ApiManager>(context, listen: false);
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    _refreshUserData();
  }

  Future<void> _refreshUserData() async {
    if (!_authProvider.isLoggedIn) {
      debugPrint('User not logged in, skipping refresh.');
      setState(() => _isLoading = false);
      return;
    }
    try {
      await _authProvider.refreshUserInfo(context);
      debugPrint('User info refreshed successfully.');
      setState(() => _isLoading = false);
      _checkUserImage(context); // ✅ Kullanıcı verisi geldikten sonra çağırıyoruz
    } catch (e) {
      debugPrint('Failed to refresh user info: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkUserImage(BuildContext context) async {
  if (_authProvider.userInfo == null || !_authProvider.isLoggedIn) {
    debugPrint('Skipping image check. User not logged in.');
    return;
  }

  final userInfo = _authProvider.userInfo;
  final userId = userInfo?['id'];
  debugPrint('Returned: ${jsonEncode(userInfo)}');

  if (userId == null) {
    debugPrint('Error: user_id is null before checking image!');
    return;
  }

  debugPrint('Checking cover image for user ID: $userId');

  try {
    final response = await _apiManager.request(
      context,
      endpoint: 'check_cover_images',
      method: 'POST',
      body: {'user_id': userId},
    );

    debugPrint('🔍 API Yanıtı: ${response.toString()}');

    if (response == null) {
      throw Exception('API response is null');
    }

    if (response is! Map<String, dynamic>) {
      debugPrint('⚠️ API yanıtı JSON formatında değil. Response: $response');
      return;
    }

    if (!response.containsKey('success')) {
      debugPrint('⚠️ API yanıtında success anahtarı bulunamadı.');
      return;
    }

    if (!response['success']) {
      debugPrint('Image check failed: ${response['message']}');
    } else {
      debugPrint('Image check successful: ${response['message']}');

      final newCoverImage = response['data']['cover_image'] ?? '';
      if (newCoverImage.isNotEmpty) {
        debugPrint("📌 Yeni Cover Image: $newCoverImage");

        // ✅ Secure Storage Güncelle
        await SecureStorage().writeSecureData('coverImage', newCoverImage);

        // ✅ AuthProvider'ı Güncelle
        _authProvider.refreshUserInfo(context);

        // ✅ Image Cache Temizle
        imageCache.clear();
        imageCache.clearLiveImages();
      }
    }
  } catch (e) {
    debugPrint('🛑 Error while checking user image: $e');
  }
}



  Future<String?> uploadImage(File file) async {
    final apiManager = Provider.of<ApiManager>(context, listen: false);
    final response = await apiManager.uploadImage(
      context,
      endpoint: 'upload_cover_image',
      file: file,
    );
    if (response['success'] == true) {
      await _authProvider.refreshUserInfo(context);
      return response['data']['file_name'];
    }
    return null;
  }
  Future<void> updateDatabase(String fileName) async {
    final apiManager = Provider.of<ApiManager>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userInfo?['id'];
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final apiManager = ApiManager.empty();
    final userId = authProvider.userInfo?['id'];
    final userName = authProvider.userInfo!['name'];
    final userSurName = authProvider.userInfo!['surname'];

    final coverImageUrl = 'images/user/covers/${authProvider.userInfo!['cover_image']}';
    //final isAssetImage = coverImageUrl == null;

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
                existingImageUrl: coverImageUrl != null
                    ? '${apiManager.showImage(coverImageUrl, false)}'
                    : null,
                onImagePicked: (file, String? base64Image) async {
                  if (file != null || base64Image != null) {
                    // Yükleme işlemini başlat
                    final apiManager =
                        Provider.of<ApiManager>(context, listen: false);
                    final response = await apiManager.uploadImage(
                      context,
                      endpoint: 'upload_cover_image',
                      file: file!,
                    );
                    print('Response: $response');
                    if (response['success'] || response != null) {
                      //final newCoverImage = response['data']['file_name'];
                      await authProvider.refreshUserInfo(context);
                    }
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
                    child: CustomImagePicker(
                      aspectRatio: 1,
                      iwidth: 100,
                      iheight: 100,
                      iradius: 12.0,
                      meta: {
                        'Publisher': 'Sea of Sea',
                        'Description': 'Cover Image - $userName $userSurName',
                        'Title': 'Cover Image - $userName $userSurName',
                        'Author': 'Sea of Sea',
                        'UserId': userId.toString(),
                      },
                      existingImageUrl: coverImageUrl != null
                          ? '${apiManager.showImage(coverImageUrl, false)}'
                          : null,
                      onImagePicked: (file, String? base64Image) async {
                        if (file != null || base64Image != null) {
                          // Yükleme işlemini başlat
                          final apiManager =
                              Provider.of<ApiManager>(context, listen: false);
                          final response = await apiManager.uploadImage(
                            context,
                            endpoint: 'upload_cover_image',
                            file: file!,
                          );
                          print('Response: $response');
                          if (response['success'] || response != null) {
                            //final newCoverImage = response['data']['file_name'];
                            await authProvider.refreshUserInfo(context);
                          }
                        }
                      },
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
