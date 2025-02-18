import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/color_blindness_provider.dart';
import 'package:seaofsea/utils/theme_provider.dart';

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode
            ? Icons.dark_mode
            : Icons.light_mode,
      ),
      onSelected: (value) {
        final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
        final colorBlindnessProvider = Provider.of<ColorBlindnessProvider>(context, listen: false);

        if (value == 'Light') {
          if (themeProvider.isDarkMode) {
            themeProvider.toggleTheme();
          }
        } else if (value == 'Dark') {
          if (!themeProvider.isDarkMode) {
            themeProvider.toggleTheme();
          }
        } else if (value == 'BlurLevel') {
          _showBlurSlider(context);
        } else if (value == 'EffectToggle') {
          colorBlindnessProvider.toggleEffect();
        } else {
          colorBlindnessProvider.setEffect(value);
        }
      },
      itemBuilder: (context) => [
        // ✅ TEMALAR
        _buildThemeOption('Light', 'Light Theme', context),
        _buildThemeOption('Dark', 'Dark Theme', context),
        const PopupMenuDivider(),

        // ✅ RENK KÖRLÜĞÜ MODLARI
        _buildColorBlindnessOption(ColorBlindnessProvider.protanopia, "Protanopia"),
        _buildColorBlindnessOption(ColorBlindnessProvider.deuteranopia, "Deuteranopia"),
        _buildColorBlindnessOption(ColorBlindnessProvider.tritanopia, "Tritanopia"),
        _buildColorBlindnessOption(ColorBlindnessProvider.achromatopsia, "Achromatopsia"),
        const PopupMenuDivider(),

        // ✅ BULANIKLIK AYARI
        const PopupMenuItem(
          value: 'BlurLevel',
          child: ListTile(
            title: Text('Set Blur Level'),
          ),
        ),

        // ✅ ETKİ AÇMA/KAPAMA SWITCH (State Güncellendi)
        PopupMenuItem(
          value: 'EffectToggle',
          child: StatefulBuilder(
            builder: (context, setState) {
              final isEffectOn = Provider.of<ColorBlindnessProvider>(context, listen: false).isEffectOn;
              return ListTile(
                title: const Text('Effect On/Off'),
                trailing: Switch(
                  value: isEffectOn,
                  onChanged: (value) {
                    Provider.of<ColorBlindnessProvider>(context, listen: false).toggleEffect();
                    setState(() {}); // ✅ Switch değiştiğinde UI güncellensin!
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ✅ TEMALAR İÇİN TEKRARLAYAN KODLARI AZALTMAK İÇİN FONKSİYON
  PopupMenuItem<String> _buildThemeOption(String value, String title, BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final isSelected = (value == 'Dark' && isDarkMode) || (value == 'Light' && !isDarkMode);

    return PopupMenuItem(
      value: value,
      child: ListTile(
        title: Text(title),
        trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
      ),
    );
  }

  // ✅ RENK KÖRLÜĞÜ MODLARI İÇİN TEKRARLAYAN KODLARI AZALTMAK İÇİN FONKSİYON
  PopupMenuItem<String> _buildColorBlindnessOption(String effect, String title) {
    return PopupMenuItem(
      value: effect,
      child: Consumer<ColorBlindnessProvider>(
        builder: (context, provider, child) {
          return ListTile(
            title: Text(title),
            trailing: provider.currentEffect == effect ? const Icon(Icons.check, color: Colors.blue) : null,
          );
        },
      ),
    );
  }

  // ✅ BLUR LEVEL AYARI (PROVIDER’DAN EN GÜNCEL HALİ ALINIYOR!)
  void _showBlurSlider(BuildContext context) {
    final provider = Provider.of<ColorBlindnessProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) {
        double blurValue = provider.blurLevel; // ✅ En güncel değeri alıyoruz
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Set Blur Level'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${(blurValue * 10).toInt()}%'), // ✅ Yüzdelik gösterim
                  Slider(
                    value: blurValue,
                    min: 0.0,
                    max: 9.0,
                    divisions: 10,
                    label: '${(blurValue * 10).toInt()}%',
                    onChanged: (value) {
                      setState(() {
                        blurValue = value;
                      });
                      provider.setBlurLevel(value); // ✅ Provider'ı güncelliyoruz
                    },
                  ),
                ],
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
      },
    );
  }
}
