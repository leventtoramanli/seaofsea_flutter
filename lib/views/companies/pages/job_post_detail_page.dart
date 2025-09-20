import 'dart:convert' show base64Encode;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:seaofsea/services/v1/recruitment_service.dart';
import 'package:seaofsea/utils/app_exceptions.dart';
import 'package:seaofsea/widgets/custon_scaffold.dart';

class JobPostDetailPage extends StatefulWidget {
  final int postId;
  const JobPostDetailPage({super.key, required this.postId});

  @override
  State<JobPostDetailPage> createState() => _JobPostDetailPageState();
}

class _JobPostDetailPageState extends State<JobPostDetailPage> {
  bool _busy = false;
  String? _error;

  Map<String, dynamic>? _post; // job_posts row
  Map<String, dynamic>? _appStats; // {by_status:{...}, total, active}
  List<dynamic> _recentApps = const []; // recent applications

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  Future<void> _fetch() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // Combined overview: post + application stats + recent applications
      final res = await RecruitmentServiceV1.postOverview(
        id: widget.postId,
        recent: 10,
      );
      final Map? data =
          (res is Map && res['data'] is Map) ? (res['data'] as Map) : null;

      if (data != null) {
        _post = (data['post'] is Map)
            ? Map<String, dynamic>.from(data['post'] as Map)
            : null;
        _appStats = (data['app_stats'] is Map)
            ? Map<String, dynamic>.from(data['app_stats'] as Map)
            : null;
        _recentApps = (data['recent_applications'] is List)
            ? List<dynamic>.from(data['recent_applications'] as List)
            : const [];
      } else {
        _error = 'Response data is null or invalid';
      }
    } catch (_) {
      // Fallback: public detail only (no internal stats)
      try {
        final res2 =
            await RecruitmentServiceV1.postPublicDetail(id: widget.postId);
        dynamic d2 = (res2 is Map) ? res2['data'] ?? res2 : res2;
        if (d2 is Map && d2['data'] != null) d2 = d2['data'];
        _post = (d2 is Map) ? Map<String, dynamic>.from(d2) : null;
        _appStats = null;
        _recentApps = const [];
        _error = 'Not authorized to view applications';
      } catch (e2) {
        _error = 'Failed to load: $e2';
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
              child:
                  Text(k, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            const Text(':  '),
            Expanded(child: Text(v)),
          ],
        ),
      );

  Widget _chip(String label, int v, {IconData? icon}) {
    return Chip(
      avatar: icon != null ? Icon(icon, size: 18) : null,
      label: Text('$label: $v'),
      side: const BorderSide(color: Colors.black12),
    );
  }

  Future<bool?> _showCvGateDialog({
    required BuildContext context,
    required int percent,
    required int minRequired,
    required List<String> missingLabels,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text('Complete your profile ($percent% / $minRequired%)'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    'Complete your profile and CV to apply for this job:'),
                const SizedBox(height: 8),
                if (missingLabels.isEmpty)
                  const Text('You are good to go — please try again.')
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        missingLabels.map((e) => Chip(label: Text(e))).toList(),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Maybe later'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.edit),
              onPressed: () => Navigator.pop(context, true),
              label: const Text('Update profile now'),
            ),
          ],
        );
      },
    );
  }

  String _guessMime(String? ext) {
    final e = (ext ?? '').toLowerCase();
    switch (e) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
    }
    return 'application/octet-stream';
  }

  @override
  Widget build(BuildContext context) {
    final post = _post ?? const {};
    final title = (post['title'] ?? 'Post').toString();
    final status = (post['status'] ?? '').toString();
    final companyId = _toInt(post['company_id']);
    final createdAt = (post['created_at'] ?? '').toString();
    final location = (post['location'] ?? '').toString();
    final empTypes = post['employment_type'].toString();
    final desc = (post['description'] ?? '').toString();
    final bool isPublicOpen = (post['status'] == 'published') &&
        ((post['visibility'] ?? 'public') == 'public');

    String humanize(String code) => code
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
    final empType = empTypes.isEmpty ? '' : humanize(empTypes);

    return CustomScaffold(
      title: 'Job Post #${widget.postId}',
      body: _busy && _post == null
          ? const Center(child: CircularProgressIndicator())
          : _post == null
              ? Center(child: Text(_error ?? 'Record not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        elevation: 0.5,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title,
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Chip(label: Text('Status: $status')),
                                  if (companyId > 0)
                                    Chip(label: Text('Company #$companyId')),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _kv('Location',
                                  location.isEmpty ? '-' : location),
                              _kv('Work type', empType.isEmpty ? '-' : empType),
                              _kv('Created at',
                                  createdAt.isEmpty ? '-' : createdAt),
                              const SizedBox(height: 8),
                              if (desc.isNotEmpty) _kv('Description', desc),
                              if (_error != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    _error!,
                                    style:
                                        const TextStyle(color: Colors.orange),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      // Apply action (only for public & open posts)
                      if (_post != null && isPublicOpen) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            icon: const Icon(Icons.send),
                            label: const Text('Apply'),
                            onPressed: () async {
                              final j = _post!;
                              final companyId = _toInt(j['company_id']);
                              final jobId = _toInt(j['id']);
                              if (companyId <= 0 || jobId <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Invalid job post'),
                                  ),
                                );
                                return;
                              }

                              // 1) CV/Profile gate
                              try {
                                final cv = await RecruitmentServiceV1
                                    .cvProfilePercent();
                                final int percent = (cv['percent'] is int)
                                    ? cv['percent'] as int
                                    : int.tryParse('${cv['percent']}') ?? 0;
                                final int minReq = (cv['required_min'] is int)
                                    ? cv['required_min'] as int
                                    : int.tryParse('${cv['required_min']}') ??
                                        50;

                                final List<String> missingLabels = (() {
                                  final raw = cv['missing_labels'] ??
                                      cv['missing'] ??
                                      [];
                                  if (raw is List) {
                                    return raw.map((e) => '$e').toList();
                                  }
                                  return const <String>[];
                                })();

                                if (percent < minReq) {
                                  final goProfile = await _showCvGateDialog(
                                    context: context,
                                    percent: percent,
                                    minRequired: minReq,
                                    missingLabels: missingLabels,
                                  );
                                  if (goProfile == true) {
                                    if (!mounted) return;
                                    // Adjust this route to your real profile/CV editor
                                    Navigator.pushNamed(
                                        context, '/profile_edit');
                                  }
                                  return; // block apply
                                }
                              } catch (_) {
                                // If the CV endpoint fails, do not block apply for now.
                              }

                              // 2) Apply dialog — cover letter + include snapshot + attachments
                              String cover = '';
                              bool includeSnapshotResult = true;
                              List<Map<String, dynamic>> attachmentsResult = [];

                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (_) {
                                  final ctrl = TextEditingController();
                                  bool includeSnapshot = true;
                                  List<Map<String, dynamic>> pickedFiles = [];

                                  return StatefulBuilder(
                                    builder: (ctx, setD) {
                                      return AlertDialog(
                                        title: const Text('Apply'),
                                        content: SingleChildScrollView(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              TextField(
                                                controller: ctrl,
                                                maxLines: 5,
                                                decoration:
                                                    const InputDecoration(
                                                  hintText:
                                                      'Short cover letter (optional)',
                                                  border: OutlineInputBorder(),
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  Switch(
                                                    value: includeSnapshot,
                                                    onChanged: (v) => setD(() =>
                                                        includeSnapshot = v),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  const Expanded(
                                                    child: Text(
                                                        'Include CV snapshot'),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              OutlinedButton.icon(
                                                icon: const Icon(
                                                    Icons.attach_file),
                                                label: const Text(
                                                    'Add attachments'),
                                                onPressed: () async {
                                                  final res = await FilePicker
                                                      .platform
                                                      .pickFiles(
                                                    type: FileType.custom,
                                                    allowMultiple: true,
                                                    withData: true,
                                                    allowedExtensions: [
                                                      'pdf',
                                                      'doc',
                                                      'docx',
                                                      'jpg',
                                                      'jpeg',
                                                      'png'
                                                    ],
                                                  );
                                                  if (res == null) return;
                                                  const maxCount = 6;
                                                  const maxSize =
                                                      5 * 1024 * 1024; // 5MB
                                                  final files =
                                                      <Map<String, dynamic>>[];

                                                  for (final f in res.files
                                                      .take(maxCount)) {
                                                    if (f.bytes == null)
                                                      continue;
                                                    if (f.size > maxSize)
                                                      continue;
                                                    files.add({
                                                      'name': f.name,
                                                      'size': f.size,
                                                      'mime': _guessMime(
                                                          f.extension),
                                                      'b64': base64Encode(
                                                          f.bytes!),
                                                    });
                                                  }
                                                  setD(() =>
                                                      pickedFiles = files);
                                                },
                                              ),
                                              if (pickedFiles.isNotEmpty) ...[
                                                const SizedBox(height: 8),
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 8,
                                                  children: pickedFiles
                                                      .map(
                                                        (m) => Chip(
                                                          label: Text(m['name']
                                                              as String),
                                                          onDeleted: () {
                                                            setD(() =>
                                                                pickedFiles
                                                                    .remove(m));
                                                          },
                                                        ),
                                                      )
                                                      .toList(),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text('Cancel'),
                                          ),
                                          FilledButton(
                                            onPressed: () {
                                              cover = ctrl.text.trim();
                                              includeSnapshotResult =
                                                  includeSnapshot;
                                              attachmentsResult = List<
                                                      Map<String,
                                                          dynamic>>.from(
                                                  pickedFiles);
                                              Navigator.pop(ctx, true);
                                            },
                                            child: const Text('Submit'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              );

                              if (ok != true) return;

                              // 3) Submit once, then route to My Applications
                              int? _extractId(dynamic res) {
                                if (res is Map) {
                                  dynamic d = res['data'] ?? res;
                                  if (d is Map && d['data'] != null)
                                    d = d['data'];
                                  final v = (d is Map) ? d['id'] : null;
                                  if (v is int) return v;
                                  if (v is String) return int.tryParse(v);
                                }
                                return null;
                              }

                              try {
                                final submitRes =
                                    await RecruitmentServiceV1.appSubmit(
                                  companyId: companyId,
                                  jobPostId: jobId,
                                  coverLetter: cover.isEmpty ? null : cover,
                                  attachments: attachmentsResult.isEmpty
                                      ? null
                                      : attachmentsResult,
                                  includeCvSnapshot:
                                      includeSnapshotResult ? 1 : 0,
                                );

                                if (!mounted) return;
                                final newId = _extractId(submitRes);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Applied successfully.'),
                                  ),
                                );

                                await Future.delayed(
                                    const Duration(milliseconds: 300));
                                if (!mounted) return;

                                Navigator.pushNamed(
                                  context,
                                  '/my_applications',
                                  arguments: {
                                    if (newId != null) 'highlight_id': newId,
                                  },
                                );
                              } on EmailVerificationRequired catch (e) {
                                if (!mounted) return;
                                showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                          title: const Text(
                                              'Email Verification Required'),
                                          content: const Text(
                                              'Please verify your email address before applying.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('OK'),
                                            ),
                                          ],
                                        ));
                              } catch (e) {
                                final msg = '$e';
                                final already = msg.contains('409') ||
                                    msg
                                        .toLowerCase()
                                        .contains('active application');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      already
                                          ? 'You already have an active application.'
                                          : 'Application failed: $msg',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],

                      // Application stats (if authorized)
                      if (_appStats != null) ...[
                        const SizedBox(height: 12),
                        Card(
                          elevation: 0.5,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Application Stats',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _chip('Total', _toInt(_appStats!['total']),
                                        icon: Icons.summarize_outlined),
                                    _chip(
                                        'Active', _toInt(_appStats!['active']),
                                        icon: Icons.timelapse_outlined),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Builder(
                                  builder: (ctx) {
                                    final Map by =
                                        (_appStats!['by_status'] is Map)
                                            ? (_appStats!['by_status'] as Map)
                                            : {};
                                    return Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _chip('Submitted',
                                            _toInt(by['submitted'])),
                                        _chip('Under review',
                                            _toInt(by['under_review'])),
                                        _chip('Shortlisted',
                                            _toInt(by['shortlisted'])),
                                        _chip('Interview',
                                            _toInt(by['interview'])),
                                        _chip('Offered', _toInt(by['offered'])),
                                        _chip('Hired', _toInt(by['hired'])),
                                        _chip(
                                            'Rejected', _toInt(by['rejected'])),
                                        _chip('Withdrawn',
                                            _toInt(by['withdrawn'])),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Recent applications (if any)
                        const SizedBox(height: 12),
                        Card(
                          elevation: 0.5,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Last Applications',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                const SizedBox(height: 8),
                                if (_recentApps.isEmpty)
                                  const Text('No recent applications')
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _recentApps.length,
                                    separatorBuilder: (_, __) =>
                                        const Divider(height: 1),
                                    itemBuilder: (ctx, i) {
                                      final it = _recentApps[i] as Map;
                                      final id = it['id']?.toString() ?? '-';
                                      final userId =
                                          it['user_id']?.toString() ?? '-';
                                      final status =
                                          (it['status'] ?? '').toString();
                                      final created =
                                          (it['created_at'] ?? '').toString();
                                      final reviewer =
                                          it['reviewer_user_id']?.toString();
                                      return ListTile(
                                        dense: true,
                                        leading: CircleAvatar(
                                          radius: 14,
                                          child: Text(id),
                                        ),
                                        title:
                                            Text('User #$userId  •  $status'),
                                        subtitle: Text(
                                          '$created${(reviewer == null || reviewer == 'null') ? '' : ' • Reviewer #$reviewer'}',
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}
