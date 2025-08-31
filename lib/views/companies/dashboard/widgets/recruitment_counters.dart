import 'package:flutter/material.dart';
import 'package:seaofsea/services/v1/recruitment_service.dart';

class RecruitmentCounters extends StatefulWidget {
  final int companyId;
  final int?
      jobPostId; // yalnız belirli ilana göre application kırılımı istersen

  const RecruitmentCounters({
    super.key,
    required this.companyId,
    this.jobPostId,
  });

  @override
  State<RecruitmentCounters> createState() => _RecruitmentCountersState();
}

class _RecruitmentCountersState extends State<RecruitmentCounters> {
  bool _busy = false;
  String? _error;

  // Posts
  int _postDraft = 0,
      _postPub = 0,
      _postClosed = 0,
      _postArchived = 0,
      _postTotal = 0;

  // Applications
  int _appSubmitted = 0,
      _appUnder = 0,
      _appShort = 0,
      _appInterview = 0,
      _appOffered = 0,
      _appHired = 0,
      _appRejected = 0,
      _appWithdrawn = 0,
      _appTotal = 0,
      _appActive = 0,
      _appUnassigned = 0;

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
      final resPosts =
          await RecruitmentServiceV1.postStats(companyId: widget.companyId);
      final resApps = await RecruitmentServiceV1.appStats(
          companyId: widget.companyId, jobPostId: widget.jobPostId);

      // ---- posts ----
      final Map? dataP = (resPosts is Map && resPosts['data'] is Map)
          ? (resPosts['data'] as Map)
          : null;
      final Map byP = (dataP != null && dataP['by_status'] is Map)
          ? (dataP['by_status'] as Map)
          : <String, dynamic>{};
      _postDraft = _toInt(byP['draft']);
      _postPub = _toInt(byP['published']);
      _postClosed = _toInt(byP['closed']);
      _postArchived = _toInt(byP['archived']);
      _postTotal = dataP != null
          ? _toInt(dataP['total'])
          : (_postDraft + _postPub + _postClosed + _postArchived);

      // ---- applications ----
      final Map? dataA = (resApps is Map && resApps['data'] is Map)
          ? (resApps['data'] as Map)
          : null;
      final Map byA = (dataA != null && dataA['by_status'] is Map)
          ? (dataA['by_status'] as Map)
          : <String, dynamic>{};
      _appSubmitted = _toInt(byA['submitted']);
      _appUnder = _toInt(byA['under_review']);
      _appShort = _toInt(byA['shortlisted']);
      _appInterview = _toInt(byA['interview']);
      _appOffered = _toInt(byA['offered']);
      _appHired = _toInt(byA['hired']);
      _appRejected = _toInt(byA['rejected']);
      _appWithdrawn = _toInt(byA['withdrawn']);
      _appTotal = dataA != null
          ? _toInt(dataA['total'])
          : (_appSubmitted +
              _appUnder +
              _appShort +
              _appInterview +
              _appOffered +
              _appHired +
              _appRejected +
              _appWithdrawn);
      _appActive = dataA != null
          ? _toInt(dataA['active'])
          : (_appSubmitted +
              _appUnder +
              _appShort +
              _appInterview +
              _appOffered);
      _appUnassigned = dataA != null ? _toInt(dataA['unassigned']) : 0;

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted)
        setState(() {
          _error = 'İstatistik alınamadı: $e';
        });
    } finally {
      if (mounted)
        setState(() {
          _busy = false;
        });
    }
  }

  Widget _chip(String label, int v, {IconData? icon, Color? color}) {
    return Chip(
      avatar: icon != null ? Icon(icon, size: 18, color: color) : null,
      label: Text('$label: $v'),
      side: const BorderSide(color: Colors.black12),
      backgroundColor: color?.withOpacity(0.06),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.jobPostId == null
        ? 'Recruitment Özet (Şirket)'
        : 'Recruitment Özet (Job #${widget.jobPostId})';

    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  tooltip: 'Yenile',
                  onPressed: _busy ? null : _fetch,
                  icon: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh),
                ),
              ],
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 8),
            Text('İlanlar', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _chip('Taslak', _postDraft, icon: Icons.edit_note),
              _chip('Yayında', _postPub, icon: Icons.campaign_outlined),
              _chip('Kapalı', _postClosed, icon: Icons.lock_outline),
              _chip('Arşiv', _postArchived, icon: Icons.archive_outlined),
              _chip('Toplam', _postTotal, icon: Icons.summarize_outlined),
            ]),
            const SizedBox(height: 16),
            Text('Başvurular', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _chip('Aktif', _appActive, icon: Icons.timelapse_outlined),
              _chip('Atanmamış', _appUnassigned,
                  icon: Icons.assignment_ind_outlined),
              _chip('Hired', _appHired, icon: Icons.verified_outlined),
              _chip('Rejected', _appRejected, icon: Icons.block_outlined),
              _chip('Withdrawn', _appWithdrawn, icon: Icons.undo),
              _chip('Toplam', _appTotal, icon: Icons.summarize_outlined),
            ]),
          ],
        ),
      ),
    );
  }
}
