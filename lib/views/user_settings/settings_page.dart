import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/auth_provider.dart';
import 'package:seaofsea/views/user_settings/language_settings.dart';
import 'package:seaofsea/views/user_settings/notificationforms.dart';
import 'package:seaofsea/views/user_settings/privacy_settings_page.dart';
import 'package:seaofsea/views/user_settings/profile_page.dart';
import 'package:seaofsea/widgets/custon_scaffold.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, Object? arguments});

  @override
  // ignore: library_private_types_in_public_api
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> menuLabels = [
    'Profile',
    'Notifications',
    'Language',
    'Privacy',
    'Logout',
  ];

  final List<IconData> menuIcons = [
    Icons.person,
    Icons.notifications,
    Icons.language,
    Icons.lock,
    Icons.logout,
  ];

  final List<Widget> contentWidgets = [
    const ProfilePage(),
    const NotificationsForm(),
    const LanguageSettings(),
    const PrivacySettings(),
    const LogoutScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: menuLabels.length, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {}); // ✅ `NavigationRail` için `setState()`
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return CustomScaffold(
      title: 'Settings',
      body: screenWidth > 650
          ? buildNavigationRailLayout(screenWidth)
          : buildTabBarLayout(),
    );
  }

  Widget buildNavigationRailLayout(double screenWidth) {
    return Row(
      children: [
        NavigationRail(
          selectedIndex: _tabController.index,
          onDestinationSelected: (index) {
            setState(() {
              _tabController.animateTo(index);
            });
          },
          labelType: NavigationRailLabelType.selected,
          destinations: List.generate(menuLabels.length, (index) {
            return NavigationRailDestination(
              icon: Icon(menuIcons[index]),
              selectedIcon: Icon(menuIcons[index], color: Colors.blue),
              label: Text(menuLabels[index]),
            );
          }),
        ),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: contentWidgets[_tabController.index],
          ),
        ),
      ],
    );
  }

  Widget buildTabBarLayout() {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: List.generate(menuLabels.length, (index) {
            return Tab(
              icon: Icon(menuIcons[index]),
              text: menuLabels[index],
            );
          }),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: contentWidgets,
          ),
        ),
      ],
    );
  }
}


class LogoutScreen extends StatelessWidget {
  const LogoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Are you sure you want to log out?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.v1logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
          
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.v1logout(allDevices: true);
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Log Out From All Devices', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
