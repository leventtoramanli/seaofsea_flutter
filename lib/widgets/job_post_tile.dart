import 'package:flutter/material.dart';
import 'package:seaofsea/widgets/online_images.dart';

class JobPostTile extends StatelessWidget {
  final String title;
  final String companyName;
  final String location;
  final String updatedAt;

  final String? companyLogoPath; // kullanılmıyor; standart path kullanıyoruz
  final String?
      companyLogoName; // kullanılmıyor; yalnızca companyLogo kullanıyoruz
  final String? companyLogo; // sadece dosya adı (örn: abc.png)

  final String? fallbackAsset;
  final String? miniSummary; // 🆕 maaş / rotation kısa özet
  final VoidCallback? onTap;

  const JobPostTile({
    super.key,
    required this.title,
    required this.companyName,
    required this.location,
    required this.updatedAt,
    this.companyLogoPath,
    this.companyLogoName,
    this.companyLogo,
    this.fallbackAsset,
    this.miniSummary, // 🆕
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subtitleMain = [
      if (companyName.isNotEmpty) companyName,
      if (location.isNotEmpty) location,
      if (updatedAt.isNotEmpty) _relative(updatedAt),
    ].where((e) => e.isNotEmpty).join(' · ');

    final hasMini = (miniSummary != null && miniSummary!.trim().isNotEmpty);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      leading: _buildLeading(context),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(subtitleMain, maxLines: 1, overflow: TextOverflow.ellipsis),
          if (hasMini) ...[
            const SizedBox(height: 4),
            Text(
              miniSummary!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ],
      ),
      trailing: FilledButton(onPressed: onTap, child: const Text('Check')),
      onTap: onTap,
      isThreeLine: hasMini,
      shape: const Border(
        bottom: BorderSide(color: Colors.blueGrey, width: 0.3),
        top: BorderSide(color: Colors.blueGrey, width: 0.1),
      ),
    );
  }

  Widget _buildLeading(BuildContext context) {
    final logoName = companyLogo ?? '';
    if (logoName.isEmpty || logoName == 'null') {
      return CircleAvatar(
        radius: 24,
        child: Text(
          (companyName.isNotEmpty ? companyName.characters.first : '?')
              .toUpperCase(),
        ),
      );
    }
    return OnlineImage(
      imagePath: 'images/companies/logo/',
      imageName: logoName,
      sizeW: 48,
      sizeH: 48,
      rounded: true,
      fallbackAsset: fallbackAsset,
    );
  }

  // --- Yardımcılar ---
  String _relative(String s) {
    try {
      DateTime dt;
      if (s.contains('T')) {
        dt = DateTime.tryParse(s) ?? DateTime.now();
      } else {
        final parts = s.split(' ');
        final d = parts.first;
        final t = parts.length > 1 ? parts[1] : '00:00:00';
        dt = DateTime.tryParse('${d}T$t') ?? DateTime.now();
      }
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Now';
      if (diff.inHours < 1) {
        final m = diff.inMinutes;
        return '$m Minute${m == 1 ? '' : 's'} ago';
      }
      if (diff.inDays < 1) {
        final h = diff.inHours;
        return '$h Hour${h == 1 ? '' : 's'} ago';
      }
      final d = diff.inDays;
      return '$d Day${d == 1 ? '' : 's'} ago';
    } catch (_) {
      return s;
    }
  }
}
