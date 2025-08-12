// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/services/v1/user_service.dart';
import 'package:seaofsea/services/v1/v1_api_manager.dart';
import 'package:seaofsea/utils/auth_provider.dart';
import 'package:seaofsea/utils/quotes.dart';
import 'package:seaofsea/utils/secure_storage.dart';
import 'package:seaofsea/utils/theme_data.dart';
import 'package:seaofsea/utils/theme_provider.dart';
import 'package:seaofsea/views/auth/auth_page.dart';
import 'package:seaofsea/views/terms.dart';
import 'package:seaofsea/widgets/custom_app_bar.dart';
import 'package:seaofsea/widgets/custom_button.dart';
import 'package:seaofsea/widgets/custom_form_field.dart';
import 'package:seaofsea/widgets/ins_image.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController =
      TextEditingController(text: 'leventtoramanli@gmail.com');
  final TextEditingController passwordController =
      TextEditingController(text: '145326326lL');

  final SecureStorage secureStorage = SecureStorage();
  final randomQuote = Quotes.getRandomQuote();

  bool _loadingLogin = false;
  bool _loadingAnon  = false;
  bool get _busy => _loadingLogin || _loadingAnon;

  bool wideScreen = false;
  double exWidth = 0.0;
  bool rememberMe = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _showEmailVerificationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Registration Successful'),
          content: const Text(
              'Please verify your email address. A verification email has been sent to your email address.'),
          actions: [
            TextButton(onPressed: () {/* TODO: resend */}, child: const Text('Send Again')),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/');
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loadingLogin = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Eğer ilerde lazım olursa:
    // ignore: unused_local_variable
    final v1 = Provider.of<V1ApiManager>(context, listen: false);

    try {
      await secureStorage.writeSecureData('rememberMe', rememberMe.toString());

      final success = await authProvider.v1login(
        context,
        emailController.text.trim(),
        passwordController.text,
        rememberMe: rememberMe,
      );
      if (!success) return;

      // İstersen doğrulama diyaloğunu tekrar aktif et:
      // final userService = UserService();
      // final result = await userService.getProfile();
      // if (result['success'] == true) {
      //   final user = result['user'] ?? result['data'] ?? {};
      //   final isVerified = user['is_verified'] ?? 1;
      //   if (isVerified != 1) {
      //     _showEmailVerificationDialog();
      //     return;
      //   }
      // }

      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      debugPrint('❗ Login error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("An unexpected error occurred.")),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingLogin = false);
    }
  }

  Future<void> _handleAnonLogin() async {
    setState(() => _loadingAnon = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.v1anonymousLogin(context);
      if (success && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      debugPrint('❗ Anon login error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Anonymous sign-in failed.")),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingAnon = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: true);

    exWidth = MediaQuery.of(context).size.width * 0.6;
    wideScreen = exWidth >= 650;

    final List<Map<String, dynamic>> fields = [
      {
        'controller': emailController,
        'label': 'Email',
        'hint': 'Enter your email',
        'icon': const Icon(Icons.email),
        'validationMessage': 'Please enter a valid email',
        'isEmail': true,
      },
      {
        'controller': passwordController,
        'label': 'Password',
        'hint': 'Enter your password',
        'icon': const Icon(Icons.lock),
        'validationMessage': 'Password must be at least 6 characters',
        'isPassword': true,
      },
    ];

    return Scaffold(
      appBar: MyAppBar(title: 'Login'),
      body: wideScreen
          ? Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InsImage(wideScreen: wideScreen),
                      const SizedBox(height: 16.0),
                      Text(
                        randomQuote,
                        style: TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                          fontFamily: GoogleFonts.tangerine().fontFamily,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: exWidth * 0.1),
                  page(themeProvider, fields, context),
                ],
              ),
            )
          : page(themeProvider, fields, context),
    );
  }

  Center page(ThemeProvider themeProvider, List<Map<String, dynamic>> fields,
      BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400.0),
          padding: const EdgeInsets.all(16.0),
          margin: const EdgeInsets.all(16.0),
          decoration: themeProvider.isDarkMode
              ? getDarkBoxDecoration()
              : getLightBoxDecoration(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: AbsorbPointer( // tüm formu _busy iken kilitler
              absorbing: _busy,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!wideScreen) InsImage(wideScreen: wideScreen),
                    const SizedBox(height: 16.0),
                    const Center(
                      child: Text(
                        'Welcome Back!',
                        style: TextStyle(
                            fontSize: 24.0, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    ListView.builder(
                      itemCount: fields.length,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        final field = fields[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: CustomFormField(
                            controller: field['controller'],
                            themeProvider: themeProvider,
                            label: field['label'],
                            hint: field['hint'],
                            icon: field['icon'],
                            validationMessage: field['validationMessage'],
                            isPassword: field['isPassword'] ?? false,
                            isEmail: field['isEmail'] ?? false,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Checkbox(
                                value: rememberMe,
                                onChanged: _busy
                                    ? null
                                    : (value) {
                                        setState(() {
                                          rememberMe = value ?? false;
                                        });
                                      },
                              ),
                              const Flexible(
                                child: Text(
                                  'Remember me',
                                  style: TextStyle(fontSize: 14.0),
                                ),
                              ),
                            ],
                          ),
                        ),
                        CustomButton(
                          label: 'Login',
                          onPressed: _busy ? null : _handleLogin,
                          icon: Icons.login,
                          isLoading: _loadingLogin,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: InkWell(
                            onTap: _busy
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const Terms(),
                                      ),
                                    );
                                  },
                            child: const Text(
                              'Terms & Conditions',
                              style: TextStyle(
                                fontSize: 14.0,
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                        Flexible(
                          child: InkWell(
                            onTap: _busy
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const AuthPage(
                                            mode: AuthMode.forgotPassword),
                                      ),
                                    );
                                  },
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                fontSize: 14.0,
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CustomButton(
                          label: 'Sign In Anonymously',
                          onPressed: _busy ? null : _handleAnonLogin,
                          icon: Icons.theater_comedy,
                          backgroundColor: Colors.amber.shade400,
                          textColor: Colors.black,
                          isLoading: _loadingAnon,
                        ),
                        const SizedBox(height: 12.0),
                        CustomButton(
                          label: 'Sign In with Google',
                          onPressed: _busy ? null : () {},
                          icon: Icons.g_mobiledata,
                          backgroundColor: Colors.red.shade400,
                          textColor: Colors.white,
                        ),
                        const SizedBox(height: 12.0),
                        CustomButton(
                          label: 'Sign Up',
                          onPressed: _busy
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const AuthPage(mode: AuthMode.register),
                                    ),
                                  );
                                },
                          icon: Icons.app_registration,
                          backgroundColor: Colors.green.shade400,
                          textColor: Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
