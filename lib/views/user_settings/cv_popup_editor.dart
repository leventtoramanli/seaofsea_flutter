import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/services/custom_text_editor.dart';
import 'package:seaofsea/services/v1/v1_api_manager.dart';
import 'package:seaofsea/views/user_settings/contact_form_section_cv.dart';
import 'package:seaofsea/views/user_settings/cv_education_setting.dart';
import 'package:seaofsea/views/user_settings/cv_language_settings.dart';
import 'package:seaofsea/views/user_settings/cv_referance_setting.dart';
import 'package:seaofsea/views/user_settings/cv_stcw_settings.dart';
import 'package:seaofsea/views/user_settings/cv_work_experience_settings.dart';
import 'package:seaofsea/views/user_settings/expertice_form_section_cv.dart';

class CVPopupEditor extends StatefulWidget {
  final String title;
  final String? initialText;
  final bool saveButton;
  final Map<String, dynamic>? initialCV;
  final String? type;
  final Function(String) onSubmit;
  final List<dynamic>? allCertificates;

  const CVPopupEditor({
    super.key,
    this.initialCV,
    required this.title,
    required this.onSubmit,
    this.saveButton = true,
    this.initialText,
    this.type = 'default',
    this.allCertificates,
  });

  @override
  State<CVPopupEditor> createState() => _CVPopupEditorState();
}

class _CVPopupEditorState extends State<CVPopupEditor> {
  final GlobalKey<QuillTextEditorState> _editorKey = GlobalKey();
  final GlobalKey<FormState> _educationFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _workFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _referenceFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _stcwFormKey = GlobalKey<FormState>();

  String content = '';
  Map<String, dynamic> pendingData = {};

  @override
  void initState() {
    super.initState();
    content = widget.initialText ?? '';
  }

