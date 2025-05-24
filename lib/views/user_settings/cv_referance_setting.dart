import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/theme_provider.dart';
import 'package:seaofsea/widgets/custom_form_field.dart';

class CVReferenceSettings extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final List<Map<String, dynamic>>? initialReferences;

  const CVReferenceSettings({
    super.key,
    required this.formKey,
    this.initialReferences,
  });

  @override
  State<CVReferenceSettings> createState() => CVReferenceSettingsState();
}

class CVReferenceSettingsState extends State<CVReferenceSettings> {
  final List<Map<String, TextEditingController>> _controllersList = [];
  final List<bool> _expanded = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialReferences != null &&
        widget.initialReferences!.isNotEmpty) {
      for (var item in widget.initialReferences!) {
        _controllersList.add({
          'title': TextEditingController(text: item['title'] ?? ''),
          'name': TextEditingController(text: item['name'] ?? ''),
          'company': TextEditingController(text: item['company'] ?? ''),
          'contact': TextEditingController(text: item['contact'] ?? ''),
        });
        _expanded.add(false);
      }
    } else {
      _addReference();
    }
  }

  void _addReference() {
    setState(() {
      _controllersList.add({
        'title': TextEditingController(),
        'name': TextEditingController(),
        'company': TextEditingController(),
        'contact': TextEditingController(),
      });
      _expanded.add(true);
    });
  }

  void _removeReference(int index) {
    setState(() {
      _controllersList.removeAt(index);
      _expanded.removeAt(index);
    });
  }

  List<Map<String, String>>? getData() {
    if (!(widget.formKey.currentState?.validate() ?? false)) {
      return null;
    }

    final List<Map<String, String>> validEntries = [];

    for (var controllerMap in _controllersList) {
      final title = controllerMap['title']!.text.trim();
      final name = controllerMap['name']!.text.trim();
      final company = controllerMap['company']!.text.trim();
      final contact = controllerMap['contact']!.text.trim();

      // En az bir alan dolu mu?
      if (title.isNotEmpty ||
          name.isNotEmpty ||
          company.isNotEmpty ||
          contact.isNotEmpty) {
        validEntries.add({
          'title': title,
          'name': name,
          'company': company,
          'contact': contact,
        });
      }
    }

    // Hiç dolu kayıt yoksa null dön
    if (validEntries.isEmpty) return null;

    return validEntries;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Form(
      key: widget.formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 400, // Örnek: 400px sabit yükseklik
            child: ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _controllersList.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = _controllersList.removeAt(oldIndex);
                  final expandedItem = _expanded.removeAt(oldIndex);
                  _controllersList.insert(newIndex, item);
                  _expanded.insert(newIndex, expandedItem);
                });
              },
              itemBuilder: (context, index) {
                final controllers = _controllersList[index];
                return Card(
                  key: ValueKey(controllers),
                  child: ExpansionTile(
                    initiallyExpanded: _expanded[index],
                    onExpansionChanged: (val) =>
                        setState(() => _expanded[index] = val),
                    title: Text(controllers['title']!.text.isNotEmpty
                        ? controllers['title']!.text
                        : '${index + 1}. ${controllers['name']!.text}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeReference(index),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomFormField(
                              controller: controllers['title']!,
                              themeProvider: themeProvider,
                              label: 'Title',
                              hint:
                                  'Enter reference title (e.g., Captain, Manager)',
                              icon: const Icon(Icons.badge),
                              validationMessage: 'Title is required',
                            ),
                            const SizedBox(height: 8),
                            CustomFormField(
                              controller: controllers['name']!,
                              themeProvider: themeProvider,
                              label: 'Name & Surname',
                              hint: 'Enter name and surname',
                              icon: const Icon(Icons.person),
                              validationMessage: 'Name & Surname is required',
                            ),
                            const SizedBox(height: 8),
                            CustomFormField(
                              controller: controllers['company']!,
                              themeProvider: themeProvider,
                              label: 'Company',
                              hint: 'Enter company name',
                              icon: const Icon(Icons.business),
                              validationMessage: 'NCompany is required',
                            ),
                            const SizedBox(height: 8),
                            CustomFormField(
                              controller: controllers['contact']!,
                              themeProvider: themeProvider,
                              label: 'Contact',
                              hint: 'Enter phone/email',
                              icon: const Icon(Icons.contact_phone),
                              validationMessage: 'Contact is required',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _addReference,
            icon: const Icon(Icons.add),
            label: const Text('Add Reference'),
          ),
        ],
      ),
    );
  }
}
