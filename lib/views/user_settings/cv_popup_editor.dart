import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/services/custom_text_editor.dart';
import 'package:seaofsea/utils/api_manager.dart';
import 'package:seaofsea/utils/auth_provider.dart';
import 'package:seaofsea/views/user_settings/contact_form_section_cv.dart';

class CVPopupEditor extends StatefulWidget {
  final String title;
  final String? initialText;
  final String? type;
  final Function(String) onSubmit;

  const CVPopupEditor({
    super.key,
    required this.title,
    required this.onSubmit,
    this.initialText,
    this.type = 'default',
  });

  @override
  State<CVPopupEditor> createState() => _CVPopupEditorState();
}

class _CVPopupEditorState extends State<CVPopupEditor> {
  String content = '';
  Map<String, dynamic> contactData = {};

  @override
  void initState() {
    super.initState();
    content = widget.initialText ?? '';
  }

  void _handleSubmit([String? updatedText]) async {
    final api = Provider.of<ApiManager>(context, listen: false);
    switch (widget.type) {
      case 'default':
        // QuillTextEditor için
        setState(() {
          content = updatedText ?? content;
        });
        widget.onSubmit(content);
        Navigator.pop(context);
        break;

      case 'contact':
        final response = await api.post(context, 'save_user_cv_contact', {
          ...contactData,
        });

        if (response['success'] == true) {
          widget.onSubmit("success");
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Save failed')),
          );
        }
        break;
      default:
        debugPrint('No handler implemented for type: ${widget.type}');
        break;
    }
  }

  Widget _buildDialogContent(String type) {
    switch (type) {
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
                onChanged: (data) => contactData = data,
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
