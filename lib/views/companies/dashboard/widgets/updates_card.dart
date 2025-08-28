import 'package:flutter/material.dart';

class UpdatesCard extends StatelessWidget {
  const UpdatesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        height: 140,
        child: Center(
          child: Text('Announcements & Updates',
              style: theme.textTheme.titleMedium),
        ),
      ),
    );
  }
}
