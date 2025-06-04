import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/services/date_time_service.dart';
import 'package:seaofsea/utils/api_manager.dart';
import 'package:seaofsea/views/companies/company_user_detail_page.dart';
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
    final api = context.read<ApiManager>();
    final response = await api.post(context, 'get_company_users', {
      'company_id': widget.companyId,
    });

    if (response['success'] == true && response['data'] != null) {
      final data = response['data']['data'] as List<dynamic>? ?? [];

      // List<Map<String, dynamic>>
      List<Map<String, dynamic>> usersList = data.cast<Map<String, dynamic>>();

      // Status sıralaması için önceliklendirme fonksiyonu
      int getStatusPriority(String? status) {
        switch ((status ?? '').toLowerCase()) {
          case 'pending':
          case 'preapproved':
          case 'waitingmanagerapproval':
            return 0; // Öncelikli, en üstte
          case 'approved':
            return 1; // Onaylı kullanıcılar sonra
          default:
            return 2; // Diğerleri en sona
        }
      }

      // Sıralama (öncelikli durumlar önce gelir)
      usersList.sort((a, b) {
        final aPriority = getStatusPriority(a['status']);
        final bPriority = getStatusPriority(b['status']);
        return aPriority.compareTo(bPriority);
      });

      setState(() {
        users = usersList;
        isLoading = false;
      });
    } else {
      setState(() {
        users = [];
        isLoading = false;
      });
      // Hata mesajı ya da snackbar eklenebilir
    }
  }

  void _openUserDetail(Map<String, dynamic> user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserDetailPage(user: user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool wideScreen = MediaQuery.of(context).size.width > 650;
    final bool tWideScreen = MediaQuery.of(context).size.width > 850;
    if (isLoading) {
      return CustomScaffold(
        title: 'Company Users',
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Onay bekleyen kullanıcılar (pending, preApproved, waitingManagerApproval)
    final pendingStatuses = {
      'pending',
      'preapproved',
      'waitingmanagerapproval'
    };
    final pendingUsers = users.where((u) {
      final status = (u['status'] ?? '').toString().toLowerCase();
      return pendingStatuses.contains(status);
    }).toList();

    // Aktif kullanıcılar (approved, diğerleri)
    final activeUsers = users.where((u) {
      final status = (u['status'] ?? '').toString().toLowerCase();
      return !pendingStatuses.contains(status);
    }).toList();

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
                  .map((user) => _buildUserTile(user, wideScreen, tWideScreen))
                  .toList(),
            ),
          ExpansionTile(
            initiallyExpanded: false,
            title: Text('Aktif Kullanıcılar (${activeUsers.length})'),
            children: activeUsers
                .map((user) => _buildUserTile(user, wideScreen, tWideScreen))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(
      Map<String, dynamic> user, bool wideScreen, bool tWideScreen) {
    final displayName = '${user['name'] ?? ''} ${user['surname'] ?? ''}'.trim();
    final imageUrl = user['user_image'] != null
        ? '${context.read<ApiManager>().baseUrl}/images/user/user/${user['user_image']}'
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
        title: tWideScreen
            ? Row(
                children: [
                  Expanded(
                      child: Text(displayName.isEmpty ? 'Unnamed' : displayName)),
                  Expanded(child: Text('Status: $status')),
                  Expanded(child: Text('Approver: $approverF')),
                  Expanded(child: Text('Approver 2: $approverS')),
                  Expanded(child: Text(formattedDate)),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName.isEmpty ? 'Unnamed' : displayName),
                  Text('Status: $status'),
                  Text('Approver: $approverF'),
                  Text('Approver 2: $approverS'),
                  Text(formattedDate),
                ],
              ),
        onTap: () => _openUserDetail(user),
      ),
    );
  }
}
