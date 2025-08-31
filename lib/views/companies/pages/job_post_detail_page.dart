import 'package:flutter/material.dart';
import 'package:seaofsea/services/v1/recruitment_service.dart';
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
      // Birleşik özet: ilan + başvuru istatistikleri + son başvurular
      final res = await RecruitmentServiceV1.postOverview(
          id: widget.postId, recent: 10);
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
        _error = 'Geçersiz cevap';
      }
    } catch (e) {
      // 403 olabilir (app.view_company izni yok). Fallback: sadece ilan detayını getir.
      try {
        final res2 = await RecruitmentServiceV1.postDetail(id: widget.postId);
        final Map? data2 =
            (res2 is Map && res2['data'] is Map) ? (res2['data'] as Map) : null;
        _post = (data2 != null) ? Map<String, dynamic>.from(data2) : null;
        _appStats = null;
        _recentApps = const [];
        _error = 'Başvuru özetine erişim yok (sadece ilan bilgisi).';
      } catch (e2) {
        _error = 'Yüklenemedi: $e2';
      }
    } finally {
      if (mounted)
        setState(() {
          _busy = false;
        });
    }
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 140,
                child: Text(k,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
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

  @override
  Widget build(BuildContext context) {
    final post = _post ?? const {};
    final title = (post['title'] ?? 'İlan').toString();
    final status = (post['status'] ?? '').toString();
    final companyId = _toInt(post['company_id']);
    final createdAt = (post['created_at'] ?? '').toString();
    final location = (post['location'] ?? '').toString();
    final empType = (post['employment_type'] ?? '').toString();
    final desc = (post['description'] ?? '').toString();

    return CustomScaffold(
      title: 'Job Post #${widget.postId}',
      body: _busy && _post == null
          ? const Center(child: CircularProgressIndicator())
          : _post == null
              ? Center(child: Text(_error ?? 'Kayıt bulunamadı'))
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
                              Wrap(spacing: 8, runSpacing: 8, children: [
                                Chip(label: Text('Durum: $status')),
                                if (companyId > 0)
                                  Chip(label: Text('Şirket #$companyId')),
                              ]),
                              const SizedBox(height: 12),
                              _kv('Lokasyon',
                                  location.isEmpty ? '-' : location),
                              _kv('İstihdam Türü',
                                  empType.isEmpty ? '-' : empType),
                              _kv('Oluşturma',
                                  createdAt.isEmpty ? '-' : createdAt),
                              const SizedBox(height: 8),
                              if (desc.isNotEmpty) _kv('Açıklama', desc),
                              if (_error != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(_error!,
                                      style: const TextStyle(
                                          color: Colors.orange)),
                                ),
                            ],
                          ),
                        ),
                      ),

                      // Başvuru özet kartı (izin varsa)
                      if (_appStats != null) ...[
                        const SizedBox(height: 12),
                        Card(
                          elevation: 0.5,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Başvuru Özeti',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                const SizedBox(height: 8),
                                Wrap(spacing: 8, runSpacing: 8, children: [
                                  _chip('Toplam', _toInt(_appStats!['total']),
                                      icon: Icons.summarize_outlined),
                                  _chip('Aktif', _toInt(_appStats!['active']),
                                      icon: Icons.timelapse_outlined),
                                ]),
                                const SizedBox(height: 6),
                                Builder(builder: (ctx) {
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
                                      ]);
                                }),
                              ],
                            ),
                          ),
                        ),

                        // Son başvurular
                        const SizedBox(height: 12),
                        Card(
                          elevation: 0.5,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Son Başvurular',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                const SizedBox(height: 8),
                                if (_recentApps.isEmpty)
                                  const Text('Kayıt yok')
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
                                            radius: 14, child: Text(id)),
                                        title:
                                            Text('User #$userId  •  $status'),
                                        subtitle: Text(
                                            '$created${(reviewer == null || reviewer == 'null') ? '' : ' • Reviewer #$reviewer'}'),
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
