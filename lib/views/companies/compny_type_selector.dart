import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';

void main() {
  runApp(const MaterialApp(home: DropdownSearchExample()));
}

class DropdownSearchExample extends StatefulWidget {
  const DropdownSearchExample({super.key});

  @override
  State<DropdownSearchExample> createState() => _DropdownSearchExampleState();
}

class _DropdownSearchExampleState extends State<DropdownSearchExample> {
  List<Map<String, dynamic>> allItems = List.generate(
    100,
    (index) => {'id': index, 'name': 'Company Type $index'},
  );

  List<int> selectedIds = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dropdown Search v6.0.2")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _showTypeSelector,
              child: const Text("Select Company Types"),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              children: selectedIds.map((id) {
                final item = allItems.firstWhere((e) => e['id'] == id);
                return Chip(label: Text(item['name']));
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showTypeSelector() async {
    final List<int>? result = await showDialog<List<int>>(
      context: context,
      builder: (context) {
        List<int> tempSelected = List.from(selectedIds);
        return AlertDialog(
          title: const Text("Select Types"),
          content: SizedBox(
              height: 500,
              child: DropdownSearch<Map<String, dynamic>>.multiSelection(
                items: allItems,
                selectedItems: allItems
                    .where((item) => selectedIds.contains(item['id']))
                    .toList(),
                itemAsString: (item) => item['name'],
                compareFn: (a, b) => a['id'] == b['id'],
                popupProps: PopupPropsMultiSelection.modalBottomSheet(
                  showSearchBox: true,
                ),
                onChanged: (List<Map<String, dynamic>>? items) {
                  setState(() {
                    selectedIds =
                        items?.map((e) => e['id'] as int).toList() ?? [];
                  });
                },
              )),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, tempSelected),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        selectedIds = result;
      });
    }
  }
}
