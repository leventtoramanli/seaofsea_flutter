import 'package:flutter/material.dart';
import 'package:seaofsea/services/v1/recruitment_service.dart';

class CompanyApplicationsPage extends StatefulWidget {
  final int companyId;

  const CompanyApplicationsPage({
    super.key,
    required this.companyId,
  });

  @override
  State<CompanyApplicationsPage> createState() =>
      _CompanyApplicationsPageState();
}

class _CompanyApplicationsPageState extends State<CompanyApplicationsPage> {
  final TextEditingController _searchCtrl =
      TextEditingController(); // ileri arama için saklı
  final TextEditingController _jobPostIdCtrl = TextEditingController();

  bool _busy = false;
  String?
      _statusFilter; // null | submitted|under_review|shortlisted|interview|offered|hired|rejected|withdrawn
  int _page = 1;
  int _perPage = 25;
  int _total = 0;

  List<dynamic> _items = [];
  final List<String?> _statuses = const [
    null,
    'submitted',
    'under_review',
    'shortlisted',
    'interview',
    'offered',
    'hired',
    'rejected',
    'withdrawn',
  ];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _jobPostIdCtrl.dispose();
    super.dispose();
  }

  int get _pages => (_total == 0) ? 1 : ((_total + _perPage - 1) ~/ _perPage);

  Future<void> _fetch() async {
    setState(() => _busy = true);
    try {
      final jobPostId = int.tryParse(_jobPostIdCtrl.text.trim());
      final res = await RecruitmentServiceV1.appListForCompany(
        companyId: widget.companyId,
        status: _statusFilter,
        page: _page,
        perPage: _perPage,
        jobPostId: jobPostId, // backend opsiyonel (ileride filtrelenecek)
      );

      final data = (res is Map) ? (res['data'] as Map?) : null;
      final items = (data?['items'] as List?) ?? const [];
      final total = (data?['total'] as int?) ?? items.length;

      setState(() {
        _items = items;
        _total = total;
      });
    } catch (e) {
      _snack('Listeleme hatası: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _updateStatusDialog(int appId, String current) async {
    String? picked = current;
    final noteCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Başvuru Statüsü'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: picked,
              items: _statuses.where((e) => e != null).map((s) {
                return DropdownMenuItem<String>(
                  value: s!,
                  child: Text(s),
                );
              }).toList(),
              onChanged: (v) => picked = v,
              decoration: const InputDecoration(labelText: 'Yeni statü'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Not (opsiyonel)',
                hintText: 'Değişiklik notu...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          FilledButton(
            onPressed: () async {
              if (picked == null) return;
              Navigator.pop(ctx);
              await _updateStatus(appId, picked!,
                  noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim());
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(int appId, String newStatus, String? note) async {
    setState(() => _busy = true);
    try {
      await RecruitmentServiceV1.appUpdateStatus(
        applicationId: appId,
        newStatus: newStatus,
        note: note,
      );
      await _fetch();
      _snack('Statü güncellendi → $newStatus');
    } catch (e) {
      _snack('Statü güncelleme hatası: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _assignReviewerDialog(int appId) async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reviewer Ata'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Kullanıcı ID',
            hintText: 'ör. 123',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          FilledButton(
            onPressed: () async {
              final id = int.tryParse(ctrl.text.trim());
              if (id == null) return;
              Navigator.pop(ctx);
              await _assignReviewer(appId, id);
            },
            child: const Text('Ata'),
          ),
        ],
      ),
    );
  }

  Future<void> _assignReviewer(int appId, int reviewerUserId) async {
    setState(() => _busy = true);
    try {
      await RecruitmentServiceV1.appAssignReviewer(
        applicationId: appId,
        reviewerUserId: reviewerUserId,
      );
      _snack('Reviewer atandı: $reviewerUserId');
    } catch (e) {
      _snack('Reviewer atama hatası: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addNoteDialog(int appId) async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('İç Not Ekle'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Not metni...',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          FilledButton(
            onPressed: () async {
              final text = ctrl.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(ctx);
              await _addNote(appId, text);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Future<void> _addNote(int appId, String text) async {
    setState(() => _busy = true);
    try {
      await RecruitmentServiceV1.appAddNote(applicationId: appId, note: text);
      _snack('Not eklendi');
    } catch (e) {
      _snack('Not ekleme hatası: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showNotes(int appId) async {
    setState(() => _busy = true);
    try {
      final res = await RecruitmentServiceV1.appNotes(applicationId: appId);
      final Map? data =
          (res is Map && res['data'] is Map) ? (res['data'] as Map) : null;
      final List<dynamic> items = (data != null && data['items'] is List)
          ? List<dynamic>.from(data['items'] as List)
          : const <dynamic>[];

      if (!mounted) return;
      // Basit bottom sheet
      // (İstersen özelleştirilmiş bir not listesi widget'ı kullan)
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (_, scroll) => ListView.separated(
            controller: scroll,
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final it = items[i] as Map;
              final text = (it['text'] ?? '').toString();
              final actor = (it['actor_id'] ?? '').toString();
              final created = (it['created_at'] ?? '').toString();
              return ListTile(
                leading: const Icon(Icons.note_alt_outlined),
                title: Text(text),
                subtitle: Text('by #$actor • $created'),
              );
            },
          ),
        ),
      );
    } catch (e) {
      _snack('Notları çekme hatası: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Başvurular (Şirket)'),
      ),
      body: Column(
        children: [
          // Filtre/Arama barı
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 12,
              spacing: 12,
              children: [
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String?>(
                    value: _statusFilter,
                    items: _statuses
                        .map((s) => DropdownMenuItem<String?>(
                              value: s,
                              child: Text(s == null ? 'Tümü' : s),
                            ))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        _statusFilter = v;
                        _page = 1;
                      });
                      _fetch();
                    },
                    decoration: const InputDecoration(
                      labelText: 'Durum',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: TextField(
                    controller: _jobPostIdCtrl,
                    keyboardType: TextInputType.number,
                    onSubmitted: (_) {
                      setState(() => _page = 1);
                      _fetch();
                    },
                    decoration: const InputDecoration(
                      labelText: 'Job Post ID (ops.)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                if (_busy)
                  const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator()),
              ],
            ),
          ),

          const Divider(height: 1),

          // Liste
          Expanded(
            child: _busy && _items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? const Center(child: Text('Kayıt bulunamadı'))
                    : ListView.separated(
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final it = _items[i] as Map;
                          final id = it['id'] as int;
                          final userId = it['user_id']?.toString() ?? '-';
                          final jobPostId =
                              it['job_post_id']?.toString() ?? '-';
                          final status = (it['status'] ?? '').toString();
                          final createdAt = (it['created_at'] ?? '').toString();

                          return ListTile(
                            leading:
                                CircleAvatar(child: Text((i + 1).toString())),
                            title: Text('Başvuru #$id  •  Kullanıcı #$userId',
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle:
                                Text('Job #$jobPostId • $status • $createdAt'),
                            trailing: Wrap(
                              spacing: 8,
                              children: [
                                // (İstersen PermissionGate ile sarmala: recruitment.app.note.add, .assign, .status.update)
                                IconButton(
                                  tooltip: 'Not ekle',
                                  onPressed:
                                      _busy ? null : () => _addNoteDialog(id),
                                  icon: const Icon(Icons.note_add_outlined),
                                ),
                                IconButton(
                                  tooltip: 'Notları gör',
                                  onPressed:
                                      _busy ? null : () => _showNotes(id),
                                  icon: const Icon(Icons.notes_outlined),
                                ),
                                IconButton(
                                  tooltip: 'Reviewer ata',
                                  onPressed: _busy
                                      ? null
                                      : () => _assignReviewerDialog(id),
                                  icon: const Icon(
                                      Icons.person_add_alt_1_outlined),
                                ),
                                IconButton(
                                  tooltip: 'Statü',
                                  onPressed: _busy
                                      ? null
                                      : () => _updateStatusDialog(id, status),
                                  icon: const Icon(Icons.swap_horiz_outlined),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),

          // Sayfalama
          if (_items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Önceki',
                    onPressed: (_page > 1 && !_busy)
                        ? () {
                            setState(() => _page--);
                            _fetch();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('$_page / $_pages (Toplam: $_total)'),
                  IconButton(
                    tooltip: 'Sonraki',
                    onPressed: (_page < _pages && !_busy)
                        ? () {
                            setState(() => _page++);
                            _fetch();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
