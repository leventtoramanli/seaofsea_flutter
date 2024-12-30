import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/quotes.dart';
import 'package:seaofsea/utils/theme_data.dart';
import 'package:seaofsea/utils/theme_provider.dart';
import 'package:seaofsea/vievs/auth_page.dart';
import 'package:seaofsea/vievs/register_page.dart';
import 'package:seaofsea/vievs/terms.dart';
import 'package:seaofsea/widgets/custom_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  bool _rememberMe = false;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  final randomQuote = Quotes.getRandomQuote();

  bool wideScreen = false;
  double exWidth = 0.0;
  @override
  void dispose() {
    nameController.dispose();
    surnameController.dispose();
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
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dialog'u kapat
                Navigator.pushReplacementNamed(context, '/');
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    exWidth = MediaQuery.of(context).size.width * 0.6;
    if (exWidth < 650) {
      wideScreen = false;
    } else {
      wideScreen = true;
    }

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
      body: wideScreen
          ? Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      insImage(),
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
                  page(themeProvider, fields, context)
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!wideScreen) insImage(),
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
                        child: formTField(
                          field['controller'],
                          themeProvider,
                          field['label'],
                          field['hint'],
                          field['icon'],
                          field['validationMessage'],
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
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _rememberMe = !_rememberMe;
                                });
                              },
                              child: const Text(
                                'Remember me',
                                style: TextStyle(fontSize: 14.0),
                              ),
                            ),
                          ],
                        ),
                      ),
                      CustomButton(
                        label: 'Login',
                        onPressed: () {
                          // Login işlemi
                        },
                        icon: Icons.login,
                        isLoading: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () {
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
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterPage(),
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
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CustomButton(
                        label: 'Sign In Anonymously',
                        onPressed: () {},
                        icon: Icons.theater_comedy,
                        backgroundColor: Colors.amber.shade400,
                        textColor: Colors.black,
                      ),
                      const SizedBox(height: 12.0),
                      CustomButton(
                        label: 'Sign In with Google',
                        onPressed: () {},
                        icon: Icons.g_mobiledata,
                        backgroundColor: Colors.red.shade400,
                        textColor: Colors.white,
                      ),
                      const SizedBox(height: 12.0),
                      CustomButton(
                        label: 'Sign Up',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AuthPage(mode: AuthMode.register),
                            ),
                          );

                          /*Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterPage(),
                            ),
                          );*/
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
    );
  }

  Center insImage() {
    double imgSize = 150;
    wideScreen ? imgSize = 300 : imgSize = 150;
    return Center(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 12,
              offset: Offset(0, 0),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          clipBehavior: Clip.antiAlias,
          child: FadeInImage.assetNetwork(
              placeholder: 'asssets/placeholder.png',
              image: 'assets/logo.png',
              height: imgSize,
              width: imgSize,
              fit: BoxFit.cover),

          /*Image(
            image: const AssetImage('assets/logo.png'),
            height: imgSize,
          ),*/
        ),
      ),
    );
  }

  Widget formTField(
      TextEditingController controller,
      ThemeProvider themeProvider,
      String label,
      String hint,
      Icon icon,
      String turner,
      {bool isPassword = false,
      bool isEmail = false}) {
    bool obsText = isPassword;

    return StatefulBuilder(builder: (context, setState) {
      return TextFormField(
        controller: controller,
        obscureText: obsText,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon,
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(obsText ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      obsText = !obsText;
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: themeProvider.isDarkMode
              ? Colors.grey.shade800
              : Colors.grey.shade200,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: themeProvider.isDarkMode
                    ? Colors.blueGrey.shade200
                    : Colors.blueGrey.shade400),
            borderRadius: BorderRadius.circular(10.0),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.red),
            borderRadius: BorderRadius.circular(10.0),
          ),
          border: OutlineInputBorder(
            borderSide: BorderSide(
                color: themeProvider.isDarkMode ? Colors.white : Colors.black),
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return turner;
          } else if (isPassword && value.length < 6) {
            return 'Password must be at least 6 characters';
          } else if (isEmail &&
              !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
            return 'Please enter a valid email';
          }
          return null;
        },
      );
    });
  }
}
