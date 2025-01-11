import 'package:flutter/material.dart';
import 'package:seaofsea/vievs/forgot_password.dart';
import 'package:seaofsea/vievs/login_page.dart';
import 'package:seaofsea/vievs/register_page.dart';

enum AuthMode { login, register, forgotPassword, none }

class AuthPage extends StatelessWidget {
  final AuthMode mode;

  const AuthPage({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    switch (mode) {
      case AuthMode.login:
        return const LoginPage(); // Login sayfası
      case AuthMode.register:
        return const RegisterPage(); // Register sayfası
      case AuthMode.forgotPassword:
        return const ForgotPassword();
      default:
        return const Scaffold(
          body: Center(
            child: Text('Invalid mode!'),
          ),
        ); // Geçersiz bir durum
    }
  }
}
