import 'package:flutter/material.dart';
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
