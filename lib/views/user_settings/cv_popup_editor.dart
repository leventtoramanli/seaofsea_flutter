import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/services/custom_text_editor.dart';
import 'package:seaofsea/utils/api_manager.dart';
import 'package:seaofsea/views/user_settings/contact_form_section_cv.dart';

class CVPopupEditor extends StatefulWidget {
  final String title;
  final String? initialText;
  final Map<String, dynamic>? initialCV;
  final String? type;
  final Function(String) onSubmit;

  const CVPopupEditor({
    super.key,
    this.initialCV,
    required this.title,
    required this.onSubmit,
    this.initialText,
    this.type = 'default',
  });

  @override
  State<CVPopupEditor> createState() => _CVPopupEditorState();
}

class _CVPopupEditorState extends State<CVPopupEditor> {
  final GlobalKey<QuillTextEditorState> _editorKey = GlobalKey();

  String content = '';
  Map<String, dynamic> contactData = {};
  Map<String, dynamic> pendingData = {};

  @override
  void initState() {
    super.initState();
    content = widget.initialText ?? '';
  }

  void _handleSubmit([String? updatedText]) async {
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
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Save failed')),
        );
      }
      return;
    }

    debugPrint('Pending data: $pendingData');

    // Tüm diğer tipler (contact, skills, education, etc.)
    final response = await api.post(context, 'update_cv', {
      widget.type!: pendingData, // örnek: { "contact": {...} }
    });

    debugPrint('Response: $pendingData \n Responsed: $response');

    if (response['success'] == true) {
      widget.onSubmit("success");
      Navigator.pop(context);
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Save failed')),
      );
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
        ElevatedButton(
          onPressed: () => _handleSubmit(content),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
