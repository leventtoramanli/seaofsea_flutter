// ignore_for_file: library_private_types_in_public_api, prefer_final_fields, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/services/v1/v1_api_manager.dart';
// import 'package:seaofsea/views/companies/company_admin_page.dart';
import 'package:seaofsea/views/user_settings/edit_cv_page.dart';
import 'package:seaofsea/views/user_settings/profile_general_tab.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  Map<String, dynamic> infoData = {};
  bool isUpdating = false;

  // Company admin/editor sekmesini daha sonra açarsak uzunluklar eşleşsin diye
  bool hasCompanyAdminOrEditor = false;
  bool multipleCompanies = false;

  @override
  void initState() {
    super.initState();
    fetchUserData();
    // checkUserCompanies(); // ileride açılacaksa, alt tarafta tabView da eklemeyi unutma
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> fetchUserData() async {
    final apiManager = Provider.of<V1ApiManager>(context, listen: false);
    try {
      final response = await apiManager.call(
        module: 'profile',
        action: 'getProfile',
      );

      if (response['success'] == true) {
        if (!mounted) return;
        setState(() {
          infoData = response['data'] ?? {};
          _nameController.text = infoData['name']?.toString() ?? '';
          _surnameController.text = infoData['surname']?.toString() ?? '';
          _emailController.text = infoData['email']?.toString() ?? '';
          _bioController.text = infoData['bio']?.toString() ?? '';
        });
      } else {
        debugPrint('API error: ${response['message'] ?? 'Unknown error'}');
      }
    } catch (e, st) {
      debugPrint('API error: $e');
      debugPrint(st.toString());
    }
  }

  Future<void> updateUserData() async {
    setState(() => isUpdating = true);
    final apiManager = Provider.of<V1ApiManager>(context, listen: false);

    final response = await apiManager.call(
      module: 'user',
      action: 'update_user',
      params: {
        'user_id': infoData['id'],
        'name': _nameController.text,
        'surname': _surnameController.text,
        'email': _emailController.text,
        'bio': _bioController.text,
      },
    );

    if (!mounted) return;
    setState(() => isUpdating = false);

    if (response['success'] == true) {
      await fetchUserData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } else {
      debugPrint('Update failed: ${response['message'] ?? 'Unknown error'}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(response['message']?.toString() ?? 'Update failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;

    // Sekme listesi ve görünümleri (mutlaka aynı uzunlukta kalmalı!)
    final List<Tab> tabs = <Tab>[
      const Tab(icon: Icon(Icons.person), text: 'General'),
      const Tab(icon: Icon(Icons.description), text: 'CV'),
    ];

    final List<Widget> views = <Widget>[
      // ProfileGeneralTab kendi içinde Theme.of(context) ile tema alıyor
      const ProfileGeneralTab(),
      const EditCVPage(),
    ];

    // İleride company admin/editor sekmesini açarsan, hem tab hem view ekle:
    // if (hasCompanyAdminOrEditor) {
    //   final icon = multipleCompanies ? Icons.business : Icons.apartment;
    //   final label = multipleCompanies ? 'Companies' : 'Company';
    //   tabs.add(Tab(icon: Icon(icon), text: label));
    //   views.add(const CompanyAdminPage());
    // }

    // Tema uyumlu TabBar: yüksek kontrast için renkleri açıkça veriyoruz
    final tabBar = TabBar(
      isScrollable: false,
      indicatorColor: c.primary,
      labelColor: c.primary,
      unselectedLabelColor:
          theme.brightness == Brightness.dark ? Colors.white70 : Colors.black87,
      tabs: tabs,
    );

    return DefaultTabController(
      length: tabs.length,
      child: Column(
        children: [
          // TabBar’ı yüzey rengi üzerinde göster, hem light hem dark’ta kontrast korunsun
          Material(
            color: theme.colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: tabBar,
            ),
          ),
          // İnce ayırıcı çizgi
          Divider(
            height: 1,
            color: theme.dividerColor.withAlpha(90),
          ),
          // İçerik
          Expanded(
            child: Stack(
              children: [
                TabBarView(children: views),
                if (isUpdating)
                  Container(
                    color: Colors.black.withAlpha(15),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),
          // İstersen profil değişikliklerini bu sayfadan kaydetmek için bir buton ekleyebilirsin:
          // Padding(
          //   padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          //   child: SizedBox(
          //     width: double.infinity,
          //     child: FilledButton.icon(
          //       onPressed: isUpdating ? null : updateUserData,
          //       icon: const Icon(Icons.save),
          //       label: const Text('Save changes'),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
