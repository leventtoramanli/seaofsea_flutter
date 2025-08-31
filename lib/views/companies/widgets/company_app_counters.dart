import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/views/companies/dashboard/services/applications_service.dart';
import 'package:seaofsea/services/v1/v1_api_manager.dart';

class CompanyAppCounters extends StatefulWidget {
  final int companyId;
  final void Function(String status)? onTapStatus;

  const CompanyAppCounters(
      {super.key, required this.companyId, this.onTapStatus});

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
    setState(() {
      counts = c;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    final c = counts ?? {};
    final statuses = [
      'submitted',
      'under_review',
      'shortlisted',
      'interview',
      'offer',
      'hired',
      'rejected',
      'withdrawn'
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: statuses.map((s) {
        final n = c[s] ?? 0;
        return ActionChip(
          label: Text('$s ($n)'),
          onPressed:
              widget.onTapStatus != null ? () => widget.onTapStatus!(s) : null,
        );
      }).toList(),
    );
  }
}
