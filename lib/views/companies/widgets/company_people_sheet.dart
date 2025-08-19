import 'package:flutter/material.dart';
import 'package:seaofsea/widgets/online_images.dart';

class CompanyPeopleSheet extends StatefulWidget {
  final String title;
  final Future<List<Map<String, dynamic>>> Function() load;
  final String imagePath; // örn: 'uploads/user/user/'
  final String imageNameKey; // örn: 'user_image'
  final String nameKey; // 'name'
  final String surnameKey; // 'surname'
  final List<String> subtitleKeys; // ['rank','role']

  const CompanyPeopleSheet({
    super.key,
    required this.title,
    required this.load,
    this.imagePath = 'uploads/user/user/',
    this.imageNameKey = 'user_image',
    this.nameKey = 'name',
    this.surnameKey = 'surname',
    this.subtitleKeys = const ['rank', 'role'],
  });

  @override
  State<CompanyPeopleSheet> createState() => _CompanyPeopleSheetState();
}

class _CompanyPeopleSheetState extends State<CompanyPeopleSheet> {
  late Future<List<Map<String, dynamic>>> _future;
  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];
  final TextEditingController _searchCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = widget.load();
  }

  void _applyFilter(String q) {
    final query = q.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _filtered = List.of(_all));
      return;
    }
    setState(() {
      _filtered = _all.where((e) {
        final n = (e[widget.nameKey] ?? '').toString().toLowerCase();
        final s = (e[widget.surnameKey] ?? '').toString().toLowerCase();
        final sub = widget.subtitleKeys
            .map((k) => (e[k] ?? '').toString().toLowerCase())
            .join(' ');
        return n.contains(query) || s.contains(query) || sub.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snap.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: ${snap.error}'),
            );
          }
          _all = (snap.data ?? const []);
          _filtered = _filtered.isEmpty && _searchCtl.text.isEmpty
              ? List.of(_all)
              : _filtered;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(widget.title,
                          style: Theme.of(context).textTheme.titleLarge),
                    ),
                    Text('${_filtered.length}'),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
                child: TextField(
                  controller: _searchCtl,
                  onChanged: _applyFilter,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search people',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) {
                    final user = _filtered[i];
                    final imgName =
                        (user[widget.imageNameKey] ?? '').toString();
                    final hasImage = imgName.isNotEmpty;
                    final fullName =
                        '${user[widget.nameKey] ?? ''} ${user[widget.surnameKey] ?? ''}'
                            .trim();
                    final subtitle = widget.subtitleKeys
                        .map((k) => (user[k] ?? '').toString())
                        .where((s) => s.isNotEmpty)
                        .join(' · ');

                    return ListTile(
                      leading: hasImage
                          ? OnlineImage(
                              imagePath: widget.imagePath,
                              imageName: imgName,
                              sizeW: 40,
                              rounded: true,
                              border: true,
                            )
                          : const Icon(Icons.person),
                      title: SelectableText(
                          fullName.isEmpty ? 'Unnamed' : fullName),
                      subtitle: Text(subtitle.isEmpty ? '-' : subtitle),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
