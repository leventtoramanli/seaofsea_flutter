import 'package:flutter/material.dart';
import 'package:seaofsea/widgets/online_images.dart';

class HeaderCard extends StatelessWidget {
  final String title;
  final List<String> typeNames;
  final String role; // admin|editor|viewer|follower|none
  final int followerCount;
  final VoidCallback? onManage;
  final VoidCallback? onFollowToggle;
  final String? logoName;

  const HeaderCard({
    super.key,
    required this.title,
    required this.typeNames,
    required this.role,
    required this.followerCount,
    this.onManage,
    this.onFollowToggle,
    this.logoName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            c.primary.withAlpha(30),
            c.secondary.withAlpha(20),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? Colors.white24 : Colors.black12),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          _buildLogo(title),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    _RoleChip(role: role),
                  ],
                ),
                const SizedBox(height: 6),
                if (typeNames.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: -8,
                    children: typeNames
                        .take(3)
                        .map((t) => Chip(
                              label:
                                  Text(t, style: const TextStyle(fontSize: 12)),
                              visualDensity: VisualDensity.compact,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                            ))
                        .toList(),
                  ),
                if (typeNames.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+${typeNames.length - 3} more types',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Wrap(
            spacing: 8,
            children: [
              if (onFollowToggle != null)
                OutlinedButton.icon(
                  onPressed: onFollowToggle,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: Text('Follow • $followerCount'),
                ),
              if (onManage != null)
                FilledButton.icon(
                  onPressed: onManage,
                  icon: const Icon(Icons.settings),
                  label: const Text('Manage'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(String title) {
    final file = (logoName ?? '').trim();
    if (file.isEmpty || file.toLowerCase() == 'null') {
      return CircleAvatar(
        radius: 28,
        child: Text(
          title.isNotEmpty ? title[0].toUpperCase() : 'C',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      );
    }
    return OnlineImage(
      imagePath: 'images/companies/logo/', // uploads/ sonrası relative path
      imageName: file,
      sizeW: 56,
      sizeH: 56,
      rounded: true,
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String role;
  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    Color color;
    if (role == 'admin') {
      color = Colors.redAccent;
    } else if (role == 'editor') {
      color = Colors.orange;
    } else if (role == 'viewer') {
      color = Colors.blueGrey;
    } else if (role == 'follower') {
      color = Colors.teal;
    } else {
      color = Colors.grey;
    }
    return Chip(
      backgroundColor: color.withAlpha(30),
      side: BorderSide(color: color.withAlpha(75)),
      label: Text(role.toUpperCase()),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
