import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_exif_plugin/flutter_exif_plugin.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/dynamic_file_provider.dart';
import 'package:seaofsea/widgets/custom_image_picker.dart';

class DynamicCustomForm extends StatefulWidget {
  final List<Map<String, dynamic>> config;

  const DynamicCustomForm({required this.config, super.key});

  @override
  State<DynamicCustomForm> createState() => _DynamicCustomFormState();
}

class _DynamicCustomFormState extends State<DynamicCustomForm> {
  final Map<String, TextEditingController> controllers = {};
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final Map<String, String?> dropdownValues = {};
  final Map<String, bool> checkboxValues = {};
  final Map<String, bool> switchValues = {};
  final Map<String, String?> fileValues = {};
  final Map<String, String?> imageValues = {};

  @override
  void dispose() {
    Provider.of<DynamicFieldProvider>(context, listen: false)
        .disposeControllers();
    controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> formFields = [];

    for (var item in widget.config) {
      if (item.containsKey('field')) {
        var field = item['field'];
        if (field['type'] == 'dropdown') {
          formFields.add(buildDropdownField(field, dropdownValues));
        } else if (field['type'] == 'checkbox') {
          formFields.add(buildCheckboxField(field, checkboxValues));
        } else if (field['type'] == 'switch') {
          formFields.add(buildSwitchField(field, switchValues));
        } else if (field['type'] == 'dynamicTextField') {
          formFields.add(buildDynamicTextField(field, context));
        } else if (field['type'] == 'filePicker') {
          formFields.add(buildFilePickerField(field, fileValues));
        } else if (field['type'] == 'imagePicker') {
          formFields.add(buildImagePickerField(field, imageValues));
        } else if (field['type'] == 'datePicker') {
          formFields.add(buildDatePickerField(field, dropdownValues));
        } else if (field['type'] == 'multilineText') {
          formFields.add(buildMultilineTextField(field, controllers));
        } else {
          formFields.add(buildTextField(field, controllers));
        }
        formFields.add(const SizedBox(height: 16));
      } else if (item.containsKey('button')) {
        var button = item['button'];
        formFields.add(
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
                    fileValues.forEach((key, value) {
                      debugPrint('$key: $value');
                    });
                    imageValues.forEach((key, value) {
                      debugPrint('$key: $value');
                    });
                  }
                },
            icon: button['icon'] ?? const Icon(Icons.send),
            label: Text(button['label'] ?? 'Button'),
          ),
        );
      }
      formFields.add(const SizedBox(height: 16));
    }

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: formFields,
        ),
      ),
    );
  }

  Widget buildDropdownField(
      Map<String, dynamic> field, Map<String, String?> dropdownValues) {
    dropdownValues[field['name']] = field['options']?.first;
    return DropdownButtonFormField<String>(
      value: dropdownValues[field['name']],
      items: (field['options'] as List<String>)
          .map((option) => DropdownMenuItem(value: option, child: Text(option)))
          .toList(),
      onChanged: (value) {
        dropdownValues[field['name']] = value;
      },
      decoration: InputDecoration(
        labelText: field['label'] ?? '',
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return field['validationMessage'] ?? 'Please select a value';
        }
        return null;
      },
    );
  }

  Widget buildCheckboxField(
      Map<String, dynamic> field, Map<String, bool> checkboxValues) {
    checkboxValues[field['name']] = field['defaultValue'] ?? false;
    return StatefulBuilder(
      builder: (context, setState) {
        return Row(
          children: [
            Checkbox(
              value: checkboxValues[field['name']],
              onChanged: (value) {
                setState(() {
                  checkboxValues[field['name']] = value ?? false;
                });
              },
            ),
            Text(field['label'] ?? ''),
          ],
        );
      },
    );
  }

  Widget buildTextField(Map<String, dynamic> field,
      Map<String, TextEditingController> controllers) {
    TextEditingController controller = TextEditingController();
    controllers[field['name']] = controller;
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: field['label'] ?? '',
        hintText: field['hint'] ?? 'Enter value',
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return field['validationMessage'] ?? 'This field is required';
        }
        return null;
      },
    );
  }

  Widget buildSwitchField(
      Map<String, dynamic> field, Map<String, bool> switchValues) {
    switchValues[field['name']] = field['defaultValue'] ?? false;
    return StatefulBuilder(
      builder: (context, setState) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(field['label'] ?? ''),
            Switch(
              value: switchValues[field['name']]!,
              onChanged: (value) {
                setState(() {
                  switchValues[field['name']] = value;
                });
              },
            ),
          ],
        );
      },
    );
  }

  Widget buildDynamicTextField(
    Map<String, dynamic> field,
    BuildContext context,
  ) {
    final provider = Provider.of<DynamicFieldProvider>(context);
    final fieldName = field['name'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field['label'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        ...provider.getControllers(fieldName).asMap().entries.map((entry) {
          final index = entry.key;
          final controller = entry.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                hintText: field['hint'] ?? 'Enter value',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.remove_circle),
                  onPressed: () => provider.removeField(fieldName, index),
                ),
              ),
            ),
          );
          // ignore: unnecessary_to_list_in_spreads
        }).toList(),
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => provider.addField(fieldName),
          ),
        ),
      ],
    );
  }

  Widget buildFilePickerField(
      Map<String, dynamic> field, Map<String, String?> fileValues) {
    fileValues[field['name']] = null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton(
          onPressed: () async {
            FilePickerResult? result = await FilePicker.platform.pickFiles(
              allowMultiple: false,
              type: FileType.custom,
              allowedExtensions:
                  field['allowedExtensions'] ?? ['jpg', 'png', 'pdf', 'docx'],
            );

            if (result != null && result.files.isNotEmpty) {
              fileValues[field['name']] = result.files.single.path;
              debugPrint('File Path: ${fileValues[field['name']]}');
            }
          },
          child: Text(field['label'] ?? 'Choose File'),
        ),
        if (fileValues[field['name']] != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Selected File: ${fileValues[field['name']]}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
      ],
    );
  }

  Widget buildImagePickerField(
      Map<String, dynamic> field, Map<String, String?> imageValues) {
    // Başlangıç değerini ayarla
    imageValues[field['name']] = null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field['label'] ?? 'Choose Image',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8.0),
        CustomImagePicker(
          aspectRatio: field['aspectRatio'] ?? 1.0,
          onImagePicked: (file) {
            if (file != null) {
              setState(() {
                imageValues[field['name']] = file.path; // Seçilen resmi kaydet
              });
            }
          },
        ),
        if (imageValues[field['name']] != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Selected Image: ${imageValues[field['name']]}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
      ],
    );
  }

  Future<void> readImageMetadata(String imagePath) async {
    FlutterExif exif = FlutterExif.fromPath(imagePath);

    String? date = await exif.getAttribute('DateTimeOriginal');
    String? cameraModel = await exif.getAttribute('Model');
    debugPrint('Date Taken: $date');
    debugPrint('Camera Model: $cameraModel');
  }

  Widget buildDatePickerField(
      Map<String, dynamic> field, Map<String, String?> dateValues) {
    dateValues[field['name']] = null;

    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: field['label'] ?? 'Select Date',
        hintText: field['hint'] ?? 'yyyy-mm-dd',
        border: const OutlineInputBorder(),
      ),
      onTap: () async {
        DateTime? selectedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
        );
        if (selectedDate != null) {
          dateValues[field['name']] =
              selectedDate.toIso8601String().split('T')[0];
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return field['validationMessage'] ?? 'Please select a date';
        }
        return null;
      },
    );
  }

  Widget buildMultilineTextField(Map<String, dynamic> field,
      Map<String, TextEditingController> controllers) {
    TextEditingController controller = TextEditingController();
    controllers[field['name']] = controller;

    return TextFormField(
      controller: controller,
      maxLines: field['maxLines'] ?? 5,
      decoration: InputDecoration(
        labelText: field['label'] ?? '',
        hintText: field['hint'] ?? 'Enter your text here',
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return field['validationMessage'] ?? 'This field is required';
        }
        return null;
      },
    );
  }
}
