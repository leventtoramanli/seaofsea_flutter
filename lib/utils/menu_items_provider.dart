import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/auth_provider.dart';
import 'package:seaofsea/services/routes.dart';

/// Menü öğelerini daha okunabilir hale getirmek için model sınıfı
class MenuItemModel {
  final IconData icon;
  final String label;
  final String actionKey;
  final int order;
  final Function(BuildContext)? onTap;

  MenuItemModel({
    required this.icon,
    required this.label,
    required this.actionKey,
    required this.order,
    this.onTap,
  });
}

class MenuItemsProvider extends ChangeNotifier {
  final List<MenuItemModel> _menuItems = [
    MenuItemModel(
      icon: Icons.settings,
      label: 'Settings',
      actionKey: 'settings',
      order: 200,
    ),
    MenuItemModel(
      icon: Icons.home,
      label: 'Home',
      actionKey: 'home',
      order: 300,
    ),
  ];

  /// Menü eylemlerini yöneten fonksiyon
  void handleMenuAction(BuildContext context, String actionKey) {
    final Map<String, Function(BuildContext)> actionHandlers = {
      'settings': (context) => navigateReplacement(context, '/settings'),
      'home': (context) => navigateReplacement(context, '/home'),
      'logout': (context) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        authProvider.logout(context);
        navigateReplacement(context, '/');
      },
      'profile': (context) => debugPrint('Profile tapped'),
      'help': (context) => debugPrint('Help tapped'),
    };

    if (actionHandlers.containsKey(actionKey)) {
      actionHandlers[actionKey]!(context);
    } else {
      debugPrint('No handler for $actionKey');
    }
  }

  /// Menü öğelerini döndürür ve `onTap` işlemlerini ekler
  List<MenuItemModel> getMenuItems(BuildContext context) {
    return _menuItems.map((item) {
      return MenuItemModel(
        icon: item.icon,
        label: item.label,
        actionKey: item.actionKey,
        order: item.order,
        onTap: (ctx) => handleMenuAction(ctx, item.actionKey),
      );
    }).toList()
      ..sort((a, b) => b.order.compareTo(a.order));
  }

  /// Dinamik menü öğelerini yükler
  void loadDynamicMenuItems() {
    final dynamicItems = [
      MenuItemModel(
        icon: Icons.logout,
        label: 'Logout',
        actionKey: 'logout',
        order: 100,
      ),
      MenuItemModel(
        icon: Icons.person,
        label: 'Profile',
        actionKey: 'profile',
        order: 201,
      ),
      MenuItemModel(
        icon: Icons.help,
        label: 'Help',
        actionKey: 'help',
        order: 102,
      ),
    ];

    _menuItems.addAll(dynamicItems);
    notifyListeners();
  }
}
