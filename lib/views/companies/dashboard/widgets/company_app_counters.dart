// seaofsea/views/companies/widgets/company_app_counters.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/services/v1/v1_api_manager.dart';
import 'package:seaofsea/views/companies/dashboard/services/applications_service.dart';

class CompanyAppCounters extends StatefulWidget {
  final int companyId;
  final void Function(String status)? onTapStatus;

  const CompanyAppCounters({super.key, required this.companyId, this.onTapStatus});

  @override
  State<CompanyAppCounters> createState() => _CompanyAppCountersState();
}

class _CompanyAppCountersState extends State<CompanyAppCounters> {
  Map<String, int>? counts;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final svc = ApplicationsServiceV1(api: context.read<V1ApiManager>());
    final c = await svc.getCountsByStatus(widget.companyId);
    if (!mounted) return;
    setState(() { counts = c; loading = false; });
  }

  // basit renk paleti
  Color _chipColor(String s, ThemeData t) {
    final sc = t.colorScheme;
    switch (s) {
      case 'submitted':     return sc.primaryContainer;
      case 'under_review':  return sc.tertiaryContainer;
      case 'shortlisted':   return sc.secondaryContainer;
      case 'interview':     return sc.surfaceVariant;
      case 'offer':         return sc.primaryContainer;
      case 'hired':         return sc.secondaryContainer;
      case 'rejected':      return sc.errorContainer;
      case 'withdrawn':     return sc.surfaceVariant;
      default:              return sc.surfaceVariant;
    }
  }

  Color _chipText(String s, ThemeData t) {
    final sc = t.colorScheme;
    switch (s) {
      case 'rejected': return sc.onErrorContainer;
      default:         return sc.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    final c = counts ?? {};
    final statuses = const [
      'submitted','under_review','shortlisted','interview','offer','hired','rejected','withdrawn'
    ];

    return Wrap(
      spacing: 8, runSpacing: 8,
      children: statuses.map((s) {
        final n = c[s] ?? 0;
        final t = Theme.of(context);
        return FilterChip(
          label: Text('$s ($n)'),
          selected: false,
          onSelected: widget.onTapStatus == null ? null : (_) => widget.onTapStatus!(s),
          backgroundColor: _chipColor(s, t),
          labelStyle: TextStyle(color: _chipText(s, t)),
          showCheckmark: false,
        );
      }).toList(),
    );
  }
}
