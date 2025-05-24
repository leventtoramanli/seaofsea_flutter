import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:seaofsea/utils/theme_provider.dart';

class CustomFormField extends StatelessWidget {
  final TextEditingController controller;
  final ThemeProvider themeProvider;
  final String label;
  final String hint;
  final Icon icon;
  final String? validationMessage;
  final bool isPassword;
  final bool isEmail;
  final bool isNumeric;
  final bool isDate;
  final bool isPhone;
  final bool isUrl;
  final BuildContext? context;
  final int maxLines;
  final bool isRequired;
  final VoidCallback? onFieldSubmitted;
  final bool showField;

  const CustomFormField({
    super.key,
    required this.controller,
    required this.themeProvider,
    required this.label,
    required this.hint,
    required this.icon,
    this.validationMessage,
    this.isPassword = false,
    this.isEmail = false,
    this.isNumeric = false,
    this.isDate = false,
    this.isPhone = false,
    this.isUrl = false,
    this.context,
    this.maxLines = 1,
    this.isRequired = true,
    this.onFieldSubmitted,
    this.showField = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!showField) return const SizedBox.shrink();
    bool obsText = isPassword;

    return StatefulBuilder(
      builder: (context, setState) {
        return TextFormField(
          controller: controller,
          obscureText: obsText,
          readOnly: isDate, // Tarih seçimi için klavye kapatılır
          onTap: isDate
              ? () async {
                  final selectedDate = await showDatePicker(
                    context: this.context!,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (selectedDate != null) {
                    controller.text =
                        DateFormat('yyyy-MM-dd').format(selectedDate);
                  }
                }
              : null,
          keyboardType: isEmail
              ? TextInputType.emailAddress
              : isPhone
                  ? TextInputType.numberWithOptions(signed: true)
                  : isNumeric
                      ? TextInputType.number
                      : TextInputType.text,
          textInputAction: TextInputAction.next,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: icon,
            suffixIcon: isPassword
                ? IconButton(
                    icon:
                        Icon(obsText ? Icons.visibility : Icons.visibility_off),
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
                  color:
                      themeProvider.isDarkMode ? Colors.white : Colors.black),
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          inputFormatters: isNumeric
              ? [FilteringTextInputFormatter.digitsOnly]
              : isPhone
                  ? [FilteringTextInputFormatter.digitsOnly]
                  : null,
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return validationMessage;
            } else if (isPassword && value!.length < 6) {
              return 'Password must be at least 6 characters';
            } else if (isEmail &&
                !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value!)) {
              return 'Please enter a valid email';
            } else if (isPhone &&
                !RegExp(r'^\+?[0-9]{7,15}$').hasMatch(value!)) {
              return 'Please enter a valid phone number';
            } else if (isUrl &&
                !RegExp(r'^(https?:\/\/)?([\w\-]+\.)+[\w\-]{2,}(\/[\w\-]*)*\/?$')
                    .hasMatch(value!)) {
              return 'Please enter a valid website URL';
            }
            return null;
          },
        );
      },
    );
  }
}
