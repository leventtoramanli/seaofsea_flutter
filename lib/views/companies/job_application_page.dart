import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/api_manager.dart';
import 'package:seaofsea/widgets/custon_scaffold.dart';

class JobApplicationPage extends StatefulWidget {
  const JobApplicationPage({super.key});

  @override
  State<JobApplicationPage> createState() => _JobApplicationPageState();
}

class _JobApplicationPageState extends State<JobApplicationPage> {
  final TextEditingController _messageController = TextEditingController();
  String? _selectedPosition;
  String? _filePath;

  final List<String> _positions = [
    'Captain',
    'Chief Officer',
    'Engineer',
    'Deckhand',
  ];

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      setState(() => _filePath = result.files.single.path);
    }
  }

  Future<void> _submitApplication() async {
    final api = Provider.of<ApiManager>(context, listen: false);
    final Map<String, dynamic> body = {
      'position': _selectedPosition,
      'message': _messageController.text,
    };
    if (_filePath != null) {
      final bytes = await File(_filePath!).readAsBytes();
      body['file_name'] = _filePath!.split('/').last;
      body['file_data'] = base64Encode(bytes);
    }
    await api.post(context, 'apply_job', body);
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Job Application',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Position',
                border: OutlineInputBorder(),
              ),
              value: _selectedPosition,
              items: _positions
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedPosition = value),
              validator: (value) => value == null ? 'Select a position' : null,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Application Message',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Choose File'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _filePath != null
                        ? _filePath!.split('/').last
                        : 'No file selected',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _submitApplication,
              icon: const Icon(Icons.send),
              label: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }
}
