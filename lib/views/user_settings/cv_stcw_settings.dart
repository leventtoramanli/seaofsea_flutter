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

  String _codeOf(Map<String, dynamic> cert) =>
      (cert['stcw_code'] ?? '').toString().toUpperCase().trim();

  bool _isSeamanVisa(Map<String, dynamic> cert) =>
      _codeOf(cert) == 'SEAMAN_VISA';

  bool _needsDocNo(Map<String, dynamic> cert) {
    final code = _codeOf(cert);
    return code == 'PASSPORT' || code == 'SEAMANS_BOOK' || code == 'DRIVERS_LICENSE';
  }

  @override
  void initState() {
    super.initState();

    if (widget.initialUserCertificates != null) {
      for (final cert in widget.initialUserCertificates!) {
        final int certId = int.parse(cert['id'].toString());
        _selected[certId] = true;

        _issueDateControllers[certId] =
            TextEditingController(text: cert['isd']?.toString() ?? '');
        _expireDateControllers[certId] =
            TextEditingController(text: cert['exd']?.toString() ?? '');

        if (cert['dn'] != null && cert['dn'].toString().isNotEmpty) {
          _documentNumberControllers[certId] =
              TextEditingController(text: cert['dn'].toString());
        }

        // Seaman Visa için mevcut vizeleri yükle
        final master = widget.allCertificates.firstWhere(
          (c) => int.parse(c['id'].toString()) == certId,
          orElse: () => {},
        );
        if (master.isNotEmpty && _isSeamanVisa(master)) {
          final visasRaw = cert['visas'];
          if (visasRaw is List) {
            for (final v in visasRaw) {
              _visaList.add({
                'visaName': TextEditingController(text: (v['vn'] ?? '').toString()),
                'issueDate': TextEditingController(text: (v['isd'] ?? '').toString()),
                'expireDate': TextEditingController(text: (v['exd'] ?? '').toString()),
              });
            }
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
      if (!isChecked) return;

      final issueDate = _issueDateControllers[certId]?.text ?? '';
      final expireDate = _expireDateControllers[certId]?.text ?? '';

      final certData = <String, dynamic>{
        'id': certId,
        'isd': issueDate,
        'exd': expireDate,
      };

      final docController = _documentNumberControllers[certId];
      if (docController != null && docController.text.trim().isNotEmpty) {
        certData['dn'] = docController.text.trim();
      }

      // Seaman visa ise alt vize dizisini ekle
      final master = widget.allCertificates.firstWhere(
        (c) => int.parse(c['id'].toString()) == certId,
        orElse: () => {},
      );
      if (master.isNotEmpty && _isSeamanVisa(master)) {
        final visas = _visaList
            .where((m) =>
                m['visaName']!.text.trim().isNotEmpty ||
                m['issueDate']!.text.trim().isNotEmpty ||
                m['expireDate']!.text.trim().isNotEmpty)
            .map((m) => {
                  'vn': m['visaName']!.text.trim(),
                  'isd': m['issueDate']!.text.trim(),
                  'exd': m['expireDate']!.text.trim(),
                })
            .toList();
        if (visas.isNotEmpty) {
          certData['visas'] = visas;
        }
      }

      selectedCertificates.add(certData);
    });

    return selectedCertificates;
  }

  @override
  Widget build(BuildContext context) {
    // Grupla & sırala
    final Map<int, List<Map<String, dynamic>>> grouped = {};
    for (final cert in widget.allCertificates) {
      final gid = int.tryParse(cert['group_id'].toString()) ?? 0;
      grouped.putIfAbsent(gid, () => []).add(cert);
    }
    grouped.forEach((gid, list) {
      list.sort((a, b) {
        final aS = int.tryParse(a['sort_order'].toString()) ?? 0;
        final bS = int.tryParse(b['sort_order'].toString()) ?? 0;
        return aS.compareTo(bS);
      });
    });

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

    IconData _icon(int gid) {
      switch (gid) {
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
          return FontAwesomeIcons.hatCowboy;
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

    final sortedGroupIds = grouped.keys.toList()..sort();

    return Form(
      key: widget.formKey,
      child: SingleChildScrollView(
        child: ExpansionPanelList.radio(
          elevation: 2,
          expandedHeaderPadding: const EdgeInsets.symmetric(vertical: 4),
          children: sortedGroupIds.map<ExpansionPanelRadio>((gid) {
            final certs = grouped[gid]!;
            return ExpansionPanelRadio(
              value: gid,
              headerBuilder: (_, isExpanded) => ListTile(
                leading: FaIcon(_icon(gid),
                    color: Theme.of(context).colorScheme.primary),
                title: Text(groupNames[gid] ?? 'Group $gid',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              body: Column(
                children: certs.map((cert) {
                  final certId = int.parse(cert['id'].toString());
                  final isSelected = _selected[certId] ?? false;
                  final isVisa = _isSeamanVisa(cert);
                  final needsDocNo = _needsDocNo(cert);

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CheckboxListTile(
                            title: Text(cert['name'].toString()),
                            subtitle: Text((cert['note'] ?? '').toString()),
                            value: isSelected,
                            onChanged: (v) {
                              setState(() {
                                _selected[certId] = v ?? false;
                                if (v == true) {
                                  _issueDateControllers[certId] ??=
                                      TextEditingController();
                                  _expireDateControllers[certId] ??=
                                      TextEditingController();
                                  if (needsDocNo &&
                                      _documentNumberControllers[certId] ==
                                          null) {
                                    _documentNumberControllers[certId] =
                                        TextEditingController();
                                  }
                                }
                              });
                            },
                          ),

                          if (isSelected && isVisa) ...[
                            // Seaman Visa alt vizeleri
                            ..._visaList.map((visa) => Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      children: [
                                        CustomFormField(
                                          controller: visa['visaName']!,
                                          themeProvider:
                                              Provider.of<ThemeProvider>(
                                                  context,
                                                  listen: false),
                                          label: 'Visa Name',
                                          hint: 'e.g. Schengen, USA...',
                                          icon:
                                              const Icon(Icons.assignment_outlined),
                                          isRequired: false,
                                        ),
                                        const SizedBox(height: 8),
                                        CustomFormField(
                                          controller: visa['issueDate']!,
                                          themeProvider:
                                              Provider.of<ThemeProvider>(
                                                  context,
                                                  listen: false),
                                          label: 'Issue Date',
                                          hint: 'Enter Issue Date',
                                          icon: const Icon(Icons.date_range),
                                          isDate: true,
                                          lastDate: 10,
                                          context: context,
                                          isRequired: false,
                                        ),
                                        const SizedBox(height: 8),
                                        CustomFormField(
                                          controller: visa['expireDate']!,
                                          themeProvider:
                                              Provider.of<ThemeProvider>(
                                                  context,
                                                  listen: false),
                                          label: 'Expire Date',
                                          hint: 'Enter Expiry Date',
                                          icon: const Icon(Icons.date_range),
                                          isDate: true,
                                          lastDate: 10,
                                          context: context,
                                          isRequired: false,
                                        ),
                                      ],
                                    ),
                                  ),
                                )),
                            ElevatedButton.icon(
                              onPressed: _addVisa,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Visa'),
                            ),
                          ],

                          if (isSelected && needsDocNo)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4.0),
                              child: CustomFormField(
                                controller:
                                    _documentNumberControllers[certId] ??=
                                        TextEditingController(),
                                themeProvider: Provider.of<ThemeProvider>(
                                    context,
                                    listen: false),
                                label: _codeOf(cert) == 'DRIVERS_LICENSE'
                                    ? '${cert['name']} Type'
                                    : '${cert['name']} Number',
                                hint: _codeOf(cert) == 'PASSPORT'
                                    ? 'e.g. U000000'
                                    : _codeOf(cert) == 'SEAMANS_BOOK'
                                        ? 'e.g. S000000'
                                        : 'e.g. A, A2, B, C...',
                                icon: const Icon(Icons.confirmation_number),
                                isRequired: false,
                              ),
                            ),

                          if (isSelected && !isVisa) ...[
                            const SizedBox(height: 8),
                            CustomFormField(
                              controller: _issueDateControllers[certId]!,
                              themeProvider: Provider.of<ThemeProvider>(context,
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
                            CustomFormField(
                              controller: _expireDateControllers[certId]!,
                              themeProvider: Provider.of<ThemeProvider>(context,
                                  listen: false),
                              label: 'Expire Date',
                              hint: 'Enter Expiry Date',
                              icon: const Icon(Icons.date_range),
                              isDate: true,
                              lastDate: 10,
                              context: context,
                              isRequired: false,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final c in _issueDateControllers.values) c.dispose();
    for (final c in _expireDateControllers.values) c.dispose();
    for (final c in _documentNumberControllers.values) c.dispose();
    for (final m in _visaList) {
      m['visaName']?.dispose();
      m['issueDate']?.dispose();
      m['expireDate']?.dispose();
    }
    super.dispose();
  }
}
