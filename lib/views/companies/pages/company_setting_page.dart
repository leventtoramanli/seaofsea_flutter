import 'package:flutter/material.dart';
import 'package:seaofsea/utils/permission_gate.dart';
import 'package:seaofsea/widgets/online_images.dart';

class CompanySettingsPage extends StatelessWidget {
  final Map<String, dynamic> companyData;

  const CompanySettingsPage({super.key, required this.companyData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Company Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                OnlineImage(
                  imagePath: 'images/companies/logo',
                  imageName: companyData['logo'] ?? '',
                  sizeW: 64,
                  rounded: true,
                  border: true,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        companyData['name'] ?? 'Company Name',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (companyData['type'] != null)
                        Text(
                          companyData['type'],
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      PermissionGate(
                        permissionCode: 'position.update',
                        companyId: (companyData['company_id'] ??
                            companyData['id']) as int?,
                        wait:
                            true, // izin kontrolü bitene kadar skeleton gizlesin
                        child: ListTile(
                          leading: const Icon(Icons.badge_outlined),
                          title: const Text('Position Permissions'),
                          subtitle: const Text(
                              'Define default permissions per position'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.pushNamed(
                              context, '/position_permissions'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const Text('CompanySettingsPage (to be implemented)'),
          ],
        ),
      ),
    );
  }
}
