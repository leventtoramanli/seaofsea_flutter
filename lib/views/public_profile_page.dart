import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/services/routes.dart';
import 'package:seaofsea/utils/api_manager.dart';
import 'package:seaofsea/utils/auth_provider.dart';
import 'package:seaofsea/widgets/custon_scaffold.dart';

class PublicProfilePage extends StatelessWidget {
  final int userId;

  const PublicProfilePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final apiManager = Provider.of<ApiManager>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId =
        int.tryParse(authProvider.userInfo?['id'].toString() ?? '-1');

    return FutureBuilder(
      future: apiManager.post(context, 'get_user_info', {'user_id': userId}),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData ||
            snapshot.data == null ||
            snapshot.data['success'] != true) {
          return const Center(child: Text("Kullanıcı bilgisi alınamadı."));
        }

        final data = snapshot.data['data'];
        if (data == null || data['id'] == null) {
          return const Center(child: Text("Geçersiz kullanıcı verisi."));
        }

        final isOwnProfile = currentUserId == data['id'];

        Widget buildCoverImage(String? coverFileName, ApiManager apiManager) {
          final hasCover = coverFileName != null && coverFileName.isNotEmpty;

          return hasCover
              ? FadeInImage(
                  placeholder: const AssetImage('assets/cover.jpg'),
                  image: NetworkImage(
                      '${apiManager.baseUrl}/images/user/covers/$coverFileName'),
                  height: 240,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholderFit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 400),
                )
              : Image.asset(
                  'assets/cover.jpg',
                  height: 240,
                  width: double.infinity,
                  fit: BoxFit.cover,
                );
        }

        final userImage = data['user_image'] != null
            ? NetworkImage(
                '${apiManager.baseUrl}/images/user/user/${data['user_image']}')
            : const AssetImage('assets/sailorHat.png') as ImageProvider<Object>;

        return CustomScaffold(
          title: isOwnProfile ? "My Profile" : "User Profile",
          body: Stack(
            children: [
              buildCoverImage(data['cover_image'], apiManager),
              Padding(
                padding: const EdgeInsets.only(top: 220),
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(30)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(15),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(30)),
                        border: Border.all(color: Colors.white.withAlpha(20)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: userImage,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${data['name']} ${data['surname']}',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            data['bio'] ?? 'No bio available.',
                            style: const TextStyle(color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          if (isOwnProfile)
                            Column(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    navigateReplacement(context, '/settings');
                                  },
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Edit Profile'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    navigateReplacement(
                                        context, '/create_company');
                                  },
                                  icon: const Icon(Icons.business),
                                  label: const Text('Create Company'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    navigateReplacement(
                                        context, '/join_company');
                                  },
                                  icon: const Icon(Icons.group_add),
                                  label: const Text('Join Company'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
