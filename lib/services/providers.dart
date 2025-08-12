import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:seaofsea/services/v1/v1_api_manager.dart';
import 'package:seaofsea/utils/api_manager.dart';
import 'package:seaofsea/utils/auth_provider.dart';
import 'package:seaofsea/utils/color_blindness_provider.dart';
import 'package:seaofsea/utils/dynamic_file_provider.dart';
import 'package:seaofsea/utils/menu_items_provider.dart';
import 'package:seaofsea/utils/permission_provider.dart';
import 'package:seaofsea/utils/role_provider.dart';
import 'package:seaofsea/utils/theme_provider.dart';

List<SingleChildWidget> providers = [
  ChangeNotifierProvider(create: (_) => RoleProvider()),
  ChangeNotifierProvider(create: (_) => LoadingProvider()),
  ChangeNotifierProvider(create: (_) => ThemeProvider()),
  ChangeNotifierProvider(create: (_) => AuthProvider()),
  ChangeNotifierProvider(create: (_) => ColorBlindnessProvider()),
  ChangeNotifierProvider(create: (_) => MenuItemsProvider()..loadDynamicMenuItems()),
  ChangeNotifierProvider(create: (_) => DynamicFieldProvider()),
  ChangeNotifierProvider(create: (_) => PermissionProvider()),
  ProxyProvider<AuthProvider, ApiManager>(
    update: (context, authProvider, apiManager) =>
        ApiManager(authProvider.token),
  ),
  Provider<V1ApiManager>(
    create: (_) => V1ApiManager(),
  ),
];
