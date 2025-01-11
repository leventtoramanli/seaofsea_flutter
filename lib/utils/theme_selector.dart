import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/color_blindness_provider.dart';
import 'package:seaofsea/utils/theme_provider.dart';

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colorBlindnessProvider = Provider.of<ColorBlindnessProvider>(context);

    return PopupMenuButton<String>(
      icon: Icon(
        themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
      ),
      onSelected: (value) {
        if (value == 'Light') {
          if (themeProvider.isDarkMode) themeProvider.toggleTheme();
        } else if (value == 'Dark') {
          if (!themeProvider.isDarkMode) themeProvider.toggleTheme();
        } else if (value == 'BlurLevel') {
          _showBlurSlider(context, colorBlindnessProvider);
        } else if (value == 'EffectToggle') {
          colorBlindnessProvider.toggleEffect();
        } else {
          colorBlindnessProvider.setEffect(value);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
            value: 'Light',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Light Theme'),
                if (!themeProvider.isDarkMode)
                  const Icon(Icons.check, color: Colors.blue),
              ],
            )),
        PopupMenuItem(
            value: 'Dark',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Dark Theme'),
                if (themeProvider.isDarkMode)
                  const Icon(Icons.check, color: Colors.blue),
              ],
            )),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: ColorBlindnessProvider.protanopia,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Protanopia'),
              if (colorBlindnessProvider.currentEffect ==
                  ColorBlindnessProvider.protanopia)
                const Icon(Icons.check, color: Colors.blue),
            ],
          ),
        ),
        PopupMenuItem(
          value: ColorBlindnessProvider.deuteranopia,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Deuteranopia'),
              if (colorBlindnessProvider.currentEffect ==
                  ColorBlindnessProvider.deuteranopia)
                const Icon(Icons.check, color: Colors.blue),
            ],
          ),
        ),
        PopupMenuItem(
          value: ColorBlindnessProvider.tritanopia,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tritanopia'),
              if (colorBlindnessProvider.currentEffect ==
                  ColorBlindnessProvider.tritanopia)
                const Icon(Icons.check, color: Colors.blue),
            ],
          ),
        ),
        PopupMenuItem(
          value: ColorBlindnessProvider.achromatopsia,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Achromatopsia'),
              if (colorBlindnessProvider.currentEffect ==
                  ColorBlindnessProvider.achromatopsia)
                const Icon(Icons.check, color: Colors.blue),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'BlurLevel',
          child: Text('Set Blur Level'),
        ),
        PopupMenuItem(
          value: 'EffectToggle',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Effect On/Off'),
              Switch(
                value: colorBlindnessProvider.isEffectOn,
                onChanged: (value) {
                  colorBlindnessProvider.toggleEffect();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showBlurSlider(BuildContext context, ColorBlindnessProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set Blur Level'),
          content: Slider(
            value: provider.blurLevel,
            min: 0.0,
            max: 9.0,
            divisions: 10,
            label: '${provider.blurLevel.toInt() * 10}%',
            onChanged: (value) {
              provider.setBlurLevel(value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
