import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:seaofsea/widgets/online_images.dart';

class PublicHero extends StatelessWidget {
  final String title;
  final List<String> typeNames;
  final String? shortDescription; // detail['about'] / ['description']
  final String? logoName;

  final int followerCount;

  final VoidCallback? onFollowPressed;
  final VoidCallback? onApplyNowPressed;
  final VoidCallback? onOpenJobsPressed;
  final VoidCallback? onSharePressed;
  final VoidCallback? onSaveContactPressed;

  final bool isFollowing;
  final bool followBusy;
  final VoidCallback? onToggleFollow;

  /// Daha kompakt görünüm için
  final bool compact;

  const PublicHero({
    super.key,
    required this.title,
    required this.typeNames,
    this.shortDescription,
    this.logoName,
    required this.followerCount,
    this.onFollowPressed,
    this.onApplyNowPressed,
    this.onOpenJobsPressed,
    this.onSharePressed,
    this.onSaveContactPressed,
    this.compact = true,
    this.isFollowing = false,
    this.followBusy = false,
    this.onToggleFollow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [c.primary.withAlpha(24), c.secondary.withAlpha(20)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor.withAlpha(60)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: _Body(
                title: title,
                typeNames: typeNames,
                shortDescription: shortDescription,
                logoName: logoName,
                followerCount: followerCount,
                // ▼ yeni props
                isFollowing: isFollowing,
                followBusy: followBusy,
                onToggleFollow: onToggleFollow,
                // diğer CTA’lar
                onApplyNowPressed: onApplyNowPressed,
                onOpenJobsPressed: onOpenJobsPressed,
                onSharePressed: onSharePressed,
                onSaveContactPressed: onSaveContactPressed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final String title;
  final List<String> typeNames;
  final String? shortDescription;
  final String? logoName;
  final int followerCount;

  // ▼▼ yeni alanlar
  final bool isFollowing;
  final bool followBusy;
  final VoidCallback? onToggleFollow;

  // opsiyonel diğer CTA’lar
  final VoidCallback? onApplyNowPressed;
  final VoidCallback? onOpenJobsPressed;
  final VoidCallback? onSharePressed;
  final VoidCallback? onSaveContactPressed;

  const _Body({
    required this.title,
    required this.typeNames,
    required this.shortDescription,
    required this.logoName,
    required this.followerCount,
    required this.isFollowing,
    required this.followBusy,
    required this.onToggleFollow,
    this.onApplyNowPressed,
    this.onOpenJobsPressed,
    this.onSharePressed,
    this.onSaveContactPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width >= 720;

    final logo = _buildLogo(title, logoName);
    final titleStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.2,
    );

    Widget followButton() {
      if (onToggleFollow == null) return const SizedBox.shrink();
      return isFollowing
          ? FilledButton.tonalIcon(
              onPressed: followBusy ? null : onToggleFollow,
              icon: const Icon(Icons.check),
              label: const Text('Following'),
            )
          : OutlinedButton.icon(
              onPressed: followBusy ? null : onToggleFollow,
              icon: const Icon(Icons.person_add_alt_1, size: 18),
              label: Text('Follow • $followerCount'),
            );
    }

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(title, style: titleStyle),
            if (typeNames.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: -8,
                children: typeNames.take(3).map((t) {
                  return Chip(
                    label: Text(t, style: const TextStyle(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  );
                }).toList(),
              ),
          ],
        ),
        if (shortDescription != null && shortDescription!.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              shortDescription!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
      ],
    );

    if (isWide) {
      // geniş: logo | başlık | (sağda follow)
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLogo(title, logoName),
          const SizedBox(width: 12),
          Expanded(child: titleBlock),
          const SizedBox(width: 12),
          Align(alignment: Alignment.topRight, child: followButton()),
        ],
      );
    }

    // dar ekranda: üstte logo+başlık, altında follow ve diğer CTA’lar
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildLogo(title, logoName),
            const SizedBox(width: 12),
            Expanded(child: titleBlock),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            followButton(),
            if (onApplyNowPressed != null)
              FilledButton.icon(
                onPressed: onApplyNowPressed,
                icon: const Icon(Icons.assignment_outlined),
                label: const Text('Apply Now'),
              ),
            if (onOpenJobsPressed != null)
              FilledButton.tonalIcon(
                onPressed: onOpenJobsPressed,
                icon: const Icon(Icons.badge_outlined),
                label: const Text('Open Jobs'),
              ),
            if (onSharePressed != null)
              IconButton.filledTonal(
                onPressed: onSharePressed,
                icon: const Icon(Icons.share),
              ),
            if (onSaveContactPressed != null)
              IconButton.filledTonal(
                onPressed: onSaveContactPressed,
                icon: const Icon(Icons.contact_page_outlined),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildLogo(String title, String? logoName) {
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
      imagePath: 'images/companies/logo/',
      imageName: file,
      sizeW: 56,
      sizeH: 56,
      rounded: true,
    );
  }
}
