// lib/widgets/certificate_picker.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/services/v1/v1_api_manager.dart';

class CertificatePicker extends StatefulWidget {
  final List<int>? initialSelectedIds;
  const CertificatePicker({super.key, this.initialSelectedIds});

  @override
  State<CertificatePicker> createState() => CertificatePickerState();
}

class CertificatePickerState extends State<CertificatePicker> {
  late V1ApiManager _v1;
  bool _loading = false;
  final _qCtl = TextEditingController();
  Timer? _deb;
  Map<int, List<Map<String, dynamic>>> _byGroup = {};
  final Map<int, bool> _selected = {}; // certId -> selected
  final Map<int, String> _groupNames = const {
    1: 'Travel Documents',
    2: 'Medical Certificates',
    3: 'Basic Safety Trainings',
    4: 'Advanced and Specialized Trainings',
    5: 'Officer Certificates',
    6: 'Deck & Engine Ratings',
    7: 'Onboard Services',
    8: 'Medical Crew',
    9: 'Fishing Vessel Certificates',
    10: 'Offshore Safety',
    11: 'Tug Operations & Pilotage',
    12: 'Pilotage Licenses',
    13: 'Luxury Yacht Services',
  };

  @override
  void initState() {
    super.initState();
    _v1 = context.read<V1ApiManager>();
    _load();
    _qCtl.addListener(_onSearchChanged);
    if (widget.initialSelectedIds != null) {
      for (final id in widget.initialSelectedIds!) {
        _selected[id] = true;
      }
    }
  }

  @override
  void dispose() {
    _qCtl.removeListener(_onSearchChanged);
    _qCtl.dispose();
    _deb?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _deb?.cancel();
    _deb = Timer(const Duration(milliseconds: 300), _load);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final params = {
        if (_qCtl.text.trim().length >= 2) 'q': _qCtl.text.trim(),
        'page': 1,
        'per_page': 1000,
      };
      final res =
          await _v1.call(module: 'certificate', action: 'list', params: params);
      final data = res['data'];
      final items = (data is Map && data['items'] is List)
          ? List<Map<String, dynamic>>.from(
              data['items'].map((e) => Map<String, dynamic>.from(e)))
          : <Map<String, dynamic>>[];

      // Group & sort
      final byG = <int, List<Map<String, dynamic>>>{};
      for (final m in items) {
        final gid = int.tryParse('${m['group_id']}') ?? 0;
        (byG[gid] ??= []).add(m);
      }
      debugPrint('Certificate groups: ${byG.keys.toList()}');
      byG.forEach((gid, list) {
        list.sort((a, b) {
          final sa = int.tryParse('${a['sort_order']}') ?? 0;
          final sb = int.tryParse('${b['sort_order']}') ?? 0;
          if (sa != sb) return sa.compareTo(sb);
          return (a['name'] ?? '')
              .toString()
              .compareTo((b['name'] ?? '').toString());
        });
      });

      setState(() => _byGroup = byG);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load certificates: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Public API: seçili ID listesi
  List<int> getSelectedIds() =>
      _selected.entries.where((e) => e.value).map((e) => e.key).toList();

  // Public API: seçili sayısı
  int getSelectedCount() => _selected.values.where((v) => v).length;

  void _toggleGroup(int gid, bool selectAll) {
    final list = _byGroup[gid] ?? const [];
    setState(() {
      for (final m in list) {
        final id = int.tryParse('${m['id']}');
        if (id != null) _selected[id] = selectAll;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupIds = _byGroup.keys.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search
        TextField(
          controller: _qCtl,
          decoration: InputDecoration(
            labelText: 'Search certificates (min 2 chars)',
            border: const OutlineInputBorder(),
            isDense: true,
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : (_qCtl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _qCtl.clear();
                          _load();
                        })
                    : null),
          ),
        ),
        const SizedBox(height: 8),
        // Summary chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            InputChip(
              avatar: const Icon(Icons.checklist, size: 18),
              label: Text('Selected: ${getSelectedCount()}'),
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Grouped panels
        ExpansionPanelList.radio(
          elevation: 2,
          children: groupIds.map<ExpansionPanelRadio>((gid) {
            final list = _byGroup[gid]!;
            final selectedInGroup = list
                .where(
                    (m) => _selected[int.tryParse('${m['id']}') ?? -1] == true)
                .length;

            return ExpansionPanelRadio(
              value: gid,
              headerBuilder: (_, isExpanded) => ListTile(
                leading: const Icon(Icons.folder_special_outlined),
                title: Text(_groupNames[gid] ?? 'Group $gid',
                    style: Theme.of(context).textTheme.titleMedium),
                subtitle: selectedInGroup > 0
                    ? Text('$selectedInGroup selected')
                    : null,
                trailing: Wrap(
                  spacing: 6,
                  children: [
                    TextButton(
                      onPressed: () => _toggleGroup(gid, true),
                      child: const Text('Select all'),
                    ),
                    TextButton(
                      onPressed: () => _toggleGroup(gid, false),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ),
              body: Column(
                children: list.map((m) {
                  final id = int.tryParse('${m['id']}')!;
                  final name = (m['name'] ?? '').toString();
                  final note = (m['note'] ?? '').toString();
                  final stcw = (m['stcw_code'] ?? '').toString();
                  final checked = _selected[id] ?? false;
                  return CheckboxListTile(
                    value: checked,
                    onChanged: (v) =>
                        setState(() => _selected[id] = v ?? false),
                    title: Text(name),
                    subtitle: note.isNotEmpty ? Text("$note ($stcw)") : null,
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                }).toList(),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
