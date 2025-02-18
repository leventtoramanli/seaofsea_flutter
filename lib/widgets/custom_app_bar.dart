import 'package:flutter/material.dart';
import 'package:seaofsea/utils/theme_selector.dart';

class MyAppBar extends AppBar {
  MyAppBar({
    super.key,
    String? title,
    List<String> hideIcons = const [],
    Color? backgroundColor,
    Map<String, VoidCallback>? overrideActions,
  }) : super(
          elevation: 4,
          title: Text('SeaOfSea - ${title ?? ""}'),
          backgroundColor: backgroundColor,
          actions: [
            if (overrideActions != null)
              ...overrideActions.entries.map(
                (entry) => IconButton(
                  icon: Icon(_getIconFromKey(entry.key)),
                  onPressed: entry.value,
                ),
              )
            else if (!hideIcons.contains('theme'))
              const ThemeSelector(),
          ],
        );

  static IconData _getIconFromKey(String key) {
    switch (key) {
      case 'settings':
        return Icons.settings;
      case 'logout':
        return Icons.exit_to_app;
      case 'profile':
        return Icons.person;
      default:
        return Icons.help_outline;
    }
  }
}

/*
class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<String> hideIcons;
  final Color? backgroundColor;
  final Map<String, VoidCallback>? overrideActions;

  const MyAppBar({
    super.key,
    this.title,
    this.hideIcons = const [],
    this.backgroundColor,
    this.overrideActions,
  });

  @override
  Widget build(BuildContext context) {
    AuthProvider authProvider =
        Provider.of<AuthProvider>(context, listen: false);
    final List<Map<String, dynamic>> defaultIcons = [
      {
        'name': '1',
        'icon': Icons.home,
        'tooltip': 'Home',
        'onTap': () => print('Home clicked')
      },
      {
        'name': '2',
        'icon': Icons.search,
        'tooltip': 'Search',
        'onTap': () => print('Search clicked')
      },
      {
        'name': '3',
        'icon': Icons.add,
        'tooltip': 'Add',
        'onTap': () => print('Add clicked')
      },
      {
        'name': '4',
        'icon': Icons.delete,
        'tooltip': 'Delete',
        'onTap': () => print('Delete clicked')
      },
      {
        'name': '5',
        'icon': Icons.logout,
        'tooltip': 'Logout',
        'onTap': () => authProvider.logout(context)
      },
    ];

    final bool wideScreen = MediaQuery.of(context).size.width > 650;
    final double exWidth = MediaQuery.of(context).size.width * 0.6;

    bool tWideScreen = false;

    if (exWidth < 650) {
      tWideScreen = false;
    } else {
      tWideScreen = true;
    }

    return AppBar(
      title: Text('SeaOfSea - ${title ?? ""}'),
      backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
      leading: !wideScreen
          ? Builder(
              builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer()))
          : null,
      actions: wideScreen
          ? [
              Row(
                children: [
                  ...defaultIcons
                      .where((icon) => !hideIcons.contains(icon['name']))
                      .expand((icon) {
                    final onTap =
                        overrideActions?[icon['name']] ?? icon['onTap'];
                    if (tWideScreen) {
                      // Hem ikonlar hem yazı görünür
                      return [
                        TextButton.icon(
                          onPressed: onTap,
                          icon: Icon(icon['icon'], color: Colors.white),
                          label: Text(
                            icon['tooltip'],
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        if (icon != defaultIcons.last)
                          const Text(
                            '|',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                      ];
                    } else {
                      // Sadece ikonlar görünür
                      return [
                        IconButton(
                          icon: Icon(icon['icon']),
                          tooltip: icon['tooltip'],
                          onPressed: onTap,
                        ),
                      ];
                    }
                  }).toList(),
                  const ThemeSelector(),
                ],
              ),
            ]
          : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}*/
