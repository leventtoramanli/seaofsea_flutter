import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:seaofsea/services/v1/recruitment_service.dart';
import 'package:seaofsea/widgets/online_images.dart';
import 'package:seaofsea/services/custom_text_editor.dart'; // QuillTextViewer

class JobPostReviewPage extends StatefulWidget {
  final int postId;
  const JobPostReviewPage({super.key, required this.postId});

  @override
  State<JobPostReviewPage> createState() => _JobPostReviewPageState();
}

class _JobPostReviewPageState extends State<JobPostReviewPage> {
  bool _busy = false;
  Map<String, dynamic>? _item;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res =
          await RecruitmentServiceV1.postPublicDetail(id: widget.postId);
      // toleranslı zarf açma
      dynamic d = res;
      if (d is Map && d['data'] != null) d = d['data'];
      if (d is Map && d['data'] != null) d = d['data'];
      if (mounted) setState(() => _item = Map<String, dynamic>.from(d as Map));
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to load post.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_item?['title']?.toString() ?? 'Job'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _busy ? null : _fetch,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(onRefresh: _fetch, child: body),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_busy && _item == null) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(),
      ));
    }
    if (_error != null) {
      return ListView(children: [
        const SizedBox(height: 24),
        Center(child: Text(_error!)),
        const SizedBox(height: 120),
      ]);
    }
    if (_item == null) {
      return ListView(children: const [
        SizedBox(height: 24),
        Center(child: Text('Not found')),
        SizedBox(height: 120),
      ]);
    }

    final it = _item!;
    final companyName = (it['company_name'] ?? '').toString();
    final logo = (it['company_logo'] ?? '').toString();
    final cityName = (it['city_name'] ?? '').toString();
    final iso2 = (it['city_iso2'] ?? '').toString();
    final locationTxt = cityName.isNotEmpty
        ? (iso2.isNotEmpty ? '$cityName, $iso2' : cityName)
        : (it['location'] ?? '').toString();

    final area = (it['area'] ?? '').toString();
    String humanize(String code) => code
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
    final empTypes = it['employment_type'].toString();
    final empType = empTypes.isEmpty ? '' : humanize(empTypes);

    final updated =
        (it['updated_at'] ?? it['published_at'] ?? it['created_at'] ?? '')
            .toString();

    final description = it['description'];
    final deltaJsonStr =
        description is String ? description : jsonEncode(description);

    final chips = <Widget>[];
    if (locationTxt.isNotEmpty)
      chips.add(_chip(context, Icons.place_outlined, locationTxt));
    if (area.isNotEmpty) chips.add(_chip(context, Icons.badge_outlined, area));
    if (empType.isNotEmpty)
      chips.add(_chip(context, Icons.work_outline, empType));
    chips.add(_chip(context, Icons.schedule, _relative(updated)));

    final offerTerms = _buildOfferTerms(context, it);

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            OnlineImage(
              imagePath: 'images/companies/logo/',
              imageName: logo,
              sizeW: 56,
              sizeH: 56,
              rounded: true,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(it['title']?.toString() ?? '',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(companyName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          )),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: chips),
        if (offerTerms.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Offer / Terms', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: offerTerms),
        ],
        const SizedBox(height: 16),
        Text('Description', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if ((deltaJsonStr).trim().isEmpty)
          Text('No description.', style: Theme.of(context).textTheme.bodyMedium)
        else
          QuillTextViewer(deltaJson: deltaJsonStr),
      ],
    );
  }

  List<Widget> _buildOfferTerms(BuildContext context, Map<String, dynamic> it) {
    final out = <Widget>[];

    // Age
    final ageMin = _toInt(it['age_min']);
    final ageMax = _toInt(it['age_max']);
    final ageText = _fmtAge(ageMin, ageMax);
    if (ageText.isNotEmpty)
      out.add(_chip(context, Icons.cake_outlined, ageText));

    // Salary
    final salaryCur = (it['salary_currency'] ?? '').toString();
    final salaryUnit = (it['salary_rate_unit'] ?? '').toString();
    final salaryMin = _toNum(it['salary_min']);
    final salaryMax = _toNum(it['salary_max']);
    final salaryText =
        _fmtSalaryRange(salaryCur, salaryMin, salaryMax, salaryUnit);
    if (salaryText.isNotEmpty)
      out.add(_chip(context, Icons.payments_outlined, salaryText));

    // Contract / Probation
    final cMonths = _toInt(it['contract_duration_months']);
    if (cMonths != null && cMonths > 0)
      out.add(
          _chip(context, Icons.assignment_outlined, 'Contract: $cMonths mo'));
    final pMonths = _toInt(it['probation_months']);
    if (pMonths != null && pMonths > 0)
      out.add(_chip(
          context, Icons.verified_user_outlined, 'Probation: $pMonths mo'));

    // Rotation
    final rotOn = _toInt(it['rotation_on_months']);
    final rotOff = _toInt(it['rotation_off_months']);
    final rotText = _fmtRotation(rotOn, rotOff);
    if (rotText.isNotEmpty)
      out.add(_chip(context, Icons.loop_outlined, rotText));

    // Bonus
    final bonusType = (it['rotation_bonus_type'] ?? '').toString();
    final bonusValue = _toNum(it['rotation_bonus_value']);
    final bonusText = _fmtBonus(bonusType, bonusValue, salaryCur);
    if (bonusText.isNotEmpty)
      out.add(_chip(context, Icons.card_giftcard_outlined, bonusText));

    // Benefits
    final benefits = _safeMap(it['benefits_json']);
    final benefitChips = _benefitChips(context, benefits);
    out.addAll(benefitChips);

    // Obligations (short)
    final obligations = _safeMap(it['obligations_json']);
    final tax = (obligations['tax_withholding'] ?? '').toString();
    final ss = (obligations['social_security'] ?? '').toString();
    final notes = (obligations['notes'] ?? '').toString();

    if (tax.isNotEmpty)
      out.add(_chip(context, Icons.balance_outlined, 'Tax: $tax'));
    if (ss.isNotEmpty)
      out.add(_chip(context, Icons.health_and_safety_outlined, 'Social: $ss'));
    if (notes.isNotEmpty) {
      out.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(notes, style: Theme.of(context).textTheme.bodySmall),
      ));
    }

    return out;
  }

  Widget _chip(BuildContext ctx, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(ctx).dividerColor),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16),
        const SizedBox(width: 6),
        Text(text, style: Theme.of(ctx).textTheme.labelMedium),
      ]),
    );
  }

  // benefits_json → chip list
  List<Widget> _benefitChips(
      BuildContext context, Map<String, dynamic> benefits) {
    if (benefits.isEmpty) return const [];

    // Bilinen key → okunur label
    const labels = {
      'insurance': 'Insurance',
      'meals_included': 'Meals',
      'accommodation_included': 'Accommodation',
      'travel_included': 'Travel',
      'visa_sponsored': 'Visa',
      'relocation': 'Relocation',
      'education_support': 'Education',
      'healthcare': 'Healthcare',
      'bonus': 'Bonus',
      'overtime_rate': 'Overtime',
    };

    String _fallbackLabel(String k) {
      final s = k.replaceAll('_', ' ');
      if (s.isEmpty) return 'Benefit';
      return s[0].toUpperCase() + s.substring(1);
    }

    final out = <Widget>[];

    benefits.forEach((key, value) {
      final base = labels[key] ?? _fallbackLabel(key);
      String? text;

      if (value is bool) {
        // true → sadece label; false → gösterme
        if (value == true) text = base;
      } else if (value is num) {
        // sayısal → "Label: 10"
        text = '$base: ${value.toString()}';
      } else if (value is String) {
        final v = value.trim();
        if (v.isEmpty ||
            v.toLowerCase() == 'no' ||
            v.toLowerCase() == 'false') {
          // gösterme
        } else if (['yes', 'true', 'included', 'employer']
            .contains(v.toLowerCase())) {
          // onay ifadeleri → sadece label
          text = base;
        } else {
          // genel durum → "Label: Değer"
          text = '$base: $v';
        }
      } // Map/List gelirse şimdilik atlıyoruz

      if (text != null && text.isNotEmpty) {
        out.add(_chip(context, Icons.check_circle_outline, text));
      }
    });

    return out;
  }

  // ---- bottom bar (Apply) ----
  Widget _buildBottomBar(BuildContext context) {
    if (_item == null) return const SizedBox.shrink();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              label: const Text('Close'),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: _busy ? null : _onApplyPressed,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onApplyPressed() async {
    final it = _item!;
    final companyId = _toInt(it['company_id']) ?? 0;
    if (companyId <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Company not found.')));
      return;
    }

    final ctrl = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Send Application',
                  style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: ctrl,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Cover letter (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Spacer(),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Send')),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (ok != true) return;

    setState(() => _busy = true);
    try {
      await RecruitmentServiceV1.appSubmit(
        companyId: companyId,
        jobPostId: widget.postId,
        coverLetter: ctrl.text.trim().isEmpty ? null : ctrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Application sent.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit application.')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---- helpers ----
  Map<String, dynamic> _safeMap(dynamic v) {
    if (v == null) return {};
    if (v is Map) return Map<String, dynamic>.from(v);
    if (v is String) {
      try {
        final dec = jsonDecode(v);
        if (dec is Map) return Map<String, dynamic>.from(dec);
      } catch (_) {}
    }
    return {};
  }

  int? _toInt(dynamic v) => v == null ? null : int.tryParse('$v');
  num? _toNum(dynamic v) => v == null ? null : num.tryParse('$v');

  String _fmtAge(int? min, int? max) {
    if (min == null && max == null) return '';
    if (min != null && max != null) return 'Age $min–$max';
    if (min != null) return 'Age $min+';
    return 'Age ≤${max!}';
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

  String _fmtBonus(String type, num? value, String currency) {
    switch (type) {
      case 'fixed':
        if (value == null || value <= 0) return '';
        final cur = currency.toUpperCase();
        final hasCur = cur.length == 3;
        final val = _fmtMoney(value);
        return hasCur ? '$cur $val bonus' : '$val bonus';
      case 'percent':
        if (value == null || value <= 0) return '';
        return '+${value.toString().replaceAll(RegExp(r"\.0$"), "")}% bonus';
      case 'one_salary':
        return 'Completion: 1 salary';
      default:
        return '';
    }
  }

  String _relative(String s) {
    try {
      DateTime dt;
      if (s.contains('T')) {
        dt = DateTime.tryParse(s) ?? DateTime.now();
      } else {
        final parts = s.split(' ');
        final d = parts.first;
        final t = parts.length > 1 ? parts[1] : '00:00:00';
        dt = DateTime.tryParse('${d}T$t') ?? DateTime.now();
      }
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Now';
      if (diff.inHours < 1) return '${diff.inMinutes} min ago';
      if (diff.inDays < 1) return '${diff.inHours} h ago';
      return '${diff.inDays} d ago';
    } catch (_) {
      return s;
    }
  }
}
