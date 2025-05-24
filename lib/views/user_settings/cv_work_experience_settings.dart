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
      CVWorkExperienceSettingsState();
}

class CVWorkExperienceSettingsState extends State<CVWorkExperienceSettings> {
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
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Form(
      key: widget.formKey,
      child: Column(
        children: [
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _workExperienceList.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final item = _workExperienceList.removeAt(oldIndex);
                final controllerItem = _controllers.removeAt(oldIndex);
                final expandedItem = _expanded.removeAt(oldIndex);
                _workExperienceList.insert(newIndex, item);
                _controllers.insert(newIndex, controllerItem);
                _expanded.insert(newIndex, expandedItem);
              });
            },
            itemBuilder: (context, i) => Card(
              key: ValueKey(_workExperienceList[i]),
              child: ExpansionTile(
                initiallyExpanded: _expanded[i],
                onExpansionChanged: (val) => setState(() => _expanded[i] = val),
                title: Text('${i + 1}. ${_controllers[i]['company']?.text}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeExperience(i),
                ),
                children: [
                  const SizedBox(height: 12),
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
                      final api =
                          Provider.of<ApiManager>(context, listen: false);
                      final type = _workExperienceList[i]['type'] ?? 'sea';

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
                        ? {
                            'id': _workExperienceList[i]['position_id'],
                            'name':
                                _workExperienceList[i]['position_name'] ?? ''
                          }
                        : null,
                    onChanged: (selectedItem) {
                      setState(() {
                        _workExperienceList[i]['position_id'] =
                            selectedItem?['id'];
                        _workExperienceList[i]['position_name'] =
                            selectedItem?['name'];
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
                    // Sea-specific fields
                    DropdownSearch<Map<String, dynamic>>(
                      asyncItems: (String filter) async {
                        final api =
                            Provider.of<ApiManager>(context, listen: false);
                        final response =
                            await api.post(context, 'get_ship_types', {});
                        if (response['success'] == true &&
                            response['data'] != null) {
                          final List data = response['data'];
                          return data
                              .where((shipType) => shipType['name']
                                  .toLowerCase()
                                  .contains(filter.toLowerCase()))
                              .cast<Map<String, dynamic>>()
                              .toList();
                        }
                        return [];
                      },
                      itemAsString: (item) => item['name'] ?? '',
                      selectedItem: _workExperienceList[i]['ship_type_id'] !=
                              null
                          ? {
                              'id': _workExperienceList[i]['ship_type_id'],
                              'name':
                                  _workExperienceList[i]['ship_type_name'] ?? ''
                            }
                          : null,
                      onChanged: (selectedItem) {
                        setState(() {
                          _workExperienceList[i]['ship_type_id'] =
                              selectedItem?['id'];
                          _workExperienceList[i]['ship_type_name'] =
                              selectedItem?['name'];
                        });
                      },
                      dropdownDecoratorProps: const DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          labelText: 'Select Ship Type',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      popupProps: const PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                          decoration: InputDecoration(
                            labelText: 'Search Ship Type',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
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
                      controller: _controllers[i]['engineBrand'] ??=
                          TextEditingController(),
                      themeProvider: themeProvider,
                      label: 'Engine Brand',
                      hint: 'Enter engine brand',
                      icon: const Icon(Icons.engineering),
                      isRequired: false,
                    ),
                    const SizedBox(height: 12),
                    CustomFormField(
                      controller: _controllers[i]['propulsionPower'] ??=
                          TextEditingController(),
                      themeProvider: themeProvider,
                      label: 'Propeller Power Transmission',
                      hint: 'Enter propulsion power transmission',
                      icon: const Icon(Icons.propane),
                      isRequired: false,
                    ),
                  ] else ...[
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
            ),
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
