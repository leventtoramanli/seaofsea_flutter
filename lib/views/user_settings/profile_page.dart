// ignore_for_file: library_private_types_in_public_api, prefer_final_fields
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/api_manager.dart';
// ignore: unused_import
import 'package:seaofsea/utils/auth_provider.dart';
import 'package:seaofsea/views/companies/company_admin_page.dart';
import 'package:seaofsea/views/user_settings/edit_cv_page.dart';
import 'package:seaofsea/views/user_settings/profile_general_tab.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _surnameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _bioController = TextEditingController();
  Map<String, dynamic> infoData = {};
  bool isUpdating = false;

  bool hasCompanyAdminOrEditor = false;
  bool multipleCompanies = false;

  Future<void> fetchUserData() async {
    final apiManager = Provider.of<ApiManager>(context, listen: false);
    try {
      final response = await apiManager.get(context, 'get_user_info');

      if (response != null && response['success'] == true) {
        if (mounted) {
          setState(() {
            infoData = response['data'] ?? {};
            _nameController.text = infoData['name'] ?? '';
            _surnameController.text = infoData['surname'] ?? '';
            _emailController.text = infoData['email'] ?? '';
            _bioController.text = infoData['bio'] ?? '';
          });
        }
      } else {
        debugPrint(
            '❌ API Hatası: ${response?['message'] ?? 'Bilinmeyen hata'}');
      }
    } catch (e, stacktrace) {
      debugPrint('❌ API Hatası: $e');
      debugPrint(stacktrace.toString());
    }
  }

  Future<void> checkUserCompanies() async {
    final api = Provider.of<ApiManager>(context, listen: false);
    final response = await api.post(context, 'get_user_companies', {});

    if (response != null && response['success'] == true) {
      final companies = response['data'] as List<dynamic>? ?? [];
      final adminEditorCompanies = companies
          .where((company) =>
              company['role'] == 'admin' || company['role'] == 'editor')
          .toList();

      if (adminEditorCompanies.isNotEmpty) {
        setState(() {
          hasCompanyAdminOrEditor = true;
          multipleCompanies = adminEditorCompanies.length > 1;
        });
      }
    }
  }

  Future<void> updateUserData() async {
    setState(() => isUpdating = true);
    final apiManager = Provider.of<ApiManager>(context, listen: false);
    final response = await apiManager.post(context, 'update_user', {
      'user_id': infoData['id'],
      'name': _nameController.text,
      'surname': _surnameController.text,
      'email': _emailController.text,
      'bio': _bioController.text,
    });
    setState(() => isUpdating = false);
    if (response != null && response['success'] == true) {
      await fetchUserData();
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully!")),
      );
    } else {
      debugPrint(
          "❌ Güncelleme başarısız: ${response?['message'] ?? 'Unknown Error'}");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUserData();
    checkUserCompanies();
  }

  @override
  Widget build(BuildContext context) {
    final List<Tab> menuTabs = [
      Tab(icon: Icon(Icons.person), text: 'General'),
      Tab(icon: Icon(Icons.description), text: 'CV'),
    ];

    final List<Widget> menuViews = [
      ProfileGeneralTab(),
      EditCVPage(),
    ];

    if (hasCompanyAdminOrEditor) {
      final icon = multipleCompanies ? Icons.business : Icons.apartment;
      final label = multipleCompanies ? 'Companies' : 'Company';
      menuTabs.add(Tab(icon: Icon(icon), text: label));
      menuViews.add(const CompanyAdminPage());
    }
    return DefaultTabController(
      length: menuTabs.length,
      child: Column(
        children: [
          TabBar(tabs: menuTabs),
          Expanded(
            child: TabBarView(children: menuViews),
          ),
        ],
      ),
    );
  }
}
