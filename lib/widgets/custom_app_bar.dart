import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/auth_provider.dart';
import 'package:seaofsea/utils/theme_selector.dart';

class MyAppBar extends AppBar {
  MyAppBar({
    super.key,
    String? title,
    List<String> hideIcons = const [],
    Color? backgroundColors,
    Map<String, VoidCallback>? overrideActions,
    BuildContext? context,
  }) : super(
          elevation: 4,
          title: Text('SeaOfSea - ${title ?? ""}'),
          backgroundColor: backgroundColors,
          actions: [
            if (overrideActions != null)
              ...overrideActions.entries.map(
                (entry) => IconButton(
                  icon: Icon(_getIconFromKey(entry.key)),
                  onPressed: entry.value,
                ),
              )
            else if (!hideIcons.contains('theme'))
              if (!hideIcons.contains('profile') && context != null)
                IconButton(
                  icon: const Icon(Icons.person),
                  onPressed: () {
                    final userId =
                        Provider.of<AuthProvider>(context, listen: false)
                            .userInfo?['id'];
                    if (userId != null) {
                      Navigator.pushNamed(context, '/public_profile_page',
                          arguments: userId);
                    }
                  },
                ),
            if (!hideIcons.contains('theme')) const ThemeSelector(),
          ],
        );

  static IconData _getIconFromKey(String key) {
    switch (key) {
      case 'settings':
        return Icons.settings;
      case 'logout':
        return Icons.exit_to_app;
      case 'profile':
        return Icons.person;
      default:
        return Icons.help_outline;
    }
  }
}
