import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/theme_provider.dart';

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({
    super.key,
    required this.themeProvider,
  });

  final ThemeProvider themeProvider;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        themeProvider.isDarkMode
            ? Icons.light_mode // Koyu temada açık tema simgesi
            : Icons.dark_mode, // Açık temada koyu tema simgesi
      ),
      onPressed: () {
        final themeProvider =
            Provider.of<ThemeProvider>(context, listen: false);
        themeProvider.toggleTheme(); // Temayı değiştir
      },
    );
  }
}
