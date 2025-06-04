import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/api_manager.dart';
import 'package:seaofsea/views/companies/company_detail_page.dart';

class CompanyAdminPage extends StatefulWidget {
  const CompanyAdminPage({super.key});

  @override
  State<CompanyAdminPage> createState() => _CompanyAdminPageState();
}

class _CompanyAdminPageState extends State<CompanyAdminPage> {
  Future<List<Map<String, dynamic>>> fetchAdminCompanies() async {
    final api = Provider.of<ApiManager>(context, listen: false);
    final response = await api.post(context, 'get_user_companies', {});
    if (response != null && response['success'] == true) {
      final companies = response['data'] as List<dynamic>? ?? [];
      final adminEditorCompanies = companies
          .where((company) =>
              company['role'] == 'admin' || company['role'] == 'editor')
          .toList();
      return List<Map<String, dynamic>>.from(adminEditorCompanies);
    }
    return [];
  }

  void navigateToCompany(Map<String, dynamic> company) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CompanyShowcasePage(companyData: company),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchAdminCompanies(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Hata oluştu. Lütfen tekrar deneyin.'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Admin/Editör olduğunuz bir şirket yok.'));
        }

        final companies = snapshot.data!;

        // pending olan var mı?
        final hasPending = companies.any((c) => c['status'] == 'pending');

        // aktif şirketleri filtrele
        final activeCompanies = companies
            .where((c) => c['status'] != 'pending')
            .toList();

        // pending yoksa ve sadece 1 aktif varsa: direk yönlendir
        if (!hasPending && activeCompanies.length == 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            navigateToCompany(activeCompanies[0]);
          });
          return const Center(child: CircularProgressIndicator());
        }

        // Diğer tüm durumlarda listeyi göster
        return ListView.builder(
          itemCount: companies.length,
          itemBuilder: (context, index) {
            final company = companies[index];
            final isPending = company['status'] == 'pending';

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: isPending ? Colors.orange[100] : Colors.blueGrey[50],
                child: Icon(
                  isPending ? Icons.access_time : Icons.apartment,
                  color: isPending ? Colors.orange : Colors.blueGrey,
                ),
              ),
              title: Text(company['name'] ?? 'No name'),
              subtitle: Text(
                isPending
                    ? 'Role: ${company['role']} (Pending)'
                    : 'Role: ${company['role']}',
              ),
              onTap: isPending
                  ? null // pending ise tıklanamaz
                  : () => navigateToCompany(company),
            );
          },
        );
      },
    );
  }
}
