import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/auth_provider.dart';

class MenuItemsProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _menuItems = [
    {
      'icon': Icons.settings,
      'label': 'Settings',
      'onTap': () => print('Settings tapped'),
      'order': 200,
    },
    {
      'icon': Icons.home,
      'label': 'Home',
      'onTap': () => print('Home tapped'),
      'order': 300,
    },
  ];

  // Menü öğelerini sıralayarak döndür
  List<Map<String, dynamic>> getMenuItems(BuildContext context) {
    final AuthProvider authProvider =
        Provider.of<AuthProvider>(context, listen: false);

    return _menuItems.map((item) {
      if (item['label'] == 'Logout') {
        return {
          ...item,
          'onTap': item['onTap'] ?? () => authProvider.logout(context),
        };
      }
      return {
        ...item,
        'onTap': item['onTap'] ?? () => print('${item['label']} tapped'),
      };
    }).toList()
      ..sort((a, b) => b['order'].compareTo(a['order']));
  }

  Future<void> loadDynamicMenuItems() async {
    await Future.delayed(const Duration(seconds: 2));
    final dynamicItems = [
      {
        'icon': Icons.logout,
        'label': 'Logout',
        'onTap': null,
        'order': 100,
      },
      {
        'icon': Icons.person,
        'label': 'Profile',
        'onTap': () => print('Profile tapped'),
        'order': 201,
      },
      {
        'icon': Icons.help,
        'label': 'Help',
        'onTap': () => print('Help tapped'),
        'order': 102,
      },
    ];

    _menuItems.addAll(dynamicItems);
    notifyListeners();
  }
}
