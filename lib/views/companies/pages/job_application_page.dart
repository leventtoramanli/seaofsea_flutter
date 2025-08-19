import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:seaofsea/services/v1/v1_api_manager.dart';
import 'package:seaofsea/widgets/custon_scaffold.dart';

class JobApplicationPage extends StatefulWidget {
  /// Başvuru hangi şirkete yapılacak? Zorunlu değil; null ise "genel başvuru" gibi davranır.
  final int? companyId;
  final String? companyName;

  const JobApplicationPage({super.key, this.companyId, this.companyName});

  @override
  State<JobApplicationPage> createState() => _JobApplicationPageState();
}

class _JobApplicationPageState extends State<JobApplicationPage> {
  final V1ApiManager v1 = V1ApiManager();

  final TextEditingController _messageController = TextEditingController();

  // Pozisyonlar için: önce sunucudan dener, olmazsa fallback kullanır.
  List<String> _positions = [];
  static const List<String> _fallbackPositions = [
    'Captain',
    'Chief Officer',
    'Engineer',
    'Deckhand',
  ];
  String? _selectedPosition;

  // Dosya seçimi
  File? _pickedFile;
  String? _pickedFileName;

  // UI state
  bool _loadingPositions = false;
  bool _submitting = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchPositions();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _fetchPositions() async {
    setState(() => _loadingPositions = true);

    try {
      // Önerilen V1 endpoint (PHP tarafını buna göre yazabilirsin):
      // module: 'position', action: 'list'
      // Beklenen response:
      // { success:true, data:{ items:[{name:'Captain'}, ...] } }  veya  { success:true, data:[{name:'Captain'}, ...] }
      final res = await v1.call(
        module: 'position',
        action: 'list',
        params: const {'perPage': 200},
        // positions endpoint’i public olabilir; requiresAuth=true kalabilir
        context: context,
      );

      List<String> names = [];
      final data = res['data'];
      if (res['success'] == true && data != null) {
        final items = (data is Map && data['items'] is List)
            ? List.from(data['items'])
            : (data is List ? List.from(data) : null);

        if (items != null) {
          names = items
              .map((e) =>
                  (e is Map ? (e['name'] ?? '').toString() : e.toString()))
              .where((s) => s.trim().isNotEmpty)
              .cast<String>()
              .toList();
        }
      }

      setState(() {
        _positions = names.isNotEmpty ? names : _fallbackPositions;
        // mevcut seçimi koru; yoksa ilk elemana default
        _selectedPosition ??= _positions.isNotEmpty ? _positions.first : null;
      });
    } catch (_) {
      setState(() {
        _positions = _fallbackPositions;
        _selectedPosition ??= _positions.first;
      });
    } finally {
      if (mounted) setState(() => _loadingPositions = false);
    }
  }

  Future<void> _pickFile() async {
    final res = await FilePicker.platform.pickFiles(withData: false);
    if (res != null && res.files.isNotEmpty) {
      final path = res.files.single.path;
      if (path != null) {
        setState(() {
          _pickedFile = File(path);
          _pickedFileName = res.files.single.name;
        });
      }
    }
  }

  void _removeFile() {
    setState(() {
      _pickedFile = null;
      _pickedFileName = null;
    });
  }

  // Basit içerik tipi kestirimi (gerekmezse null bırakabiliriz)
  String? _guessMimeType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (lower.endsWith('.doc')) return 'application/msword';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.txt')) return 'text/plain';
    return null; // Dio null gönderirse de sorun olmaz
    // (V1ApiManager zaten null contentType ile form-data yükleyebiliyor.)
  }

  Future<void> _submit() async {
    if (_selectedPosition == null || _selectedPosition!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a position.')),
      );
      return;
    }

    setState(() {
      _submitting = true;
      _uploadProgress = 0.0;
    });

    try {
      // Önerilen V1 endpoint (PHP tarafında yazacaksın):
      // module: 'job', action: 'apply'
      // Parametreler:
      // - company_id (opsiyonel, eğer şirkete özgü başvuru ise)
      // - position (zorunlu)
      // - message (opsiyonel)
      // - file (form-data dosya alanı) — V1ApiManager otomatik ekliyor
      //
      // Dönüş:
      // { success:true, data:{ application_id: 123 } } gibi.
      final res = await v1.call(
        module: 'job',
        action: 'apply',
        params: {
          if (widget.companyId != null) 'company_id': widget.companyId,
          'position': _selectedPosition,
          'message': _messageController.text.trim(),
        },
        context: context,
        file: _pickedFile,
        fileName: _pickedFileName,
        fileType:
            _pickedFileName != null ? _guessMimeType(_pickedFileName!) : null,
        onProgress: (p) {
          // p: 0..1
          if (mounted) {
            setState(() => _uploadProgress = p);
          }
        },
      );

      if (res['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application submitted successfully.')),
        );
        Navigator.pop(context, true);
      } else {
        final msg = (res['message'] ?? 'Application failed.').toString();
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('❌ $msg')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: widget.companyName != null
          ? 'Job Application — ${widget.companyName}'
          : 'Job Application',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            if (widget.companyId == null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'General Application',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            // Position
            if (_loadingPositions)
              const Padding(
                padding: EdgeInsets.only(top: 8, bottom: 16),
                child: LinearProgressIndicator(minHeight: 3),
              ),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Position',
                border: OutlineInputBorder(),
              ),
              value: _selectedPosition,
              isExpanded: true,
              items: _positions
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: _submitting
                  ? null
                  : (v) => setState(() => _selectedPosition = v),
            ),
            const SizedBox(height: 16),

            // Message
            TextField(
              controller: _messageController,
              maxLines: 4,
              readOnly: _submitting,
              decoration: const InputDecoration(
                labelText: 'Application Message (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // File picker
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _submitting ? null : _pickFile,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Choose File'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _pickedFileName ?? 'No file selected',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_pickedFile != null && !_submitting)
                  IconButton(
                    tooltip: 'Remove file',
                    onPressed: _removeFile,
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),

            // Upload progress (multipart sırasında)
            if (_submitting && _pickedFile != null) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                  value: _uploadProgress == 0 ? null : _uploadProgress),
              const SizedBox(height: 4),
              Text(
                _uploadProgress == 0
                    ? 'Uploading…'
                    : '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],

            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: const Icon(Icons.send),
              label: Text(_submitting ? 'Sending…' : 'Apply'),
            ),
          ],
        ),
      ),
    );
  }
}
