import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/api_manager.dart';
import 'package:seaofsea/utils/theme_provider.dart';
import 'package:seaofsea/widgets/custom_form_field.dart';

class CVWorkExperienceSettings extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final List<Map<String, dynamic>>? initialExperienceList;

  const CVWorkExperienceSettings({
    super.key,
    required this.formKey,
    this.initialExperienceList,
  });

  @override
  State<CVWorkExperienceSettings> createState() =>
      _CVWorkExperienceSettingsState();
}

class _CVWorkExperienceSettingsState extends State<CVWorkExperienceSettings> {
  final List<Map<String, dynamic>> _workExperienceList = [];
  final List<Map<String, TextEditingController>> _controllers = [];
  final List<bool> _expanded = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialExperienceList != null &&
        widget.initialExperienceList!.isNotEmpty) {
      for (var item in widget.initialExperienceList!) {
        _workExperienceList.add({...item});
        _expanded.add(false);
        _controllers.add({
          'position': TextEditingController(text: item['position'] ?? ''),
          'shipName': TextEditingController(text: item['shipName'] ?? ''),
          'company': TextEditingController(text: item['company'] ?? ''),
          'grt': TextEditingController(text: item['grt'] ?? ''),
          'kw': TextEditingController(text: item['kw'] ?? ''),
          'flag': TextEditingController(text: item['flag'] ?? ''),
          'shipType': TextEditingController(text: item['shipType'] ?? ''),
          'title': TextEditingController(text: item['title'] ?? ''),
          'period': TextEditingController(text: item['period'] ?? ''),
        });
      }
    } else {
      _addExperience();
    }
  }

  void _addExperience() {
    setState(() {
      _workExperienceList.add({
        'type': 'sea',
        'position': '',
        'shipName': '',
        'company': '',
        'grt': '',
        'kw': '',
        'flag': '',
        'shipType': '',
        'title': '',
        'period': '',
        'details': [],
      });
      _expanded.add(true);
      _controllers.add({
        'position': TextEditingController(),
        'shipName': TextEditingController(),
        'company': TextEditingController(),
        'grt': TextEditingController(),
        'kw': TextEditingController(),
        'flag': TextEditingController(),
        'shipType': TextEditingController(),
        'title': TextEditingController(),
        'period': TextEditingController(),
      });
    });
  }

  void _removeExperience(int index) {
    setState(() {
      _workExperienceList.removeAt(index);
      _controllers.removeAt(index);
      _expanded.removeAt(index);
    });
  }

  void _moveUp(int index) {
    if (index > 0) {
      setState(() {
        final temp = _workExperienceList[index];
        _workExperienceList[index] = _workExperienceList[index - 1];
        _workExperienceList[index - 1] = temp;

        final tempControllers = _controllers[index];
        _controllers[index] = _controllers[index - 1];
        _controllers[index - 1] = tempControllers;

        final expandedTemp = _expanded[index];
        _expanded[index] = _expanded[index - 1];
        _expanded[index - 1] = expandedTemp;
      });
    }
  }

  void _moveDown(int index) {
    if (index < _workExperienceList.length - 1) {
      setState(() {
        final temp = _workExperienceList[index];
        _workExperienceList[index] = _workExperienceList[index + 1];
        _workExperienceList[index + 1] = temp;

        final tempControllers = _controllers[index];
        _controllers[index] = _controllers[index + 1];
        _controllers[index + 1] = tempControllers;

        final expandedTemp = _expanded[index];
        _expanded[index] = _expanded[index + 1];
        _expanded[index + 1] = expandedTemp;
      });
    }
  }

  List<Map<String, dynamic>>? getData() {
    if (!(widget.formKey.currentState?.validate() ?? false)) {
      return null;
    }

    for (int i = 0; i < _workExperienceList.length; i++) {
      _workExperienceList[i]['position'] =
          _controllers[i]['position']?.text ?? '';
      _workExperienceList[i]['shipName'] =
          _controllers[i]['shipName']?.text ?? '';
      _workExperienceList[i]['company'] =
          _controllers[i]['company']?.text ?? '';
      _workExperienceList[i]['grt'] = _controllers[i]['grt']?.text ?? '';
      _workExperienceList[i]['kw'] = _controllers[i]['kw']?.text ?? '';
      _workExperienceList[i]['flag'] = _controllers[i]['flag']?.text ?? '';
      _workExperienceList[i]['shipType'] =
          _controllers[i]['shipType']?.text ?? '';
      _workExperienceList[i]['title'] = _controllers[i]['title']?.text ?? '';
      _workExperienceList[i]['period'] = _controllers[i]['period']?.text ?? '';
    }

    return _workExperienceList;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Form(
      key: widget.formKey,
      child: Column(
        children: [
          for (int i = 0; i < _workExperienceList.length; i++)
            ExpansionTile(
              initiallyExpanded: _expanded[i],
              onExpansionChanged: (val) => setState(() => _expanded[i] = val),
              title: Text('Experience Entry ${i + 1}'),
              trailing: Wrap(
                spacing: 8,
                children: [
                  if (i > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_upward),
                      onPressed: () => _moveUp(i),
                    ),
                  if (i < _workExperienceList.length - 1)
                    IconButton(
                      icon: const Icon(Icons.arrow_downward),
                      onPressed: () => _moveDown(i),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeExperience(i),
                  ),
                ],
              ),
              children: [
                DropdownButtonFormField<String>(
                  value: _workExperienceList[i]['type'],
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'sea', child: Text('Sea (Ship)')),
                    DropdownMenuItem(value: 'office', child: Text('Office')),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _workExperienceList[i]['type'] = val!;
                    });
                  },
                ),
                const SizedBox(height: 12),
                // Dinamik Position alanı
                DropdownSearch<Map<String, dynamic>>(
                  asyncItems: (String filter) async {
                    final api = Provider.of<ApiManager>(context, listen: false);
                    final type = _workExperienceList[i]['type'] ?? 'sea';

                    // Sea için Crew, Office için Office
                    String column = 'category';
                    String value = type == 'office' ? 'Office' : 'Crew';

                    final response = await api.post(
                      context,
                      'get_positions_by_handler',
                      {
                        'handler': {'column': column, 'value': value}
                      },
                    );

                    if (response['success'] && response['data'] != null) {
                      final List data = response['data'];
                      return data
                          .where((pos) => pos['name']
                              .toLowerCase()
                              .contains(filter.toLowerCase()))
                          .cast<Map<String, dynamic>>()
                          .toList();
                    }
                    return [];
                  },
                  itemAsString: (item) => item['name'] ?? '',
                  selectedItem: _workExperienceList[i]['position_id'] != null
                      ? {'id': _workExperienceList[i]['position_id']}
                      : null,
                  onChanged: (selectedItem) {
                    setState(() {
                      _workExperienceList[i]['position_id'] =
                          selectedItem?['id'];
                    });
                  },
                  dropdownDecoratorProps: const DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: 'Select Position',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  popupProps: const PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        labelText: 'Search Position',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                if (_workExperienceList[i]['type'] == 'sea') ...[
                  CustomFormField(
                    controller: _controllers[i]['position']!,
                    themeProvider: themeProvider,
                    label: 'Position',
                    hint: 'Enter position',
                    icon: const Icon(Icons.work),
                    validationMessage: 'Position is required',
                  ),
                  const SizedBox(height: 12),
                  CustomFormField(
                    controller: _controllers[i]['shipName']!,
                    themeProvider: themeProvider,
                    label: 'Ship Name',
                    hint: 'Enter ship name',
                    icon: const Icon(Icons.directions_boat),
                  ),
                  const SizedBox(height: 12),
                  CustomFormField(
                    controller: _controllers[i]['company']!,
                    themeProvider: themeProvider,
                    label: 'Company',
                    hint: 'Enter company name',
                    icon: const Icon(Icons.business),
                  ),
                  const SizedBox(height: 12),
                  CustomFormField(
                    controller: _controllers[i]['grt']!,
                    themeProvider: themeProvider,
                    label: 'GRT',
                    hint: 'Gross Tonnage',
                    icon: const Icon(Icons.numbers),
                  ),
                  const SizedBox(height: 12),
                  CustomFormField(
                    controller: _controllers[i]['kw']!,
                    themeProvider: themeProvider,
                    label: 'KW',
                    hint: 'Kilowatt Power',
                    icon: const Icon(Icons.bolt),
                  ),
                  const SizedBox(height: 12),
                  CustomFormField(
                    controller: _controllers[i]['flag']!,
                    themeProvider: themeProvider,
                    label: 'Flag',
                    hint: 'Enter flag',
                    icon: const Icon(Icons.flag),
                  ),
                  const SizedBox(height: 12),
                  CustomFormField(
                    controller: _controllers[i]['shipType']!,
                    themeProvider: themeProvider,
                    label: 'Ship Type',
                    hint: 'Enter ship type',
                    icon: const Icon(Icons.category),
                  ),
                ] else ...[
                  CustomFormField(
                    controller: _controllers[i]['title']!,
                    themeProvider: themeProvider,
                    label: 'Title',
                    hint: 'Enter title',
                    icon: const Icon(Icons.title),
                    validationMessage: 'Title is required',
                  ),
                  const SizedBox(height: 12),
                  CustomFormField(
                    controller: _controllers[i]['company']!,
                    themeProvider: themeProvider,
                    label: 'Company',
                    hint: 'Enter company',
                    icon: const Icon(Icons.business),
                  ),
                ],
                const SizedBox(height: 12),
                CustomFormField(
                  controller: _controllers[i]['period']!,
                  themeProvider: themeProvider,
                  label: 'Period',
                  hint: 'Enter period',
                  icon: const Icon(Icons.timeline),
                  validationMessage: 'Period is required',
                ),
                const SizedBox(height: 12),
              ],
            ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _addExperience,
            icon: const Icon(Icons.add),
            label: const Text('Add Another Experience'),
          ),
        ],
      ),
    );
  }
}
