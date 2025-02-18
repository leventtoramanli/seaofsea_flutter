import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/api_manager.dart';
import 'package:seaofsea/utils/quotes.dart';
import 'package:seaofsea/utils/theme_data.dart';
import 'package:seaofsea/utils/theme_provider.dart';
import 'package:seaofsea/views/terms.dart';
import 'package:seaofsea/widgets/custom_app_bar.dart';
import 'package:seaofsea/widgets/custom_button.dart';
import 'package:seaofsea/widgets/custom_form_field.dart';
import 'package:seaofsea/widgets/ins_image.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  bool _termsAccepted = false;
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

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    final apiManager = Provider.of<ApiManager>(context, listen: false);

    if (!_termsAccepted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Terms Not Accepted'),
          content: const Text(
              'You must accept the Terms and Conditions to register.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final response = await apiManager
          .request(context, endpoint: 'register', method: 'POST', body: {
        'name': nameController.text,
        'surname': surnameController.text,
        'email': emailController.text,
        'password': passwordController.text
      });

      if (response['success']) {
        _showEmailVerificationDialog();
      }
    } catch (e) {
      debugPrint('Error during registration: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
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
        'controller': nameController,
        'label': 'Name',
        'hint': 'Enter your name',
        'icon': const Icon(Icons.person),
        'validationMessage': 'Please enter your name',
      },
      {
        'controller': surnameController,
        'label': 'Surname',
        'hint': 'Enter your surname',
        'icon': const Icon(Icons.person),
        'validationMessage': 'Please enter your surname',
      },
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
      appBar: MyAppBar(title: 'Register'),
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
                  if (!wideScreen) InsImage(wideScreen: wideScreen),
                  const SizedBox(height: 16.0),
                  const Center(
                    child: Text(
                      'Register Form',
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
                        padding: const EdgeInsets.only(bottom: 12.0),
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
                  CheckboxListTile(
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _termsAccepted,
                    onChanged: (value) {
                      setState(() {
                        _termsAccepted = value ?? false;
                      });
                    },
                    title: const Text(
                      'I accept the Terms and Conditions',
                      style: TextStyle(fontSize: 14.0),
                    ),
                    subtitle: InkWell(
                      onTap: () {
                        // Terms and Conditions sayfasına yönlendirme
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Terms(),
                          ),
                        );
                      },
                      child: const Text(
                        'Read Terms and Conditions',
                        style: TextStyle(
                          fontSize: 14.0,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CustomButton(
                          label: 'Login',
                          icon: Icons.turn_left,
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                          onPressed: () {
                            Navigator.pop(context);
                          }),
                      const SizedBox(width: 16.0),
                      Expanded(
                        child: CustomButton(
                          isLoading: isLoading,
                          label: 'Register',
                          backgroundColor: Colors.green,
                          textColor: Colors.white,
                          onPressed: _handleRegister,
                        ),
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
}
