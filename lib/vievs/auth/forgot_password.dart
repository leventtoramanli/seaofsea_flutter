import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/api_manager.dart';
import 'package:seaofsea/utils/quotes.dart';
import 'package:seaofsea/utils/secure_storage.dart';
import 'package:seaofsea/utils/theme_data.dart';
import 'package:seaofsea/utils/theme_provider.dart';
import 'package:seaofsea/vievs/auth/auth_page.dart';
import 'package:seaofsea/widgets/custom_app_bar.dart';
import 'package:seaofsea/widgets/custom_button.dart';
import 'package:seaofsea/widgets/custom_form_field.dart';
import 'package:seaofsea/widgets/ins_image.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController =
      TextEditingController(text: 'leventtoramanli@gmail.com');

  bool isLoading = false;
  final SecureStorage secureStorage = SecureStorage();
  final randomQuote = Quotes.getRandomQuote();

  bool wideScreen = false;
  double exWidth = 0.0;
  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  void _showEmailResetDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Password'),
          content: const Text(
              'Check your email address. A password reset email has been sent to your email address.'),
          actions: [
            TextButton(onPressed: () {}, child: Text('Send Again')),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AuthPage(mode: AuthMode.login),
                  ),
                );
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handlePasswordReset() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        final apiManager = Provider.of<ApiManager>(context, listen: false);
        final response = await apiManager.request(context,
            endpoint: 'reset_password_request',
            method: 'POST',
            body: {
              'email': emailController.text,
            });

        if (response['success']) {
          _showEmailResetDialog();
          debugPrint('Password reset email sent successfully.');
        }
      } catch (e) {
        debugPrint('Error during password reset: $e');
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: true);

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
    ];

    return Scaffold(
      appBar: MyAppBar(title: 'Reset Password'),
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
                      'Reset Password',
                      style: TextStyle(
                          fontSize: 24.0, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  ListView.builder(
                    itemCount: fields.length,
                    shrinkWrap: true,
                    //physics: const NeverScrollableScrollPhysics(),
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
                  const SizedBox(height: 12.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CustomButton(
                        label: 'Send Reset Password Email',
                        onPressed: () {isLoading ? null :
                          _handlePasswordReset();
                        },
                        icon: Icons.email,
                        isLoading: isLoading,
                        backgroundColor: Colors.blueGrey,
                        textColor: Colors.white,
                      ),
                      const SizedBox(height: 12.0),
                      CustomButton(
                        label: 'Turn Back',
                        onPressed: () { isLoading ? null :
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AuthPage(mode: AuthMode.login),
                            ),
                          );
                        },
                        icon: Icons.arrow_back,
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
}
