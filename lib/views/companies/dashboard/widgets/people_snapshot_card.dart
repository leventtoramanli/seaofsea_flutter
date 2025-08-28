import 'package:flutter/material.dart';
import 'package:seaofsea/widgets/online_images.dart';

class PeopleSnapshotCard extends StatelessWidget {
  final List<Map<String, dynamic>> people;
  final int companyId;
  const PeopleSnapshotCard(
      {super.key, required this.people, required this.companyId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.people_alt_outlined),
                const SizedBox(width: 8),
                Text('People', style: theme.textTheme.titleMedium),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/company_users',
                    arguments: {'company_id': companyId},
                  ),
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (people.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('No employees to show',
                    style: theme.textTheme.bodyMedium),
              )
            else
              Column(
                children: people.map((p) {
                  final name =
                      '${p['name'] ?? ''} ${p['surname'] ?? ''}'.trim();
                  final role =
                      (p['role'] ?? p['position_name'] ?? '').toString();

                  final imgName = (p['user_image'] ?? '').toString().trim();
                  final initials =
                      (name.isNotEmpty ? name[0] : '?').toUpperCase();

                  Widget leading;
                  if (imgName.isEmpty) {
                    leading = CircleAvatar(
                      radius: 18,
                      child: Text(initials),
                    );
                  } else {
                    leading = OnlineImage(
                      imagePath: 'user/user/', // uploads/ sonrası relative path
                      imageName: imgName,
                      sizeW: 36,
                      sizeH: 36,
                      rounded: true,
                      fallbackAsset: 'assets/avatar.png',
                    );
                  }

                  return ListTile(
                    dense: true,
                    leading: leading,
                    title: Text(name.isEmpty ? '—' : name),
                    subtitle: role.isEmpty ? null : Text(role),
                  );
                }).toList(),
              )
          ],
        ),
      ),
    );
  }
}
