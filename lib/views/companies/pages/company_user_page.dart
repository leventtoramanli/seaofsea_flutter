// views/companies/company_user_page.dart
import 'package:flutter/material.dart';
import 'package:seaofsea/services/date_time_service.dart';
import 'package:seaofsea/services/v1/v1_api_manager.dart';
import 'package:seaofsea/services/v1/v1_config.dart';
import 'package:seaofsea/views/companies/pages/company_user_detail_page.dart';
import 'package:seaofsea/widgets/custon_scaffold.dart';

class CompanyUsersPage extends StatefulWidget {
  final int companyId;
  const CompanyUsersPage({super.key, required this.companyId});

  @override
  State<CompanyUsersPage> createState() => _CompanyUsersPageState();
}

class _CompanyUsersPageState extends State<CompanyUsersPage> {
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    final v1 = V1ApiManager();
    final res = await v1.call(
      module: 'company',
      action: 'members_list',
      params: {'company_id': widget.companyId, 'perPage': 500},
      context: context,
    );

    final data = (res['data'] is Map) ? res['data'] : null;
    final list = (data != null && data['items'] is List)
        ? List<Map<String, dynamic>>.from(data['items'])
        : <Map<String, dynamic>>[];

    int prio(String? s) {
      switch ((s ?? '').toLowerCase()) {
        case 'pending':
        case 'preapproved':
        case 'waitingmanagerapproval':
        case 'waiting_manager_approval':
          return 0;
        case 'approved':
          return 1;
        default:
          return 2;
      }
    }

    list.sort((a, b) => prio(a['status']).compareTo(prio(b['status'])));

    setState(() {
      users = list;
      isLoading = false;
    });
  }

  void _openUserDetail(Map<String, dynamic> user) {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => UserDetailPage(user: user)));
  }

  @override
  Widget build(BuildContext context) {
    final bool wideScreen = MediaQuery.of(context).size.width > 650;
    final bool tWideScreen = MediaQuery.of(context).size.width > 850;
    if (isLoading) {
      return const CustomScaffold(
          title: 'Company Users',
          body: Center(child: CircularProgressIndicator()));
    }

    final pendingStatuses = {
      'pending',
      'preapproved',
      'waitingmanagerapproval',
      'waiting_manager_approval'
    };
    final pendingUsers = users
        .where((u) => pendingStatuses
            .contains((u['status'] ?? '').toString().toLowerCase()))
        .toList();
    final activeUsers = users
        .where((u) => !pendingStatuses
            .contains((u['status'] ?? '').toString().toLowerCase()))
        .toList();

    return CustomScaffold(
      title: 'Company Users',
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (pendingUsers.isNotEmpty)
            ExpansionTile(
              initiallyExpanded: true,
              title: Text('Onay Bekleyenler (${pendingUsers.length})'),
              children: pendingUsers
                  .map((u) => _tile(u, wideScreen, tWideScreen))
                  .toList(),
            ),
          ExpansionTile(
            initiallyExpanded: false,
            title: Text('Aktif Kullanıcılar (${activeUsers.length})'),
            children: activeUsers
                .map((u) => _tile(u, wideScreen, tWideScreen))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _tile(Map<String, dynamic> user, bool wide, bool twide) {
    final displayName = '${user['name'] ?? ''} ${user['surname'] ?? ''}'.trim();
    final imgFile = user['user_image']?.toString();
    final imageUrl = (imgFile != null && imgFile.isNotEmpty)
        ? '${V1Config.baseUrl}uploads/user/user/$imgFile'
        : null;
    final created = user['created_at'];
    final formattedDate =
        created != null ? DateTimeService.formatFromISO(created, context) : '-';

    final status = user['status'] ?? '-';
    final approverF = user['approvalF'] ?? '-';
    final approverS = user['approvalS'] ?? '-';

    return Card(
      child: ListTile(
        leading: imageUrl != null
            ? CircleAvatar(backgroundImage: NetworkImage(imageUrl))
            : const CircleAvatar(child: Icon(Icons.person)),
        title: twide
            ? Row(children: [
                Expanded(
                    child: Text(displayName.isEmpty ? 'Unnamed' : displayName)),
                Expanded(child: Text('Status: $status')),
                Expanded(child: Text('Approver: $approverF')),
                Expanded(child: Text('Approver 2: $approverS')),
                Expanded(child: Text(formattedDate)),
              ])
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(displayName.isEmpty ? 'Unnamed' : displayName),
                Text('Status: $status'),
                Text('Approver: $approverF'),
                Text('Approver 2: $approverS'),
                Text(formattedDate),
              ]),
        onTap: () => _openUserDetail(user),
      ),
    );
  }
}
