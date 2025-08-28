import 'package:flutter/material.dart';
import 'package:seaofsea/views/companies/dashboard/widgets/address_expandable_card.dart';

/// contact['addresses'] listesini alt alta AddressExpandableCard olarak gösterir.
/// Her item: {'label': 'HQ', 'value': 'Adres satırı...'}
class AddressExpandableList extends StatelessWidget {
  final List<Map<String, String>> addresses;
  final void Function(Map<String, String>) onOpenMap;
  final void Function(Map<String, String>) onCopy;

  const AddressExpandableList({
    super.key,
    required this.addresses,
    required this.onOpenMap,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    if (addresses.isEmpty) return const SizedBox.shrink();

    return Column(
      children: List.generate(addresses.length, (i) {
        final a = addresses[i];
        final value = (a['value'] ?? '').trim();
        final label = (a['label'] ?? '').trim();
        final display = label.isEmpty ? value : '$label: $value';

        return Padding(
          padding: EdgeInsets.only(bottom: i == addresses.length - 1 ? 0 : 12),
          child: AddressExpandableCard(
            addressText: display,
            onOpenMap: () => onOpenMap(a),
            onCopy: () => onCopy(a),
          ),
        );
      }),
    );
  }
}
