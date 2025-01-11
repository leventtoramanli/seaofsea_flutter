import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:seaofsea/utils/api_manager.dart';
import 'package:seaofsea/utils/auth_provider.dart';
import 'package:seaofsea/utils/color_blindness_provider.dart';
import 'package:seaofsea/utils/role_provider.dart';
import 'package:seaofsea/utils/theme_provider.dart';

List<SingleChildWidget> providers = [
  ChangeNotifierProvider(create: (_) => RoleProvider()),
  ChangeNotifierProvider(create: (_) => LoadingProvider()),
  ChangeNotifierProvider(create: (_) => ThemeProvider()),
  ChangeNotifierProvider(create: (_) => AuthProvider()),
  ChangeNotifierProvider(create: (_) => ColorBlindnessProvider()),
  ProxyProvider<AuthProvider, ApiManager>(
    update: (context, authProvider, apiManager) =>
        ApiManager(authProvider.token),
  ),
];