  Future<void> _submitToApi({
    required String field,
    required dynamic value,
  }) async {
    final v1 = Provider.of<V1ApiManager>(context, listen: false);

    // Backend’in beklediği payload
    Map<String, dynamic> params;
    switch (field) {
      case 'contact':
        params = {'contact': value}; // object
        break;
      case 'stcw_certificates':
        params = {'stcw_certificates': value}; // list
        break;
      default:
        params = {
          field: value
        }; // basic_info, professional_title, skills, language, education, work_experience, references
    }

    // Tercihen snake_case action kullan (CVHandler’da zaten update_cv -> updateCV yönlendiriyor)
    final resp = await v1.call(
      module: 'cv',
      action:
          'update_cv', // önce 'updateCV' idi; ikisi de çalışır ama bunu tercih edelim
      params: params,
    );

    if (resp['success'] == true && (resp['data']?['success'] == true)) {
      widget.onSubmit(
        (field == 'basic_info' || field == 'professional_title')
            ? (value?.toString() ?? '')
            : 'success',
      );
      if (mounted) Navigator.pop(context);
      setState(() {});
    } else {
      if (!mounted) return;
      final msg = resp['data']?['message'] ?? resp['message'] ?? 'Save failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$msg')),
      );
    }
  }

  void _handleSubmit([String? updatedText]) async {
    final type = widget.type ?? 'default';

    // Basit text (quill delta ya da düz metin)
    if (type == 'default' ||
        type == 'basic_info' ||
        type == 'professional_title') {
      if (type == 'professional_title') {
        content = content.trim();
      } else {
        content = _editorKey.currentState?.getJson() ?? '';
      }
      await _submitToApi(
          field: type == 'default' ? 'basic_info' : type, value: content);
      return;
    }

    // Structured alanlar
    dynamic value;

    if (type == 'education') {
      final state = _educationFormKey.currentState?.context
          .findAncestorStateOfType<CVEducationSettingsState>();
      final result = state?.getData();
      if (result == null) return;
      value = result; // List<Map>
    } else if (type == 'stcw_certificates') {
      final state = _stcwFormKey.currentState?.context
          .findAncestorStateOfType<CVSTCWSettingsState>();
      final result = state?.getData();
      if (result == null) return;
      value = result; // List<Map>
    } else if (type == 'work_experience') {
      final state = _workFormKey.currentState?.context
          .findAncestorStateOfType<CVWorkExperienceSettingsState>();
      final result = state?.getData();
      if (result == null) return;
      value = result; // List<Map>
    } else if (type == 'references') {
      final state = _referenceFormKey.currentState?.context
          .findAncestorStateOfType<CVReferenceSettingsState>();
      final result = state?.getData();
      if (result == null) return;
      value = result; // List<Map>
    } else if (type == 'skills' || type == 'language' || type == 'contact') {
      // Bu üçü _buildDialogContent içinde pendingData’ya yazılıyor
      value = pendingData;
      if (type == 'skills' || type == 'language') {
        // pendingData {'skills': [...]} veya {'language': [...]}
        // value olarak doğrudan listeyi gönderelim
        if (pendingData.isNotEmpty) {
          value = pendingData.values.first;
        }
      }
    } else {
      // desteklenmeyen type
      return;
    }

    await _submitToApi(field: type, value: value);
  }

  Widget _buildDialogContent(String type) {
    switch (type) {
      case 'basic_info':
        return QuillTextEditor(
          key: _editorKey,
          showAll: false,
          toolbarButtons: minimalToolbarButtons,
          minHeight: 100,
          initialJsonDelta: widget.initialText,
          onSubmit: (deltaJson) => content = deltaJson,
        );

      case 'professional_title':
        return Padding(
          padding: const EdgeInsets.all(3.0),
          child: TextFormField(
            initialValue: widget.initialText ?? '',
            autofocus: true,
            onChanged: (val) => content = val,
            maxLines: 1,
            decoration: const InputDecoration(
              labelText: 'Enter Professional Title',
              border: OutlineInputBorder(),
            ),
          ),
        );

      case 'skills':
        {
          List<ExpertiseItem> initialItems = [];
          final raw = widget.initialCV?[type];
          List<dynamic> dataList = [];
          if (raw is String) {
            try {
              dataList = jsonDecode(raw);
            } catch (_) {}
          } else if (raw is List) {
            dataList = raw;
          }
          initialItems = dataList
              .map((e) => ExpertiseItem.fromJson(e as Map<String, dynamic>))
              .toList();
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ExpertiseFormSection(
                initialItems: initialItems,
                onChanged: (items) {
                  pendingData = {
                    'skills': items
                        .map((e) => {
                              ...e.toJson(),
                              'percentage': e.percentage,
                            })
                        .toList(),
                  };
                },
              ),
            ),
          );
        }

      case 'language':
        {
          List<LanguageItem> initialItems = [];
          final raw = widget.initialCV?[type];
          List<dynamic> dataList = [];
          if (raw is String) {
            try {
              dataList = jsonDecode(raw);
            } catch (_) {}
          } else if (raw is List) {
            dataList = raw;
          }
          initialItems = dataList
              .map((e) => LanguageItem.fromJson(e as Map<String, dynamic>))
              .toList();
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: LanguageFormSection(
                initialItems: initialItems,
                onChanged: (items) {
                  pendingData = {
                    'language': items
                        .map((e) => {
                              ...e.toJson(),
                              'percentage': e.percentage,
                            })
                        .toList(),
                  };
                },
              ),
            ),
          );
        }

      case 'education':
        {
          final raw = widget.initialCV?[type];
          List<Map<String, dynamic>> educationList = [];
          if (raw is String) {
            try {
              educationList = List<Map<String, dynamic>>.from(jsonDecode(raw));
            } catch (_) {}
          } else if (raw is List) {
            educationList = List<Map<String, dynamic>>.from(raw);
          }
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CVEducationSettings(
                formKey: _educationFormKey,
                initialEducationList: educationList,
                onChanged: (result) => pendingData = {'education': result},
              ),
            ),
          );
        }

      case 'work_experience':
        {
          final raw = widget.initialCV?[type];
          List<Map<String, dynamic>> workList = [];
          if (raw is String) {
            try {
              workList = List<Map<String, dynamic>>.from(jsonDecode(raw));
            } catch (_) {}
          } else if (raw is List) {
            workList = List<Map<String, dynamic>>.from(raw);
          }
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CVWorkExperienceSettings(
                formKey: _workFormKey,
                initialExperienceList: workList,
              ),
            ),
          );
        }

      case 'references':
        {
          final raw = widget.initialCV?[type];
          List<Map<String, dynamic>> referencesList = [];
          if (raw is String) {
            try {
              referencesList = List<Map<String, dynamic>>.from(jsonDecode(raw));
            } catch (_) {}
          } else if (raw is List) {
            referencesList = List<Map<String, dynamic>>.from(raw);
          }
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CVReferenceSettings(
                formKey: _referenceFormKey,
                initialReferences: referencesList,
              ),
            ),
          );
        }

      case 'stcw_certificates':
        {
          final raw = widget.initialCV?['certificates'];
          final allCertificates = widget.allCertificates ?? [];
          List<Map<String, dynamic>> userCerts = [];
          if (raw is String) {
            try {
              userCerts = List<Map<String, dynamic>>.from(jsonDecode(raw));
            } catch (_) {}
          } else if (raw is List) {
            userCerts = List<Map<String, dynamic>>.from(raw);
          }
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CVSTCWSettings(
                formKey: _stcwFormKey,
                allCertificates: allCertificates
                    .map((e) => e as Map<String, dynamic>)
                    .toList(),
                initialUserCertificates: userCerts,
              ),
            ),
          );
        }

      case 'default':
        return QuillTextEditor(
          showAll: false,
          toolbarButtons: minimalToolbarButtons,
          onSubmit: (deltaJson) {},
        );

      case 'contact':
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ContactFormSection(
              isDark: false,
              initialCV: widget.initialCV,
              onChanged: (data) {
                // contact için doğrudan object set
                pendingData = data;
              },
            ),
          ),
        );

      default:
        return const Center(child: Text('Invalid content type.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.type ?? 'default';
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final dialogWidth = width > 600 ? width * 0.85 : width * 0.95;
    final dialogHeight = height * 0.85;

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: _buildDialogContent(type),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (widget.saveButton)
          ElevatedButton(
            onPressed: () => _handleSubmit(content),
            child: const Text('Save'),
          ),
      ],
    );
  }
}
