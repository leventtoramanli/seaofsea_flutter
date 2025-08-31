// Company job list (company internal view)
// - Uses RecruitmentServiceV1.postList / postPublish / postClose / postUpdate / postCreate
// - Keeps UI simple; only service calls changed.
// - You can wrap action buttons with your PermissionGate if desired.

import 'package:flutter/material.dart';
import 'package:seaofsea/services/v1/recruitment_service.dart';
import 'package:seaofsea/views/companies/company_detail_page.dart';
import 'package:seaofsea/views/companies/pages/job_post_detail_page.dart';

class CompanyJobListPage extends StatefulWidget {
  final int companyId;

  const CompanyJobListPage({
    super.key,
    required this.companyId,
  });

  @override
  State<CompanyJobListPage> createState() => _CompanyJobListPageState();
}

class _CompanyJobListPageState extends State<CompanyJobListPage> {
  final TextEditingController _searchCtrl = TextEditingController();

  bool _busy = false;
  String? _statusFilter; // 'draft' | 'published' | 'closed' | 'archived' | null
  int _page = 1;
  int _perPage = 25;
  int _total = 0;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _busy = true);
    try {
      final res = await RecruitmentServiceV1.postList(
        companyId: widget.companyId,
        status: _statusFilter,
        q: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
        page: _page,
        perPage: _perPage,
      );

      final data = (res is Map) ? (res['data'] as Map?) : null;
      final items = (data?['items'] as List?) ?? const [];
      final total = (data?['total'] as int?) ?? items.length;

      setState(() {
        _items = items;
        _total = total;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Listeleme başarısız: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  int get _pages => (_total == 0) ? 1 : ((_total + _perPage - 1) ~/ _perPage);

  Future<void> _publish(int id) async {
    setState(() => _busy = true);
    try {
      await RecruitmentServiceV1.postPublish(id: id);
      await _fetch();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İlan yayınlandı')),
        );
      }
    } catch (e) {
      _showError('Yayınlama hatası: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _close(int id) async {
    setState(() => _busy = true);
    try {
      await RecruitmentServiceV1.postClose(id: id);
      await _fetch();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İlan kapatıldı')),
        );
      }
    } catch (e) {
      _showError('Kapatma hatası: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _updateDialog(Map item) async {
    final titleCtrl =
        TextEditingController(text: (item['title'] ?? '').toString());
    final descCtrl =
        TextEditingController(text: (item['description'] ?? '').toString());
    final posIdCtrl =
        TextEditingController(text: item['position_id']?.toString() ?? '');
    final locCtrl =
        TextEditingController(text: (item['location'] ?? '').toString());
    final typeCtrl =
        TextEditingController(text: (item['employment_type'] ?? '').toString());

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('İlanı Düzenle'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Başlık')),
              TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Açıklama'),
                  maxLines: 4),
              TextField(
                  controller: posIdCtrl,
                  decoration: const InputDecoration(labelText: 'Position ID'),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: locCtrl,
                  decoration: const InputDecoration(labelText: 'Lokasyon')),
              TextField(
                  controller: typeCtrl,
                  decoration:
                      const InputDecoration(labelText: 'İstihdam Türü')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _update(
                id: item['id'] as int,
                title: titleCtrl.text.trim().isEmpty
                    ? null
                    : titleCtrl.text.trim(),
                description:
                    descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                positionId: int.tryParse(posIdCtrl.text.trim()),
                location:
                    locCtrl.text.trim().isEmpty ? null : locCtrl.text.trim(),
                employmentType:
                    typeCtrl.text.trim().isEmpty ? null : typeCtrl.text.trim(),
              );
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Future<void> _update({
    required int id,
    String? title,
    String? description,
    int? positionId,
    String? location,
    String? employmentType,
  }) async {
    setState(() => _busy = true);
    try {
      await RecruitmentServiceV1.postUpdate(
        id: id,
        title: title,
        description: description,
        positionId: positionId,
        location: location,
        employmentType: employmentType,
      );
      await _fetch();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Güncellendi')),
        );
      }
    } catch (e) {
      _showError('Güncelleme hatası: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createDialog() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final posIdCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final typeCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni İlan'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Başlık')),
              TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Açıklama'),
                  maxLines: 4),
              TextField(
                  controller: posIdCtrl,
                  decoration: const InputDecoration(labelText: 'Position ID'),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: locCtrl,
                  decoration: const InputDecoration(labelText: 'Lokasyon')),
              TextField(
                  controller: typeCtrl,
                  decoration:
                      const InputDecoration(labelText: 'İstihdam Türü')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          FilledButton(
            onPressed: () async {
              final title = titleCtrl.text.trim();
              if (title.isEmpty) return;

              Navigator.pop(ctx);
              await _create(
                title: title,
                description:
                    descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                positionId: int.tryParse(posIdCtrl.text.trim()),
                location:
                    locCtrl.text.trim().isEmpty ? null : locCtrl.text.trim(),
                employmentType:
                    typeCtrl.text.trim().isEmpty ? null : typeCtrl.text.trim(),
              );
            },
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
  }

  Future<void> _create({
    required String title,
    String? description,
    int? positionId,
    String? location,
    String? employmentType,
  }) async {
    setState(() => _busy = true);
    try {
      await RecruitmentServiceV1.postCreate(
        companyId: widget.companyId,
        title: title,
        description: description,
        positionId: positionId,
        location: location,
        employmentType: employmentType,
      );
      // yeni kayıt listede en üstte gelsin diye sayfayı 1'e çekip fetch
      setState(() => _page = 1);
      await _fetch();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İlan oluşturuldu (taslak).')),
        );
      }
    } catch (e) {
      _showError('Oluşturma hatası: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final statuses = <String?>[
      null,
      'draft',
      'published',
      'closed',
      'archived'
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Şirket İlanları'),
        actions: [
          // NOT: Burayı PermissionGate ile sarmalayabilirsin:
          // PermissionGate('recruitment.post.create', widget.companyId, child: ...)
          IconButton(
            tooltip: 'Yeni ilan',
            onPressed: _busy ? null : _createDialog,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          // Arama & Filtre
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _searchCtrl,
                    onSubmitted: (_) {
                      setState(() => _page = 1);
                      _fetch();
                    },
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Ara (başlık / açıklama)',
                      suffixIcon: IconButton(
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _page = 1);
                          _fetch();
                        },
                        icon: const Icon(Icons.clear),
                      ),
                    ),
                  ),
                ),
                DropdownButton<String?>(
                  value: _statusFilter,
                  items: statuses
                      .map((s) => DropdownMenuItem<String?>(
                            value: s,
                            child: Text(s == null ? 'Tümü' : s),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _statusFilter = val;
                      _page = 1;
                    });
                    _fetch();
                  },
                ),
                const SizedBox(width: 12),
                if (_busy)
                  const SizedBox(
                      width: 20,
                      height: 20,
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
                          final title = (it['title'] ?? '').toString();
                          final status = (it['status'] ?? '').toString();
                          final createdAt = (it['created_at'] ?? '').toString();

                          return ListTile(
                            title: Text(title,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle:
                                Text('Durum: $status • Oluşturma: $createdAt'),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => JobPostDetailPage(postId: id),
                                ),
                              );
                            },
                            trailing: Wrap(
                              spacing: 8,
                              children: [
                                // NOT: Aşağıdaki butonları PermissionGate ile sarmalayabilirsin.
                                IconButton(
                                  tooltip: 'Düzenle',
                                  onPressed:
                                      _busy ? null : () => _updateDialog(it),
                                  icon: const Icon(Icons.edit),
                                ),
                                if (status != 'published')
                                  IconButton(
                                    tooltip: 'Yayınla',
                                    onPressed:
                                        _busy ? null : () => _publish(id),
                                    icon: const Icon(Icons.campaign_outlined),
                                  ),
                                if (status != 'closed' && status != 'archived')
                                  IconButton(
                                    tooltip: 'Kapat',
                                    onPressed: _busy ? null : () => _close(id),
                                    icon: const Icon(Icons.close),
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
