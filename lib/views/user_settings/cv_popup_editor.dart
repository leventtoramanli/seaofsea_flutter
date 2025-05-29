import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/services/custom_text_editor.dart';
import 'package:seaofsea/utils/api_manager.dart';
import 'package:seaofsea/views/user_settings/contact_form_section_cv.dart';
import 'package:seaofsea/views/user_settings/cv_education_setting.dart';
import 'package:seaofsea/views/user_settings/cv_language_settings.dart';
import 'package:seaofsea/views/user_settings/cv_referance_setting.dart';
import 'package:seaofsea/views/user_settings/cv_work_experience_settings.dart';
import 'package:seaofsea/views/user_settings/expertice_form_section_cv.dart';

class CVPopupEditor extends StatefulWidget {
  final String title;
  final String? initialText;
  final bool saveButton;
  final Map<String, dynamic>? initialCV;
  final String? type;
  final Function(String) onSubmit;

  const CVPopupEditor({
    super.key,
    this.initialCV,
    required this.title,
    required this.onSubmit,
    this.saveButton = true,
    this.initialText,
    this.type = 'default',
  });

  @override
  State<CVPopupEditor> createState() => _CVPopupEditorState();
}

class _CVPopupEditorState extends State<CVPopupEditor> {
  final GlobalKey<QuillTextEditorState> _editorKey = GlobalKey();
  final GlobalKey<FormState> _educationFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _workFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _referenceFormKey = GlobalKey<FormState>();

  String content = '';
  Map<String, dynamic> contactData = {};
  Map<String, dynamic> pendingData = {};

  @override
  void initState() {
    super.initState();
    content = widget.initialText ?? '';
  }

  void _handleSubmit([String? updatedText]) async {
    debugPrint('>>>> HANDLE SUBMIT STARTED');
    debugPrint('type: ${widget.type}');
    debugPrint('pendingData: $pendingData');
    final api = Provider.of<ApiManager>(context, listen: false);

    if (widget.type == 'default' ||
        widget.type == 'basic_info' ||
        widget.type == 'professional_title') {
      if (widget.type == 'professional_title') {
        content = content.trim();
      } else {
        content = _editorKey.currentState?.getJson() ?? '';
      }

      final response =
          await api.post(context, 'update_cv', {widget.type!: content});

      if (response['success'] == true) {
        widget.onSubmit(content);
        setState(() {});
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Save failed')),
          );
        }
      }
      return;
    }

    if (widget.type == 'education') {
      final state = _educationFormKey.currentState?.context
          .findAncestorStateOfType<CVEducationSettingsState>();
      final result = state?.getData();
      if (result == null) return; // geçersiz veri

      pendingData = {
        'education': result,
      };
    }

    if (widget.type == 'work_experience') {
      final state = _workFormKey.currentState?.context
          .findAncestorStateOfType<CVWorkExperienceSettingsState>();
      final result = state?.getData();
      if (result == null) return;

      pendingData = {
        'work_experience': result,
      };
    }

    if (widget.type == 'references') {
      final state = _referenceFormKey.currentState?.context
          .findAncestorStateOfType<CVReferenceSettingsState>();
      final result = state?.getData();
      if (result == null) return;
      pendingData = {'references': result};
    }

    debugPrint('Pending data: $pendingData');
    final response = await api.post(context, 'update_cv', {
      widget.type!: pendingData, // örnek: { "contact": {...} }
    });

    debugPrint('Response: $pendingData \n Responsed: $response');

    if (response['success'] == true) {
      widget.onSubmit("success");
      if (mounted) {
        Navigator.pop(context);
      }
      setState(() {});
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Save failed')),
        );
      }
    }
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
          onSubmit: (deltaJson) {
            content = deltaJson;
          },
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
        List<ExpertiseItem> initialItems = [];

        final raw = widget.initialCV?[type];
        List<dynamic> dataList = [];

        if (raw is String) {
          try {
            dataList = jsonDecode(raw);
          } catch (_) {
            dataList = [];
          }
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
      case 'language':
        List<LanguageItem> initialItems = [];

        final raw = widget.initialCV?[type];
        List<dynamic> dataList = [];

        if (raw is String) {
          try {
            dataList = jsonDecode(raw);
          } catch (_) {
            dataList = [];
          }
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
      case 'education':
        final raw = widget.initialCV?[type];
        List<Map<String, dynamic>> educationList = [];

        if (raw is String) {
          try {
            educationList = List<Map<String, dynamic>>.from(jsonDecode(raw));
          } catch (_) {
            educationList = [];
          }
        } else if (raw is List) {
          educationList = List<Map<String, dynamic>>.from(raw);
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CVEducationSettings(
              formKey: _educationFormKey,
              initialEducationList: educationList,
              onChanged: (result) {
                pendingData = {
                  'education': result,
                };
              },
            ),
          ),
        );
      case 'work_experience':
      final raw = widget.initialCV?[type];
        List<Map<String, dynamic>> workList = [];

        if (raw is String) {
          try {
            workList = List<Map<String, dynamic>>.from(jsonDecode(raw));
          } catch (_) {
            workList = [];
          }
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
case 'references':
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
      case 'default':
        return QuillTextEditor(
          showAll: false,
          toolbarButtons: minimalToolbarButtons,
          onSubmit: (deltaJson) {
            debugPrint('Editor content: $deltaJson');
          },
        );

      case 'contact':
        return SingleChildScrollView(
          child: Padding(
              padding: EdgeInsets.all(8.0),
              child: ContactFormSection(
                isDark: false,
                initialCV: widget.initialCV,
                onChanged: (data) {
                  pendingData = data;
                },
                //onChanged: (data) => contactData = data,
              )),
        );

      default:
        return const Center(child: Text('Invalid content type.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.type ?? 'default';
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 500,
        height: 400,
        child: _buildDialogContent(type),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        widget.saveButton
            ? ElevatedButton(
                onPressed: () {
                  debugPrint('Content: $content');
                  _handleSubmit(content);
                },
                child: const Text('Save'),
              )
            : Container(),
      ],
    );
  }
}
