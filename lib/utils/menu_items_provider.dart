import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/auth_provider.dart';
import 'package:seaofsea/services/routes.dart';
import 'package:seaofsea/utils/permission_provider.dart';

/// Menü öğelerini daha okunabilir hale getirmek için model sınıfı
class MenuItemModel {
  final IconData icon;
  final String label;
  final String actionKey;
  final int order;
  final Function(BuildContext)? onTap;
  final String? permissionCode;

  MenuItemModel({
    required this.icon,
    required this.label,
    required this.actionKey,
    required this.order,
    this.onTap,
    this.permissionCode,
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
      'logout': (context) async {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.v1logout();
        if (context.mounted) {
          navigateReplacement(context, '/');
        }
      },
      'profile': (context) {
        navigateReplacement(context, '/public_profile_page');
      },
      'help': (context) => debugPrint('Help tapped'),
      'perm_debug': (context) => navigateReplacement(context, '/perm_debug'),
      'admin': (context) => navigateReplacement(context, '/admin'),
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
        permissionCode: null,
      ),
      MenuItemModel(
        icon: Icons.person,
        label: 'Profile',
        actionKey: 'profile',
        order: 201,
        permissionCode: 'profile.view',
      ),
      MenuItemModel(
        icon: Icons.help,
        label: 'Help',
        actionKey: 'help',
        order: 102,
        permissionCode: null,
      ),
      MenuItemModel(
        icon: Icons.admin_panel_settings,
        label: 'Admin Panel',
        actionKey: 'admin',
        order: 50,
        permissionCode: 'admin.access',
      ),
      //---------------------------TEST TEST TEST--------------------------------
      MenuItemModel(
        icon: Icons.lock_open,
        label: 'Perm Debug',
        actionKey: 'perm_debug',
        order: 999,
        permissionCode: null,
      ),
    ];

    _menuItems.addAll(dynamicItems);
    notifyListeners();
  }

  List<MenuItemModel> getVisibleMenuItems(BuildContext context) {
    final permissionProvider =
        Provider.of<PermissionProvider>(context, listen: false);

    return _menuItems.where((item) {
      if (item.permissionCode == null) return true;
      return permissionProvider.can(item.permissionCode!);
    }).map((item) {
      return MenuItemModel(
        icon: item.icon,
        label: item.label,
        actionKey: item.actionKey,
        order: item.order,
        onTap: (ctx) => handleMenuAction(ctx, item.actionKey),
        permissionCode: item.permissionCode,
      );
    }).toList()
      ..sort((a, b) => b.order.compareTo(a.order));
  }
}
