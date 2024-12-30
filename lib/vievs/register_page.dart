import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/api_manager.dart';
import 'package:seaofsea/utils/theme_data.dart';
import 'package:seaofsea/utils/theme_provider.dart';
import 'package:seaofsea/vievs/terms.dart';
import 'package:seaofsea/widgets/custom_button.dart';

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
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: Center(
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
                    Center(
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
                          child: const Image(
                            image: AssetImage('assets/logo.png'),
                            height: 150,
                          ),
                        ),
                      ),
                    ),
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
                    const SizedBox(height: 24.0),
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
                    Center(
                      child: CustomButton(
                        isLoading: isLoading,
                        label: 'Register',
                        onPressed: () async {
                          
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              isLoading = true;
                            });
                            final api =
                                Provider.of<ApiManager>(context, listen: false);
                            if (!_termsAccepted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please accept the terms.'),
                              ),
                            );
                            isLoading = false;
                            return;
                          }

                            try {
                              final response = await api.createUser(
                                context,
                                {
                                  'name': nameController.text,
                                  'surname': surnameController.text,
                                  'email': emailController.text,
                                  'password': passwordController.text,
                                },
                              );
                              print(response);
                              if (response['success'] == true) {
                                _showEmailVerificationDialog();
                              }
                            } catch (e) {
                              print('Error: $e');
                            } finally {
                              setState(() {
                                isLoading = false;
                              });
                            }
                          }
                        },
                      ),
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
