import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/theme_provider.dart';
import 'package:seaofsea/widgets/custom_form_field.dart';

class CVSTCWSettings extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final List<Map<String, dynamic>> allCertificates;
  final List<Map<String, dynamic>>? initialUserCertificates;

  const CVSTCWSettings({
    super.key,
    required this.formKey,
    required this.allCertificates,
    this.initialUserCertificates,
  });

  @override
  State<CVSTCWSettings> createState() => CVSTCWSettingsState();
}

class CVSTCWSettingsState extends State<CVSTCWSettings> {
  final Map<int, bool> _selected = {};
  final Map<int, TextEditingController> _issueDateControllers = {};
  final Map<int, TextEditingController> _expireDateControllers = {};
  final Map<int, TextEditingController> _documentNumberControllers = {};
  final List<Map<String, TextEditingController>> _visaList = [];

  @override
  @override
  void initState() {
    super.initState();
    if (widget.initialUserCertificates != null) {
      for (var cert in widget.initialUserCertificates!) {
        final certId = cert['id'];
        _selected[certId] = true;

        _issueDateControllers[certId] =
            TextEditingController(text: cert['isd'] ?? '');
        _expireDateControllers[certId] =
            TextEditingController(text: cert['exd'] ?? '');

        // document number (dn) alanı
        if (cert['dn'] != null && cert['dn'].toString().isNotEmpty) {
          _documentNumberControllers[certId] =
              TextEditingController(text: cert['dn']);
        }

        // Seaman Visa için ilk visaList verisini doldur
        final certName = widget.allCertificates
            .firstWhere((c) => int.parse(c['id'].toString()) == certId)['name']
            .toString()
            .toLowerCase();

        if (certName == 'seaman visa' && cert['visas'] != null) {
          final List<dynamic> visasRaw = cert['visas'];
          for (var visa in visasRaw) {
            _visaList.add({
              'visaName': TextEditingController(text: visa['vn'] ?? ''),
              'issueDate': TextEditingController(text: visa['isd'] ?? ''),
              'expireDate': TextEditingController(text: visa['exd'] ?? ''),
            });
          }
        }
      }
    }
  }

  void _addVisa() {
    setState(() {
      _visaList.add({
        'visaName': TextEditingController(),
        'issueDate': TextEditingController(),
        'expireDate': TextEditingController(),
      });
    });
  }

  List<Map<String, dynamic>>? getData() {
    if (!(widget.formKey.currentState?.validate() ?? false)) {
      return null;
    }

    final selectedCertificates = <Map<String, dynamic>>[];

    _selected.forEach((certId, isChecked) {
      if (isChecked) {
        final issueDate = _issueDateControllers[certId]?.text ?? '';
        final expireDate = _expireDateControllers[certId]?.text ?? '';

        final certData = {
          'id': certId,
          'isd': issueDate,
          'exd': expireDate,
        };

        // Ek alan: Document Number / Type
        final docController = _documentNumberControllers[certId];
        if (docController != null && docController.text.isNotEmpty) {
          certData['dn'] = docController.text;
        }

        // Seaman Visa alanı: Visa listesi ekle
        final certName = widget.allCertificates
            .firstWhere((c) => int.parse(c['id'].toString()) == certId)['name']
            .toString()
            .toLowerCase();

        if (certName == 'seaman visa') {
          final visaList = _visaList
              .where((visa) =>
                  visa['visaName']!.text.isNotEmpty ||
                  visa['issueDate']!.text.isNotEmpty ||
                  visa['expireDate']!.text.isNotEmpty)
              .map((visa) => {
                    'vn': visa['visaName']!.text,
                    'isd': visa['issueDate']!.text,
                    'exd': visa['expireDate']!.text,
                  })
              .toList();

          if (visaList.isNotEmpty) {
            certData['visas'] = visaList;
          }
        }

        selectedCertificates.add(certData);
      }
    });
    return selectedCertificates;
  }

