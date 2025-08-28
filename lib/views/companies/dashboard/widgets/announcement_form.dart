import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/services/v1/v1_api_manager.dart';
import 'package:seaofsea/views/companies/dashboard/services/announcements_service.dart';

class AnnouncementFormCard extends StatefulWidget {
  final int companyId;
  final VoidCallback? onCancel;
  final void Function(int? id)? onCreated; // success callback (id opsiyonel)

  const AnnouncementFormCard({
    super.key,
    required this.companyId,
    this.onCancel,
    this.onCreated,
  });

  @override
  State<AnnouncementFormCard> createState() => _AnnouncementFormCardState();
}

class _AnnouncementFormCardState extends State<AnnouncementFormCard> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  String _visibility = 'public'; // public | followers | internal
  bool _pinned = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final v1 = context.read<V1ApiManager>();
      final svc = AnnouncementsService(v1);

      final ok = await svc.create(
        companyId: widget.companyId,
        title: _titleCtrl.text.trim(),
        body: _bodyCtrl.text.trim().isEmpty ? null : _bodyCtrl.text.trim(),
        visibility: _visibility,
        pinned: _pinned,
        context: context,
      );

      if (!mounted) return;

      if (ok) {
        widget.onCreated?.call(null);
      } else {
        setState(() => _error = 'Failed to publish announcement.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Error: $e');
    } finally {
      if (!mounted) return;
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.campaign_outlined, size: 20),
                  const SizedBox(width: 8),
                  Text('New announcement', style: theme.textTheme.titleMedium),
                  const Spacer(),
                  TextButton(
                    onPressed: _submitting ? null : widget.onCancel,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: const Text('Publish'),
                  ),
                ],
              ),
              const Divider(height: 16),

              // Title
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: 12),

              // Body
              TextFormField(
                controller: _bodyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Body (optional)',
                  border: OutlineInputBorder(),
                ),
                minLines: 3,
                maxLines: 6,
              ),
              const SizedBox(height: 12),

              // Visibility + Pinned
              Row(
                children: [
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Visibility',
                        border: OutlineInputBorder(),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _visibility,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(
                              value: 'public',
                              child: Text('Public'),
                            ),
                            DropdownMenuItem(
                              value: 'followers',
                              child: Text('Followers'),
                            ),
                            DropdownMenuItem(
                              value: 'internal',
                              child: Text('Internal'),
                            ),
                          ],
                          onChanged: _submitting
                              ? null
                              : (v) =>
                                  setState(() => _visibility = v ?? 'public'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Pinned'),
                      const SizedBox(width: 8),
                      Switch(
                        value: _pinned,
                        onChanged: _submitting
                            ? null
                            : (v) => setState(() => _pinned = v),
                      ),
                    ],
                  ),
                ],
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
