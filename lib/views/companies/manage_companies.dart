// views/company/manage_company_page.dart
import 'package:flutter/material.dart';
import 'package:seaofsea/widgets/custon_scaffold.dart';

class ManageCompanyPage extends StatelessWidget {
  const ManageCompanyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Manage Company',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/create_company');
              },
              icon: const Icon(Icons.add_business),
              label: const Text('Create New Company'),
            ),
            const SizedBox(height: 20),
            const Text("My Companies (List will be here...)"),
          ],
        ),
      ),
    );
  }
}
