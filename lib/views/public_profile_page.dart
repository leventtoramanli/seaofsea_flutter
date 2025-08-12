// lib/views/public_profile_page.dart
// ignore_for_file: use_build_context_synchronously

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/services/routes.dart';
import 'package:seaofsea/services/v1/v1_api_manager.dart';
import 'package:seaofsea/utils/auth_provider.dart';
import 'package:seaofsea/utils/permission_provider.dart';
import 'package:seaofsea/widgets/custon_scaffold.dart';

class PublicProfilePage extends StatefulWidget {
  /// Argüman vermezsen kendi profilin açılır. Başkasını görmek için userId ver.
  final int? userId;
  const PublicProfilePage({super.key, this.userId});

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    final v1 = context.read<V1ApiManager>();

    // Yalın param: sadece userId verilmişse gönder.
    final Map<String, dynamic> params =
        (widget.userId != null) ? {'id': widget.userId} : {};

    _future = v1.call(
      module: 'profile',
      action: 'getProfile',
      params: params, // boşsa backend kendi profilini döndürür
    );
  }

  @override
  Widget build(BuildContext context) {
    final v1 = context.read<V1ApiManager>();
    final auth = context.read<AuthProvider>();

    // baseUrl sonundaki / işaretini kaldırıp uploads ile birleştiriyoruz
    final String base = v1.baseUrl.endsWith('/')
        ? v1.baseUrl.substring(0, v1.baseUrl.length - 1)
        : v1.baseUrl;

    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return const Center(child: Text('Bir hata oluştu.'));
        }

        final resp = snap.data ?? const {};
        final ok = resp['success'] == true;
        final data = (resp['data'] as Map<String, dynamic>?) ?? const {};

        if (!ok || data['id'] == null) {
          final msg = (resp['message']?.toString().trim().isNotEmpty ?? false)
              ? resp['message'].toString()
              : 'Kullanıcı bilgisi alınamadı.';
          return Center(child: Text(msg));
        }

        final int? currentUserId =
            int.tryParse(auth.userInfo?['id']?.toString() ?? '');
        final bool isOwnProfile =
            currentUserId != null && currentUserId == (data['id'] as int);

        // Admin mi? (admin.access veya user.manage)
        final isAdmin = context.select<PermissionProvider, bool>(
          (p) => p.can('admin.access') || p.can('user.manage'),
        );

        Widget buildCoverImage(dynamic fileNameRaw) {
          final String? fileName =
              (fileNameRaw is String && fileNameRaw.isNotEmpty)
                  ? fileNameRaw
                  : null;
          return (fileName != null)
              ? FadeInImage(
                  placeholder: const AssetImage('assets/cover.jpg'),
                  image: NetworkImage('$base/uploads/user/covers/$fileName'),
                  height: 240,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholderFit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 350),
                )
              : Image.asset(
                  'assets/cover.jpg',
                  height: 240,
                  width: double.infinity,
                  fit: BoxFit.cover,
                );
        }

        // ---- FIX: Tipi sabitle (ImageProvider<Object>) ----
        ImageProvider<Object> userImageProvider() {
          final raw = data['user_image'];
          if (raw is String && raw.isNotEmpty) {
            return NetworkImage('$base/uploads/user/user/$raw');
          }
          return const AssetImage('assets/sailorHat.png');
        }

        final String fullName =
            ('${data['name'] ?? ''} ${data['surname'] ?? ''}').trim();

        final String bio = (() {
          final raw = data['bio'];
          if (raw is String && raw.trim().isNotEmpty) return raw.trim();
          return 'No bio available.';
        })();

        return CustomScaffold(
          title: isOwnProfile ? 'My Profile' : 'User Profile',
          body: Stack(
            children: [
              buildCoverImage(data['cover_image']),
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
                            backgroundImage: userImageProvider(),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            fullName.isNotEmpty ? fullName : '—',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            bio,
                            style: const TextStyle(color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          // Bu sayfa HER ZAMAN read-only.
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Owner ise: Edit (Settings'e gitsin)
              if (isOwnProfile)
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton.filledTonal(
                    tooltip: 'Edit Profile',
                    onPressed: () => navigateReplacement(context, '/settings'),
                    icon: const Icon(Icons.edit),
                  ),
                ),

              // Owner değil + admin ise: Admin kısa yolu
              if (!isOwnProfile && isAdmin)
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton.filledTonal(
                    tooltip: 'Admin',
                    onPressed: () => navigateReplacement(context, '/admin'),
                    icon: const Icon(Icons.admin_panel_settings),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
