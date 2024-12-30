import 'package:flutter/material.dart';
import 'package:seaofsea/vievs/login_page.dart';
import 'package:seaofsea/vievs/register_page.dart';

enum AuthMode { login, register }

class AuthPage extends StatelessWidget {
  final AuthMode mode;

  const AuthPage({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    Widget content;

    // Enum moduna göre sayfaları seçiyoruz
    switch (mode) {
      case AuthMode.login:
        content = const LoginPage(); // Mevcut LoginPage'i bağladık
        break;
      case AuthMode.register:
        content = const RegisterPage(); // Mevcut RegisterPage'i bağladık
        break;
      default:
        content = const Center(child: Text('Invalid mode'));
    }

    return content;
  }
}
