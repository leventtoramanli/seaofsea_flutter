import 'package:flutter/material.dart';
import 'package:seaofsea/vievs/user_settings/profile_page.dart';
import 'package:seaofsea/widgets/custon_scaffold.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> menuLabels = [
    'Profile',
    'Notifications',
    'Theme',
    'Language',
    'Privacy',
    'Logout',
  ];

  final List<IconData> menuIcons = [
    Icons.person,
    Icons.notifications,
    Icons.color_lens,
    Icons.language,
    Icons.lock,
    Icons.logout,
  ];

  final List<Widget> contentWidgets = [
    const ProfilePage(),
    const NotificationsForm(),
    const ThemeSettings(),
    const LanguageSettings(),
    const PrivacySettings(),
    const LogoutScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: menuLabels.length, vsync: this);
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
              _tabController.index = index;
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

class NotificationsForm extends StatelessWidget {
  const NotificationsForm({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Notification Settings'));
  }
}

class ThemeSettings extends StatelessWidget {
  const ThemeSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Theme Settings'));
  }
}

class LanguageSettings extends StatelessWidget {
  const LanguageSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Language Settings'));
  }
}

class PrivacySettings extends StatelessWidget {
  const PrivacySettings({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Privacy and Security'));
  }
}

class LogoutScreen extends StatelessWidget {
  const LogoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Logout Screen'));
  }
}