  @override
  Widget build(BuildContext context) {
    // 📌 Gruplama ve sıralama
    final Map<int, List<Map<String, dynamic>>> groupedCerts = {};

// 🟦 İsteye bağlı (validation yok)

    for (var cert in widget.allCertificates) {
      final groupId = int.parse(cert['group_id'].toString());
      groupedCerts.putIfAbsent(groupId, () => []).add(cert);
    }
    groupedCerts.forEach((groupId, certs) {
      certs.sort((a, b) {
        final orderA = int.tryParse(a['sort_order'].toString()) ?? 0;
        final orderB = int.tryParse(b['sort_order'].toString()) ?? 0;
        return orderA.compareTo(orderB);
      });
    });

    // 📌 Grup başlıklarını isimlendirme
    final Map<int, String> groupNames = {
      1: 'Travel Documents',
      2: 'Medical Certificates',
      3: 'Basic Safety Trainings',
      4: 'Advanced and Specialized Trainings',
      5: 'Officer Certificates',
      6: 'Deck & Engine Ratings',
      7: 'Onboard Services',
      8: 'Medical Crew',
      9: 'Fishing Vessel Certificates',
      10: 'Offshore Safety',
      11: 'Tug Operations & Pilotage',
      12: 'Pilotage Licenses',
      13: 'Luxury Yacht Services',
    };
    IconData _getGroupIcon(int groupId) {
      switch (groupId) {
        case 1:
          return FontAwesomeIcons.passport;
        case 2:
          return FontAwesomeIcons.notesMedical;
        case 3:
          return FontAwesomeIcons.lifeRing;
        case 4:
          return FontAwesomeIcons.graduationCap;
        case 5:
          return FontAwesomeIcons.certificate;
        case 6:
          return FontAwesomeIcons.toolbox;
        case 7:
          return FontAwesomeIcons.bellConcierge;
        case 8:
          return FontAwesomeIcons.userDoctor;
        case 9:
          return FontAwesomeIcons.fishFins;
        case 10:
          return FontAwesomeIcons.hardHat;
        case 11:
          return FontAwesomeIcons.ship;
        case 12:
          return FontAwesomeIcons.anchorCircleCheck;
        case 13:
          return FontAwesomeIcons.champagneGlasses;
        default:
          return FontAwesomeIcons.circle;
      }
    }

    final sortedGroupIds = groupedCerts.keys.toList()..sort();

    return Form(
      key: widget.formKey,
      child: SingleChildScrollView(
        child: ExpansionPanelList.radio(
          elevation: 2,
          expandedHeaderPadding: EdgeInsets.symmetric(vertical: 4),
          children: sortedGroupIds.map<ExpansionPanelRadio>((groupId) {
            final groupCerts = groupedCerts[groupId]!;
            return ExpansionPanelRadio(
              value: groupId,
              headerBuilder: (context, isExpanded) => ListTile(
                leading: FaIcon(
                  _getGroupIcon(groupId),
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  groupNames[groupId] ?? 'Group $groupId',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              body: Column(
                children: groupCerts.map((cert) {
                  final certId = int.parse(cert['id'].toString());
                  final isSelected = _selected[certId] ?? false;
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CheckboxListTile(
                            title: Text(cert['name']),
                            subtitle: Text(cert['note'] ?? ''),
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                _selected[certId] = value!;
                                if (value) {
                                  _issueDateControllers[certId] ??=
                                      TextEditingController();
                                  _expireDateControllers[certId] ??=
                                      TextEditingController();
                                }
                              });
                            },
                          ),
                          if (isSelected)
                            Column(
                              children: [
                                if (cert['name'] == 'Seaman Visa')
                                  Column(
                                    children: [
                                      ..._visaList.map((visa) {
                                        return Card(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              children: [
                                                CustomFormField(
                                                  controller: visa['visaName']!,
                                                  themeProvider: Provider.of<
                                                          ThemeProvider>(
                                                      context,
                                                      listen: false),
                                                  label: 'Visa Name',
                                                  hint: 'e.g. Schengen, USA...',
                                                  icon: const Icon(
                                                      Icons.assignment),
                                                  isRequired: false,
                                                ),
                                                const SizedBox(height: 8),
                                                CustomFormField(
                                                  controller:
                                                      visa['issueDate']!,
                                                  themeProvider: Provider.of<
                                                          ThemeProvider>(
                                                      context,
                                                      listen: false),
                                                  label: 'Issue Date',
                                                  hint: 'Enter Issue Date',
                                                  icon: const Icon(
                                                      Icons.date_range),
                                                  isDate: true,
                                                  lastDate: 10,
                                                  context: context,
                                                  isRequired: false,
                                                ),
                                                const SizedBox(height: 8),
                                                CustomFormField(
                                                  controller:
                                                      visa['expireDate']!,
                                                  themeProvider: Provider.of<
                                                          ThemeProvider>(
                                                      context,
                                                      listen: false),
                                                  label: 'Expire Date',
                                                  hint: 'Enter Expiry Date',
                                                  icon: const Icon(
                                                      Icons.date_range),
                                                  isDate: true,
                                                  lastDate: 10,
                                                  context: context,
                                                  isRequired: false,
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }),
                                      ElevatedButton.icon(
                                        onPressed: _addVisa,
                                        icon: const Icon(Icons.add),
                                        label: const Text('Add Visa'),
                                      ),
                                    ],
                                  ),
                                if (cert['name'] == 'Passport' ||
                                    cert['name'] == 'Seaman’s Book' ||
                                    cert['name'] == 'Drivers License')
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0),
                                    child: CustomFormField(
                                      controller:
                                          _documentNumberControllers[certId] ??=
                                              TextEditingController(),
                                      themeProvider: Provider.of<ThemeProvider>(
                                          context,
                                          listen: false),
                                      label: cert['name'] == 'Drivers License'
                                          ? '${cert['name']} Type'
                                          : '${cert['name']} Number',
                                      hint: cert['name'] == 'Passport'
                                          ? 'e.g. U000000'
                                          : cert['name'] == 'Seaman’s Book'
                                              ? 'e.g. S000000'
                                              : 'e.g. A, A2, B, C...',
                                      icon:
                                          const Icon(Icons.confirmation_number),
                                      isRequired: false, // Zorunlu değil!
                                    ),
                                  ),
                                if (cert['name'] != 'Seaman Visa')
                                  const SizedBox(height: 8),
                                if (cert['name'] != 'Seaman Visa')
                                  CustomFormField(
                                    controller: _issueDateControllers[certId]!,
                                    themeProvider: Provider.of<ThemeProvider>(
                                        context,
                                        listen: false),
                                    label: 'Issue Date',
                                    hint: 'Select Issue Date',
                                    icon: const Icon(Icons.calendar_today),
                                    isDate: true,
                                    lastDate: 10,
                                    context: context,
                                    validationMessage: 'Required',
                                  ),
                                const SizedBox(height: 8),
                                if (cert['name'] != 'Seaman Visa')
                                  CustomFormField(
                                    controller: _expireDateControllers[certId]!,
                                    themeProvider: Provider.of<ThemeProvider>(
                                        context,
                                        listen: false),
                                    label: 'Expire Date',
                                    hint: 'Enter Expiry Date',
                                    icon: const Icon(Icons.date_range),
                                    isDate: false,
                                    lastDate: 10,
                                    context: context,
                                    isRequired: false,
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }).toList(),
          // Burada toList()!
        ),
      ),
    );
  }
}
