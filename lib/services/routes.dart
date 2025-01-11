import 'package:flutter/material.dart';
import 'package:seaofsea/main.dart';
import 'package:seaofsea/vievs/admin_dashboard.dart';
import 'package:seaofsea/vievs/auth_page.dart';
import 'package:seaofsea/vievs/home_page.dart';

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
    default:
      return MaterialPageRoute(
          builder: (context) => const Center(
                child: Text('Page not found'),
              ));
  }
}