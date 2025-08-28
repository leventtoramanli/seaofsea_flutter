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
import 'package:seaofsea/widgets/online_images.dart';

class PublicProfilePage extends StatefulWidget {
  /// If userId is null, opens the current user's profile; otherwise shows a public profile.
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

    final params =
        (widget.userId != null) ? {'id': widget.userId} : <String, dynamic>{};

    _future = v1.call(
      module: 'profile',
      action: 'getProfile',
      params: params, // empty => backend returns own profile
    );
  }

  @override
  Widget build(BuildContext context) {
    final v1 = context.read<V1ApiManager>();
    final auth = context.read<AuthProvider>();
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Normalize base URL (no trailing slash) for manual cover URL below
    final String base = v1.baseUrl.endsWith('/')
        ? v1.baseUrl.substring(0, v1.baseUrl.length - 1)
        : v1.baseUrl;

    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snap) {
        // Always keep app layout consistent
        if (snap.connectionState == ConnectionState.waiting) {
          return CustomScaffold(
            title: 'Profile',
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return CustomScaffold(
            title: 'Profile',
            body: const Center(child: Text('An unexpected error occurred.')),
          );
        }

        final resp = snap.data ?? const {};
        final ok = resp['success'] == true || resp.containsKey('data');
        final data = (resp['data'] as Map<String, dynamic>?) ?? resp;

        if (!ok || data['id'] == null) {
          final msg = (resp['message']?.toString().trim().isNotEmpty ?? false)
              ? resp['message'].toString()
              : 'Profile could not be loaded.';
          return CustomScaffold(
            title: 'Profile',
            body: Center(child: Text(msg)),
          );
        }

        final int? currentUserId =
            int.tryParse(auth.userInfo?['id']?.toString() ?? '');
        final bool isOwnProfile =
            currentUserId != null && currentUserId == (data['id'] as int);

        // Admin quick action permission
        final isAdmin = context.select<PermissionProvider, bool>(
          (p) => p.can('admin.access') || p.can('user.manage'),
        );

        // --- Cover image (network or fallback asset) ---
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
                  fadeInDuration: const Duration(milliseconds: 300),
                )
              : Image.asset(
                  'assets/cover.jpg',
                  height: 240,
                  width: double.infinity,
                  fit: BoxFit.cover,
                );
        }

        final String fullName =
            ('${data['name'] ?? ''} ${data['surname'] ?? ''}').trim();

        final String bio = (() {
          final raw = data['bio'];
          if (raw is String && raw.trim().isNotEmpty) return raw.trim();
          return 'No bio available.';
        })();

        // Glass panel colors based on theme for legible text on image
        final Color glassBg =
            isDark ? c.surface.withAlpha(56) : c.surface.withAlpha(195);
        final Color glassBorder =
            c.outlineVariant.withAlpha(isDark ? 90 : 115);

        return CustomScaffold(
          title: isOwnProfile ? 'My Profile' : 'User Profile',
          body: Stack(
            children: [
              // Cover
              buildCoverImage(data['cover_image']),

              // Glass card block
              Padding(
                padding: const EdgeInsets.only(top: 220),
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: glassBg,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(28)),
                        border: Border.all(color: glassBorder),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ---- Avatar (OnlineImage) ----
                          OnlineImage(
                            imagePath:
                                'user/user/', // -> .../uploads/user/user/<name>
                            imageName: (data['user_image'] ?? '').toString(),
                            sizeW: 100,
                            sizeH: 100,
                            rounded: true,
                            border: true,
                            fallbackAsset: 'assets/sailorHat.png',
                          ),
                          const SizedBox(height: 12),

                          // Name
                          Text(
                            fullName.isNotEmpty ? fullName : '—',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 8),

                          // Bio
                          Text(
                            bio,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withAlpha(217),
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 16),
                          // (Public page is read-only by design)
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Top-right actions
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
