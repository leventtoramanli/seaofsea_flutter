import 'package:flutter/material.dart';

class LanguageItem {
  String name;
  double percentage;
  String pathName;

  LanguageItem({required this.name, required this.percentage, this.pathName = 'Language'});

  Map<String, dynamic> toJson() => {
        'name': name,
        'percentage': percentage,
      };

  factory LanguageItem.fromJson(Map<String, dynamic> json) {
    return LanguageItem(
      name: json['name'] ?? '',
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }
}

class LanguageFormSection extends StatefulWidget {
  final List<LanguageItem> initialItems;
  final Function(List<LanguageItem>)? onChanged;

  const LanguageFormSection({super.key, required this.initialItems, this.onChanged});

  @override
  State<LanguageFormSection> createState() => _LanguageFormSectionState();
}

class _LanguageFormSectionState extends State<LanguageFormSection> {
  late List<LanguageItem> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.initialItems);
  }

  void _addItem() {
    setState(() {
      _items.add(LanguageItem(name: '', percentage: 0));
      widget.onChanged?.call(_items);
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      widget.onChanged?.call(_items);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < _items.length; i++)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    initialValue: _items[i].name,
                    decoration: const InputDecoration(labelText: 'Name of language'),
                    onChanged: (value) {
                      _items[i].name = value;
                      widget.onChanged?.call(_items);
                    },
                  ),
                  Slider(
                    value: _items[i].percentage,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: '${_items[i].percentage.toInt()}%',
                    onChanged: (value) {
                      setState(() {
                        _items[i].percentage = value;
                      });
                      widget.onChanged?.call(_items);
                    },
                  ),
                  Text('${_items[i].percentage.toInt()}%'),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _removeItem(i),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ElevatedButton.icon(
          onPressed: _addItem,
          icon: const Icon(Icons.add),
          label: const Text('Add a new language'),
        ),
      ],
    );
  }
}
