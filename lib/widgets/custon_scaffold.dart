import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/auth_provider.dart';
import 'package:seaofsea/utils/theme_selector.dart';

class CustomScaffold extends StatelessWidget {
  final String? title;
  final Widget? body;

  const CustomScaffold({
    super.key,
    this.title,
    this.body,
  });

  // Default liste (hem AppBar actions hem Drawer için kullanılacak)
  List<Map<String, dynamic>> menuItems(BuildContext context) {
    final AuthProvider authProvider = Provider.of<AuthProvider>(context, listen: false);

    return [
      {
        'icon': Icons.home,
        'label': 'Home',
        'onTap': () => print('Home tapped'),
      },
      {
        'icon': Icons.settings,
        'label': 'Settings',
        'onTap': () => print('Settings tapped'),
      },
      {
        'icon': Icons.logout,
        'label': 'Logout',
        'onTap': () => authProvider.logout(context), // AuthProvider ile logout
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bool wideScreen = MediaQuery.of(context).size.width > 650;
    final bool tWideScreen = MediaQuery.of(context).size.width > 850;

    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? ''),
        actions: [
          if (wideScreen)
            ...menuItems(context).expand((item) {
              return [
                if (tWideScreen)
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: item['onTap'],
                        icon: Icon(item['icon'], color: Colors.white),
                        label: Text(
                          item['label'],
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      if (item != menuItems(context).last) // Son öğe hariç ayraç ekle
                        const Text(
                          '|',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                    ],
                  )
                else
                  IconButton(
                    icon: Icon(item['icon']),
                    tooltip: item['label'],
                    onPressed: item['onTap'],
                  ),
              ];
            }),
          const ThemeSelector(),
        ],
      ),
      drawer: !wideScreen
          ? Drawer(
              child: ListView(
                children: [
                  const DrawerHeader(
                    decoration: BoxDecoration(color: Colors.blue),
                    child: Text(
                      'Menu',
                      style: TextStyle(color: Colors.white, fontSize: 24),
                    ),
                  ),
                  ...menuItems(context).map((item) {
                    return ListTile(
                      leading: Icon(item['icon']),
                      title: Text(item['label']),
                      onTap: item['onTap'],
                    );
                  }).toList(),
                ],
              ),
            )
          : null,
      body: body ?? const SizedBox.shrink(),
    );
  }
}
