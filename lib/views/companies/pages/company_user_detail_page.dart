// views/companies/company_user_detail_page.dart
import 'package:flutter/material.dart';
import 'package:seaofsea/services/v1/v1_config.dart';
import 'package:seaofsea/widgets/custon_scaffold.dart';

class UserDetailPage extends StatelessWidget {
  final Map<String, dynamic> user;
  const UserDetailPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final displayName = '${user['name'] ?? ''} ${user['surname'] ?? ''}'.trim();
    final approvalF = user['approvalF_name'] != null
        ? '${user['approvalF_name']} ${user['approvalF_surname'] ?? ''}'
        : '-';
    final approvalS = user['approvalS_name'] != null
        ? '${user['approvalS_name']} ${user['approvalS_surname'] ?? ''}'
        : '-';

    final img = user['user_image']?.toString();
    final imgUrl = (img != null && img.isNotEmpty)
        ? '${V1Config.baseUrl}uploads/user/user/$img'
        : null;

    return CustomScaffold(
      title: 'User Details',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: imgUrl != null
                ? CircleAvatar(
                    radius: 50, backgroundImage: NetworkImage(imgUrl))
                : const CircleAvatar(
                    radius: 50, child: Icon(Icons.person, size: 50)),
          ),
          const SizedBox(height: 16),
          Text('Name: ${displayName.isEmpty ? '-' : displayName}',
              style: Theme.of(context).textTheme.titleLarge),
          Text('Role: ${user['role'] ?? '-'}',
              style: Theme.of(context).textTheme.titleMedium),
          Text('Rank: ${user['rank'] ?? '-'}',
              style: Theme.of(context).textTheme.titleMedium),
          Text('Status: ${user['status'] ?? '-'}',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Text('First Approval: $approvalF',
              style: Theme.of(context).textTheme.titleMedium),
          Text('Second Approval: $approvalS',
              style: Theme.of(context).textTheme.titleMedium),
        ]),
      ),
    );
  }
}
