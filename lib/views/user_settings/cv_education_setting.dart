import 'package:flutter/material.dart';
import 'package:seaofsea/widgets/custom_form_field.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/theme_provider.dart';

class CVEducationSettings extends StatefulWidget {
  final void Function(List<Map<String, dynamic>>) onChanged;
  final GlobalKey<FormState> formKey;
  final List<Map<String, dynamic>>? initialEducationList;

  const CVEducationSettings({
    super.key,
    required this.onChanged,
    required this.formKey,
    this.initialEducationList,
  });

  @override
  State<CVEducationSettings> createState() => CVEducationSettingsState();
}

class CVEducationSettingsState extends State<CVEducationSettings> {
  final List<Map<String, TextEditingController>> _educationList = [];
  final List<bool> _expanded = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialEducationList != null &&
        widget.initialEducationList!.isNotEmpty) {
      for (var item in widget.initialEducationList!) {
        _educationList.add({
          'school_name': TextEditingController(text: item['school_name'] ?? ''),
          'degree': TextEditingController(text: item['degree'] ?? ''),
          'start_date': TextEditingController(text: item['start_date'] ?? ''),
          'end_date': TextEditingController(text: item['end_date'] ?? ''),
          'description': TextEditingController(text: item['description'] ?? ''),
        });
        _expanded.add(false);
      }
    } else {
      _addEducation();
    }
  }

  void _addEducation() {
    setState(() {
      _educationList.add({
        'school_name': TextEditingController(),
        'degree': TextEditingController(),
        'start_date': TextEditingController(),
        'end_date': TextEditingController(),
        'description': TextEditingController(),
      });
      _expanded.add(true);
    });
  }

  void _removeEducation(int index) {
    setState(() {
      _educationList[index].forEach((_, controller) => controller.dispose());
      _educationList.removeAt(index);
      _expanded.removeAt(index);
    });
  }

  List<Map<String, dynamic>>? getData() {
    if (!(widget.formKey.currentState?.validate() ?? false)) {
      return null;
    }

    return _educationList
        .map((controllers) => {
              'school_name': controllers['school_name']!.text,
              'degree': controllers['degree']!.text,
              'start_date': controllers['start_date']!.text,
              'end_date': controllers['end_date']!.text,
              'description': controllers['description']!.text,
            })
        .toList();
  }

  @override
  void dispose() {
    for (var controllers in _educationList) {
      controllers.forEach((_, controller) => controller.dispose());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Form(
      key: widget.formKey,
      child: Column(
        children: [
          SizedBox(
            height: 600, // Listeyi sabit bir yükseklikte tutmak için
            child: ReorderableListView.builder(
              itemCount: _educationList.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _educationList.removeAt(oldIndex);
                  _educationList.insert(newIndex, item);

                  final expandedItem = _expanded.removeAt(oldIndex);
                  _expanded.insert(newIndex, expandedItem);
                });
              },
              itemBuilder: (context, i) {
                return Card(
                  key: ValueKey(i),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ExpansionTile(
                    initiallyExpanded: _expanded[i],
                    onExpansionChanged: (val) =>
                        setState(() => _expanded[i] = val),
                    title: Text('${i + 1}. ${_educationList[i]['degree']!.text}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeEducation(i),
                    ),
                    children: [
                      CustomFormField(
                        controller: _educationList[i]['school_name']!,
                        themeProvider: themeProvider,
                        label: 'School Name',
                        hint: 'Enter school name',
                        icon: const Icon(Icons.school),
                        validationMessage: 'School name is required',
                      ),
                      const SizedBox(height: 12),
                      CustomFormField(
                        controller: _educationList[i]['degree']!,
                        themeProvider: themeProvider,
                        label: 'Degree',
                        hint: 'Enter your degree',
                        icon: const Icon(Icons.workspace_premium),
                        validationMessage: 'Degree is required',
                      ),
                      const SizedBox(height: 12),
                      CustomFormField(
                        controller: _educationList[i]['start_date']!,
                        themeProvider: themeProvider,
                        label: 'Start Date',
                        hint: 'Select start date',
                        icon: const Icon(Icons.date_range),
                        validationMessage: 'Start date is required',
                        isDate: true,
                        context: context,
                      ),
                      const SizedBox(height: 12),
                      CustomFormField(
                        controller: _educationList[i]['end_date']!,
                        themeProvider: themeProvider,
                        label: 'End Date',
                        hint: 'Select end date',
                        icon: const Icon(Icons.date_range),
                        validationMessage: 'End date is required',
                        isDate: true,
                        context: context,
                      ),
                      const SizedBox(height: 12),
                      CustomFormField(
                        controller: _educationList[i]['description']!,
                        themeProvider: themeProvider,
                        label: 'Description',
                        hint: 'Write about your studies',
                        icon: const Icon(Icons.description),
                        isRequired: false,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _addEducation,
            icon: const Icon(Icons.add),
            label: const Text('Add Another Education'),
          ),
        ],
      ),
    );
  }
}
