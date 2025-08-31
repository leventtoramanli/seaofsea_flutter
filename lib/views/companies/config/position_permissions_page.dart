import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/services/v1/positions_service.dart';
import 'package:seaofsea/services/v1/v1_api_manager.dart';
import 'package:seaofsea/widgets/custon_scaffold.dart'; // mevcut CustomScaffold

class PositionPermissionsPage extends StatefulWidget {
  const PositionPermissionsPage({super.key});

  @override
  State<PositionPermissionsPage> createState() =>
      _PositionPermissionsPageState();
}

class _PositionPermissionsPageState extends State<PositionPermissionsPage> {
  late final PositionsServiceV1 _svc;
  Map<String, List<String>> _areas =
      {}; // {'Ship':['Deck','Engine',...], 'Office':['HR',...]}
  String? _groupKey; // 'Ship' | 'Office'
  String? _area; // 'Deck' | 'HR' ...
  List<_PosItem> _positions = []; // liste (id opsiyonel)
  _PosItem? _selected;

  bool _loadingAreas = true;
  bool _loadingPositions = false;
  bool _loadingPerms = false;
  bool _saving = false;

  // izin sözlüğü (permission.getAll → scope: company)
  List<_PermEntry> _catalog = [];
  String _search = '';

  // seçilen pozisyonun izin kodları
  Set<String> _selectedCodes = {};

  @override
  void initState() {
    super.initState();
    final v1 = context.findAncestorWidgetOfExactType<Provider<V1ApiManager>>();
    // genelde V1ApiManager Provider tree’de; yoksa şöyle alıyoruz:
    final api =
        V1ApiManager(); // fallback – projende zaten Provider varsa bu satır kullanılmayacak
    _svc = PositionsServiceV1(api: api);

    _loadAreas();
    _loadCatalog(api);
  }

  Future<void> _loadAreas() async {
    setState(() => _loadingAreas = true);
    final map = await _svc.getAreas();
    setState(() {
      _areas = map;
      _groupKey = _areas.keys.isNotEmpty ? _areas.keys.first : null;
      _area = (_groupKey != null && _areas[_groupKey!]!.isNotEmpty)
          ? _areas[_groupKey!]!.first
          : null;
      _loadingAreas = false;
    });
    if (_area != null) _loadPositions();
  }

  Future<void> _loadPositions() async {
    if (_area == null) return;
    setState(() {
      _loadingPositions = true;
      _positions = [];
      _selected = null;
      _selectedCodes.clear();
    });
    final list = await _svc.getPositionsByArea(_area!);
    // Backend şu an yalnızca {name} dönüyor → id null kalabilir (UI bunu gösterecek)
    setState(() {
      _positions = list.map((n) => _PosItem(id: null, name: n)).toList();
      _loadingPositions = false;
    });
  }

  Future<void> _loadPermsForSelected() async {
    final pos = _selected;
    if (pos == null || pos.id == null) return;
    setState(() {
      _loadingPerms = true;
      _selectedCodes.clear();
    });
    final pp = await _svc.getPermissions(pos.id!);
    setState(() {
      _selectedCodes = pp?.codes.toSet() ?? {};
      _loadingPerms = false;
    });
  }

  Future<void> _save() async {
    final pos = _selected;
    if (pos == null || pos.id == null) {
      _snack(
          'Bu pozisyon için ID yok. Backend, byArea cevabında id de döndürmeli.');
      return;
    }
    setState(() => _saving = true);
    final updated = await _svc.updatePermissions(
      positionId: pos.id!,
      codes: _selectedCodes.toList(),
    );
    setState(() => _saving = false);
    if (updated.isNotEmpty) {
      _snack('Kaydedildi (${updated.length} izin).');
    } else {
      _snack('Kaydedilemedi (yetki veya sunucu hatası olabilir).');
    }
  }

  Future<void> _loadCatalog(V1ApiManager api) async {
    try {
      final res = await api.call(
        module: 'permission',
        action: 'getAll',
        params: {'scope': 'company'},
      );
      final data = res['data'] ?? res;
      final list = (data['permissions'] ?? data['items'] ?? []) as List;
      setState(() {
        _catalog = list
            .map((e) {
              final m = Map<String, dynamic>.from(e as Map);
              return _PermEntry(
                code: m['code']?.toString() ?? '',
                category: m['category']?.toString() ?? '',
                description: m['description']?.toString() ?? '',
              );
            })
            .where((p) => p.code.isNotEmpty)
            .toList();
      });
    } catch (_) {
      // yok say
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _catalog.where((p) {
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return p.code.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q);
    }).toList();

    return CustomScaffold(
      title: 'Position Permissions',
      actions: [
        IconButton(
          onPressed: (_saving || _loadingPerms) ? null : _save,
          icon: const Icon(Icons.save),
          tooltip: 'Save',
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Üst seçimler
            Row(
              children: [
                // Group (Ship/Office)
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _groupKey,
                    decoration: const InputDecoration(labelText: 'Group'),
                    items: _areas.keys
                        .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        _groupKey = v;
                        final areas = _areas[_groupKey!] ?? [];
                        _area = areas.isNotEmpty ? areas.first : null;
                      });
                      _loadPositions();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Area
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _area,
                    decoration: const InputDecoration(labelText: 'Area'),
                    items: (_groupKey == null
                            ? <String>[]
                            : _areas[_groupKey!] ?? [])
                        .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                        .toList(),
                    onChanged: (v) {
                      setState(() => _area = v);
                      _loadPositions();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Pozisyonlar
            if (_loadingPositions)
              const LinearProgressIndicator()
            else
              SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (_, i) {
                    final it = _positions[i];
                    final selected = _selected == it;
                    return ChoiceChip(
                      label: Text(it.name + (it.id == null ? ' (id yok)' : '')),
                      selected: selected,
                      onSelected: (ok) async {
                        setState(() {
                          _selected = it;
                          _selectedCodes.clear();
                        });
                        if (it.id != null) {
                          await _loadPermsForSelected();
                        } else {
                          _snack(
                              'Bu öğe için id yok; düzenlemek için backend byArea cevabına id eklenmeli.');
                        }
                      },
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemCount: _positions.length,
                ),
              ),

            const Divider(height: 24),

            // Arama
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search permissions',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
            const SizedBox(height: 8),

            // İzin listesi
            if (_loadingPerms) const LinearProgressIndicator(),

            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final p = filtered[i];
                  final checked = _selectedCodes.contains(p.code);
                  return CheckboxListTile(
                    value: checked,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedCodes.add(p.code);
                        } else {
                          _selectedCodes.remove(p.code);
                        }
                      });
                    },
                    title: Text(p.code),
                    subtitle: Text(
                      [p.category, p.description]
                          .where((s) => s.isNotEmpty)
                          .join(' • '),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PosItem {
  final int? id; // şimdilik backend byArea id döndürmediği için opsiyonel
  final String name;
  _PosItem({required this.id, required this.name});
}

class _PermEntry {
  final String code;
  final String category;
  final String description;
  _PermEntry(
      {required this.code, required this.category, required this.description});
}
