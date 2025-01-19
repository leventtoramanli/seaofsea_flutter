import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/auth_provider.dart';
import 'package:seaofsea/services/routes.dart';

class MenuItemsProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _menuItems = [
    {
      'icon': Icons.settings,
      'label': 'Settings',
      'actionKey': 'settings',
      'order': 200,
    },
    {
      'icon': Icons.home,
      'label': 'Home',
      'actionKey': 'home',
      'order': 300,
    },
  ];

  final Map<String, Function(BuildContext)> _actionHandlers = {
    'settings': (context) => navigateReplacement(context, '/settings'),
    'home': (context) => navigateReplacement(context, '/home'),
    'logout': (context) {
      final authProvider =
          Provider.of<AuthProvider>(context, listen: false);
      authProvider.logout(context);
      navigateReplacement(context, '/');
    },
    'profile': (context) => debugPrint('Profile tapped'),
    'help': (context) => debugPrint('Help tapped'),
  };

  List<Map<String, dynamic>> getMenuItems(BuildContext context) {
    return _menuItems.map((item) {
      return {
        ...item,
        'onTap': () {
          final actionKey = item['actionKey'];
          if (_actionHandlers.containsKey(actionKey)) {
            _actionHandlers[actionKey]!(context);
          } else {
            debugPrint('No handler for $actionKey');
          }
        },
      };
    }).toList()
      ..sort((a, b) => b['order'].compareTo(a['order']));
  }

  Future<void> loadDynamicMenuItems() async {
    final dynamicItems = [
      {
        'icon': Icons.logout,
        'label': 'Logout',
        'actionKey': 'logout',
        'order': 100,
      },
      {
        'icon': Icons.person,
        'label': 'Profile',
        'actionKey': 'profile',
        'order': 201,
      },
      {
        'icon': Icons.help,
        'label': 'Help',
        'actionKey': 'help',
        'order': 102,
      },
    ];

    _menuItems.addAll(dynamicItems);
    notifyListeners();
  }
}
