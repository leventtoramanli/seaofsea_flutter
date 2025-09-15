import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:seaofsea/services/v1/recruitment_service.dart';
import 'package:seaofsea/widgets/job_post_tile.dart';

class OpenJobsTab extends StatefulWidget {
  final double?
      fixedHeight; // TabBarView içinde 220 gibi sabit yükseklik istersen
  const OpenJobsTab({super.key, this.fixedHeight});

  @override
  State<OpenJobsTab> createState() => _OpenJobsTabState();
}

class _OpenJobsTabState extends State<OpenJobsTab> with AutomaticKeepAliveClientMixin {
  bool _busy = false;
  List<Map<String, dynamic>> _items = [];
  String? _error;
  int _fetchToken = 0;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _fetch() async {
    if (!mounted || _busy) return;
    final token = ++_fetchToken;

    setState(() { _busy = true; _error = null; });

    try {
      final res = await RecruitmentServiceV1.postPublicOpenListNormalized(limit: 10);

      if (!mounted || token != _fetchToken) return; // stale sonucu at

      final items = (res['items'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      setState(() => _items = items);
    } catch (e) {
      if (!mounted || token != _fetchToken) return;
      setState(() => _error = 'Failed to load open jobs');
    } finally {
      if (!mounted || token != _fetchToken) return;
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin için
    final content = RefreshIndicator(
      onRefresh: _fetch,
      child: _buildList(context),
    );

    final stackChild = Stack(
      children: [
        content,
        Positioned(
          right: 8,
          top: 4,
          child: TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/jobs'),
            icon: const Icon(Icons.chevron_right),
            label: const Text('See all'),
          ),
        ),
      ],
    );

    if (widget.fixedHeight != null) {
      return SizedBox(height: widget.fixedHeight, child: stackChild);
    }
    return stackChild;
  }

  Widget _buildList(BuildContext context) {
    if (_busy && _items.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 80),
          Center(child: CircularProgressIndicator()),
          SizedBox(height: 120),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 16),
          Center(child: Text(_error!)),
          const SizedBox(height: 120),
        ],
      );
    }

    if (_items.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 16),
          Center(child: Text('Discover job lists')),
          SizedBox(height: 120),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      shrinkWrap: true,
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox.shrink(),
      itemBuilder: (ctx, i) {
        final m = _items[i];
        final id = (m['id'] as int?) ?? int.tryParse('${m['id']}') ?? 0;

        final title = '${m['title'] ?? ''}';
        final companyName = '${m['company_name'] ?? ''}';

        final cityName = (m['city_name'] ?? '').toString();
        final iso2 = (m['city_iso2'] ?? '').toString();
        final locationTxt = cityName.isNotEmpty
            ? (iso2.isNotEmpty ? '$cityName, $iso2' : cityName)
            : (m['location'] ?? '').toString();

        final updated =
            (m['updated_at'] ?? m['published_at'] ?? m['created_at'] ?? '')
                .toString();

        final logo = (m['company_logo'] ?? '').toString();

        // --- mini summary (maaş → rotation fallback) ---
        final salaryCur = (m['salary_currency'] ?? '').toString();
        final salaryUnit = (m['salary_rate_unit'] ?? '').toString();
        final salaryMin = _toNum(m['salary_min']);
        final salaryMax = _toNum(m['salary_max']);

        final rotOn = _toInt(m['rotation_on_months']);
        final rotOff = _toInt(m['rotation_off_months']);

        String mini = '';
        final salaryPart =
            _fmtSalaryRange(salaryCur, salaryMin, salaryMax, salaryUnit);
        if (salaryPart.isNotEmpty) {
          mini = salaryPart;
        } else if (rotOn != null || rotOff != null) {
          mini = _fmtRotation(rotOn, rotOff);
        }

        return JobPostTile(
          title: title,
          companyName: companyName,
          location: locationTxt,
          updatedAt: updated,
          companyLogo: logo,
          miniSummary: mini, // 🆕
          onTap: () => Navigator.pushNamed(context, '/job_review', arguments: {
            'post_id': id,
          }),
        );
      },
    );
  }

  // ---------- helpers ----------
  num? _toNum(dynamic v) {
    if (v == null) return null;
    if (v is num) return v;
    return num.tryParse('$v');
  }

  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse('$v');
  }

  String _fmtSalaryRange(String currency, num? min, num? max, String unit) {
    if (min == null && max == null) return '';
    final unitS = _unitShort(unit);
    final cur = currency.toUpperCase();
    final hasCur = cur.length == 3;

    String range;
    if (min != null && max != null && min != max) {
      range = '${_fmtMoney(min)}–${_fmtMoney(max)}';
    } else {
      final v = (max ?? min ?? 0);
      range = _fmtMoney(v);
    }

    final prefix = hasCur ? '$cur ' : '';
    final suffix = unitS.isNotEmpty ? ' / $unitS' : '';
    return '$prefix$range$suffix';
  }

  String _fmtMoney(num v) {
    // basit format: 4000.00 -> 4,000 ; 5500.50 -> 5,500.50
    final s = v.toStringAsFixed(v % 1 == 0 ? 0 : 2);
    final parts = s.split('.');
    final intPart = parts[0];
    final dec = parts.length > 1 ? '.${parts[1]}' : '';
    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      final fromEnd = intPart.length - i;
      buf.write(intPart[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
    }
    return buf.toString() + dec;
  }

  String _unitShort(String unit) {
    switch (unit) {
      case 'hour':
        return 'hr';
      case 'day':
        return 'day';
      case 'month':
        return 'mo';
      case 'year':
        return 'yr';
      case 'contract':
        return 'contract';
      case 'trip':
        return 'trip';
      default:
        return '';
    }
  }

  String _fmtRotation(int? on, int? off) {
    final a = on ?? 0;
    final b = off ?? 0;
    if (a == 0 && b == 0) return '';
    if (a > 0 && b > 0) return 'Rotation $a+$b';
    return 'Rotation ${a > 0 ? a : b}';
  }
}
