import 'package:flutter/material.dart';
import 'package:seaofsea/utils/theme_provider.dart';

class CustomFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String validationMessage;
  final bool isPassword;
  final bool isEmail;

  const CustomFormField({
    Key? key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.validationMessage,
    this.isPassword = false,
    this.isEmail = false, required ThemeProvider themeProvider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool obsText = isPassword;

    return StatefulBuilder(
      builder: (context, setState) {
        return TextFormField(
          controller: controller,
          obscureText: isPassword ? obsText : false,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(icon),
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
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return validationMessage;
            } else if (isEmail &&
                !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
              return 'Please enter a valid email';
            } else if (isPassword && value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        );
      },
    );
  }
}
