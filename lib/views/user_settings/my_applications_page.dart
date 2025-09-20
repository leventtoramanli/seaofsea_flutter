import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/my_applications_providers.dart';
import 'package:seaofsea/widgets/custon_scaffold.dart';

class MyApplicationsPage extends StatefulWidget {
  static const routeName = '/my-applications';

  const MyApplicationsPage({super.key});

  @override
  State<MyApplicationsPage> createState() => _MyApplicationsPageState();
}

class _MyApplicationsPageState extends State<MyApplicationsPage> {
  final TextEditingController _searchCtrl = TextEditingController();

  // UI için insan-dostu etiketler
  static const Map<String, String> kStatusLabels = {
    'submitted': 'Submitted',
    'under_review': 'Under Review',
    'shortlisted': 'Shortlisted',
    'interview': 'Interview',
    'offered': 'Offered',
    'hired': 'Hired',
    'rejected': 'Rejected',
    'withdrawn': 'Withdrawn',
  };

  static const Set<String> kWithdrawAllowed = {
    'submitted',
    'under_review',
    'shortlisted',
    'interview',
    'offered',
  };

  @override
  void initState() {
    super.initState();
    // İlk yükleme
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<MyApplicationsProvider>();
      // perPage default 25, page default 1 — provider içinde ayarlı
      p.fetch();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applySearch() {
    final p = context.read<MyApplicationsProvider>();
    p.search(_searchCtrl.text);
    p.refresh();
  }

  void _toggleStatus(String status, bool selected) {
    final p = context.read<MyApplicationsProvider>();
    final current = [...p.statuses];
    if (selected) {
      if (!current.contains(status)) current.add(status);
    } else {
      current.remove(status);
    }
    p.setStatuses(current);
    p.refresh();
  }

  Widget _buildTopBar(MyApplicationsProvider p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Arama satırı
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onSubmitted: (_) => _applySearch(),
                decoration: const InputDecoration(
                  hintText: 'Job title / Description / cover letter...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _applySearch,
              icon: const Icon(Icons.tune),
              label: const Text('Filter'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Status chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kStatusLabels.keys.map((st) {
            final selected = p.statuses.contains(st);
            return ChoiceChip(
              label: Text(kStatusLabels[st] ?? st),
              selected: selected,
              onSelected: (val) => _toggleStatus(st, val),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        // PerPage & Özet
        Row(
          children: [
            DropdownButton<int>(
              value: p.perPage,
              items: const [
                DropdownMenuItem(value: 25, child: Text('25')),
                DropdownMenuItem(value: 50, child: Text('50')),
                DropdownMenuItem(value: 100, child: Text('100')),
              ],
              onChanged: (v) {
                if (v != null) {
                  p.setPerPage(v);
                  p.refresh();
                }
              },
            ),
            const SizedBox(width: 12),
            Text('Total: ${p.total}'),
            const Spacer(),
            IconButton(
              tooltip: 'Refresh',
              onPressed: () => p.refresh(),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildList(MyApplicationsProvider p) {
    if (p.loading && p.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (p.error != null && p.items.isEmpty) {
      return Center(
        child: Text(
          'Error: ${p.error}',
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }
    if (p.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 48),
            const SizedBox(height: 8),
            const Text('You have no applications.'),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => p.refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => p.refresh(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: p.items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final it = p.items[index];
          final int id =
              (it['id'] is int) ? it['id'] : int.tryParse('${it['id']}') ?? 0;
          final String job = (it['job_title'] ?? '—').toString();
          final String comp = (it['company_name'] ?? '—').toString();
          final String status = (it['status'] ?? '').toString();
          final String createdAt = (it['created_at'] ?? '').toString();

          return ListTile(
            title: Text(job, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(comp, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Chip(
                  label: Text(kStatusLabels[status] ?? status),
                ),
                Text(
                  createdAt,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                TextButton(
                  onPressed: () => _openDetail(id),
                  child: const Text('Details'),
                ),
                if (kWithdrawAllowed.contains(status))
                  TextButton(
                    onPressed: () => _confirmWithdraw(id),
                    child: const Text('Withdraw'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openDetail(int applicationId) async {
    final p = context.read<MyApplicationsProvider>();
    final data = await p.getDetail(applicationId);
    if (!mounted) return;

    if (data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Detay alınamadı.')),
      );
      return;
    }

    final app = Map<String, dynamic>.from(data['application'] ?? {});
    final hist = (data['status_history'] as List?)?.cast<Map>() ?? const [];
    final title = (app['job_title'] ?? '—').toString();
    final company = (app['company_name'] ?? '—').toString();
    final status = (app['status'] ?? '').toString();
    final cover = (app['cover_letter'] ?? '').toString();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(company, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              Chip(label: Text(kStatusLabels[status] ?? status)),
              const SizedBox(height: 12),
              if (cover.isNotEmpty) ...[
                const Text('Cover Letter',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(cover),
                const SizedBox(height: 12),
              ],
              const Text('Durum Geçmişi',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: hist.length,
                  itemBuilder: (_, i) {
                    final h = Map<String, dynamic>.from(hist[i]);
                    final os = (h['old_status'] ?? '').toString();
                    final ns = (h['new_status'] ?? '').toString();
                    final at = (h['created_at'] ?? '').toString();
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                          '${kStatusLabels[os] ?? os} → ${kStatusLabels[ns] ?? ns}'),
                      subtitle: Text(at),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Kapat'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmWithdraw(int applicationId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Başvuruyu geri çek'),
        content:
            const Text('Bu işlem geri alınamaz. Devam etmek istiyor musunuz?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Withdraw')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final p = context.read<MyApplicationsProvider>();
    final success = await p.withdrawOne(applicationId);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Başvuru geri çekildi.' : 'İşlem başarısız.'),
      ),
    );
  }

  Widget _buildPager(MyApplicationsProvider p) {
    if (p.pages <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: 'Önceki',
          onPressed: (p.page > 1) ? () => p.goTo(p.page - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('${p.page} / ${p.pages}'),
        IconButton(
          tooltip: 'Sonraki',
          onPressed: (p.page < p.pages) ? () => p.goTo(p.page + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MyApplicationsProvider>(
      builder: (context, p, _) {
        return CustomScaffold(
          title: 'My Applications',
          body: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                _buildTopBar(p),
                const SizedBox(height: 8),
                Expanded(child: _buildList(p)),
                const SizedBox(height: 8),
                _buildPager(p),
              ],
            ),
          ),
        );
      },
    );
  }
}
