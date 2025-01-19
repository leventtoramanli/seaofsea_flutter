/*import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:seaofsea/utils/theme_provider.dart';

class DynamicCustomForm extends StatelessWidget {
  final List<Map<String, dynamic>> config;

  const DynamicCustomForm({required this.config, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = ThemeProvider.of(context);
    final Map<String, TextEditingController> controllers = {};
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
    final Map<String, String?> dropdownValues = {};
    final Map<String, bool> checkboxValues = {};
    final Map<String, bool> switchValues = {};
    final Map<String, List<TextEditingController>> dynamicFieldControllers = {};

    List<Widget> formFields = [];

    for (var item in config) {
      if (item.containsKey('field')) {
        var field = item['field'];
        if (field['type'] == 'dynamicTextField') {
          final fieldName = field['name'];
          dynamicFieldControllers[fieldName] = List.generate(
            field['initialCount'] ?? 1,
            (_) => TextEditingController(),
          );

          formFields.add(
            StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(field['label'] ?? ''),
                    ...dynamicFieldControllers[fieldName]!.map((controller) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: TextFormField(
                          controller: controller,
                          decoration: InputDecoration(
                            hintText: field['hint'] ?? 'Enter value',
                            filled: true,
                          ),
                        ),
                      );
                    }).toList(),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            dynamicFieldControllers[fieldName]!
                                .add(TextEditingController());
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          );
        }
        if (field['type'] == 'dropdown') {
          dropdownValues[field['name']] = field['options']?.first;
          formFields.add(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: dropdownValues[field['name']],
                  items: (field['options'] as List<String>)
                      .map((option) => DropdownMenuItem(
                            value: option,
                            child: Text(option),
                          ))
                      .toList(),
                  onChanged: (value) {
                    dropdownValues[field['name']] = value;
                  },
                  decoration: InputDecoration(
                    labelText: field['label'] ?? '',
                    filled: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return field['validationMessage'] ??
                          'Please select a value';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        } else if (field['type'] == 'checkbox') {
          checkboxValues[field['name']] = field['defaultValue'] ?? false;
          formFields.add(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: checkboxValues[field['name']],
                      onChanged: (value) {
                        checkboxValues[field['name']] = value ?? false;
                      },
                    ),
                    Text(field['label'] ?? ''),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        } else if (field['type'] == 'switch') {
          switchValues[field['name']] = field['defaultValue'] ?? false;
          formFields.add(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(field['label'] ?? ''),
                    Switch(
                      value: switchValues[field['name']]!,
                      onChanged: (value) {
                        switchValues[field['name']] = value;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        } else {
          TextEditingController controller = TextEditingController();
          controllers[field['name']] = controller;

          formFields.add(
            Column(
              children: [
                CustomFormField(
                  controller: controller,
                  label: field['label'] ?? '',
                  hint: field['hint'] ?? '',
                  icon: field['icon'] ?? const Icon(Icons.text_fields),
                  validationMessage:
                      field['validationMessage'] ?? 'This field is required',
                  isPassword: field['isPassword'] ?? false,
                  isEmail: field['isEmail'] ?? false,
                  isNumeric: field['isNumeric'] ?? false,
                  isDate: field['isDate'] ?? false,
                  isMultiline: field['isMultiline'] ?? false,
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        }
      } else if (item.containsKey('button')) {
        var button = item['button'];
        formFields.add(
          Column(
            children: [
              ElevatedButton.icon(
                onPressed: button['onTap'] ??
                    () {
                      if (_formKey.currentState!.validate()) {
                        controllers.forEach((key, controller) {
                          debugPrint('$key: ${controller.text}');
                        });
                        dropdownValues.forEach((key, value) {
                          debugPrint('$key: $value');
                        });
                        checkboxValues.forEach((key, value) {
                          debugPrint('$key: $value');
                        });
                        switchValues.forEach((key, value) {
                          debugPrint('$key: $value');
                        });
                      }
                    },
                icon: button['icon'] ?? const Icon(Icons.send),
                label: Text(button['label'] ?? 'Button',
                style: Theme.of(context).textTheme.titleLarge,),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      }
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: formFields,
      ),
    );
  }
}

class CustomFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final Icon icon;
  final String validationMessage;
  final bool isPassword;
  final bool isEmail;
  final bool isNumeric;
  final bool isDate;
  final bool isMultiline;

  const CustomFormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.validationMessage,
    this.isPassword = false,
    this.isEmail = false,
    this.isNumeric = false,
    this.isDate = false,
    this.isMultiline = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool obsText = isPassword;

    return StatefulBuilder(
      builder: (context, setState) {
        return TextFormField(
          controller: controller,
          obscureText: obsText,
          readOnly: isDate,
          onTap: isDate
              ? () async {
                  final selectedDate = await showDatePicker(
                    context: context,
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
              : isNumeric
                  ? TextInputType.number
                  : isMultiline
                      ? TextInputType.multiline
                      : TextInputType.text,
          maxLines: isMultiline ? null : 1,
          textInputAction:
              isMultiline ? TextInputAction.newline : TextInputAction.next,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: Theme.of(context).textTheme.titleMedium,
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
            border: OutlineInputBorder(
              borderSide: Theme.of(context).inputDecorationTheme.border?.borderSide ?? BorderSide.none,
            ),
          ),
          inputFormatters:
              isNumeric ? [FilteringTextInputFormatter.digitsOnly] : null,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return validationMessage;
            } else if (isPassword && value.length < 6) {
              return 'Password must be at least 6 characters';
            } else if (isEmail &&
                !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        );
      },
    );
  }
}

// Kullanım Örneği
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Dynamic Form Example')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: DynamicCustomForm(
            config: [
              {
                'field': {
                  'name': 'username',
                  'label': 'Username',
                  'hint': 'Enter your username',
                  'icon': const Icon(Icons.person),
                  'isEmail': false,
                },
              },
              {
                'field': {
                  'name': 'feedback',
                  'label': 'Feedback',
                  'hint': 'Enter your feedback',
                  'icon': const Icon(Icons.feedback),
                  'isMultiline': true,
                },
              },
              {
                'field': {
                  'name': 'gender',
                  'label': 'Gender',
                  'type': 'dropdown',
                  'options': ['Male', 'Female', 'Other'],
                },
              },
              {
                'field': {
                  'name': 'acceptTerms',
                  'label': 'Accept Terms and Conditions',
                  'type': 'checkbox',
                  'defaultValue': false,
                },
              },
              {
                'field': {
                  'name': 'notifications',
                  'label': 'Enable Notifications',
                  'type': 'switch',
                  'defaultValue': true,
                },
              },
              {
                'button': {
                  'label': 'Custom Submit',
                  'icon': const Icon(Icons.check),
                  'onTap': () {
                    debugPrint('Custom Submit Button Pressed!');
                  },
                },
              },
              {
                'button': {
                  'label': 'Default Submit',
                },
              },
            ],
          ),
        ),
      ),
    );
  }
}*/
