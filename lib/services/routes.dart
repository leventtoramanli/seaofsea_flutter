import 'package:flutter/material.dart';
import 'package:seaofsea/main.dart';
import 'package:seaofsea/vievs/admin_dashboard.dart';
import 'package:seaofsea/vievs/auth/auth_page.dart';
import 'package:seaofsea/vievs/home_page.dart';
import 'package:seaofsea/vievs/user_settings/settings_page.dart';

Route<dynamic>? generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/':
      return MaterialPageRoute(builder: (context) => const MainPage());
    case '/login':
      return MaterialPageRoute(
          builder: (context) => const AuthPage(mode: AuthMode.login));
    case '/register':
      return MaterialPageRoute(
          builder: (context) => const AuthPage(mode: AuthMode.register));
    case '/home':
      return MaterialPageRoute(builder: (context) => const HomePage());
    case '/admin':
      return MaterialPageRoute(builder: (context) => const AdminDashboard());
    case '/settings':
      return MaterialPageRoute(builder: (context) => const SettingsPage());
    default:
      return MaterialPageRoute(
          builder: (context) => const Center(
                child: Text('Page not found'),
              ));
  }
}

void navigateReplacement(BuildContext context, String routeName,
    {Object? arguments}) {
  Navigator.of(context).pushReplacement(
    generateRoute(RouteSettings(name: routeName, arguments: arguments))!,
  );
}
