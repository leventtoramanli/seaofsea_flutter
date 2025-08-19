// lib/widgets/custon_scaffold.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/menu_items_provider.dart';
import 'package:seaofsea/utils/theme_selector.dart';

class CustomScaffold extends StatelessWidget {
  final String? title;
  final Widget? body;
  final List<Widget>? actions; // ekstra aksiyon eklemek istersen
  final Widget? floatingActionButton;

  const CustomScaffold({
    super.key,
    this.title,
    this.body,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final menuProvider = Provider.of<MenuItemsProvider>(context);
    final width = MediaQuery.of(context).size.width;

    // kırılımlar
    final bool wideScreen = width > 650; // AppBar'da ikon/text göster
    final bool textButtons = width > 950; // ikon + metin mi, sadece ikon mu?

    final items = menuProvider.getVisibleMenuItems(context).toList();

    // AppBar'a kaç tane sığdıracağımızı hesapla (ThemeSelector da bir slot)
    final maxVisible = _maxVisibleForWidth(width) - 1; // -1: ThemeSelector
    final visibleCount =
        math.max(0, math.min(items.length, math.max(0, maxVisible)));

    final visible = items.take(visibleCount).toList();
    final overflow = items.skip(visibleCount).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            TextButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                clipBehavior: Clip.antiAlias,
                child: const Image(
                  image: AssetImage('assets/logo256.png'),
                  height: 40,
                  width: 40,
                ),
              ),
            ),
            SizedBox(width: wideScreen ? 10 : 7),
            Text(title ?? ''),
          ],
        ),
        actions: [
          if (wideScreen) ...[
            // Görünen menü ögeleri
            ...List.generate(visible.length, (i) {
              final item = visible[i];
              return textButtons
                  ? TextButton.icon(
                      onPressed: () => item.onTap?.call(context),
                      icon: Icon(item.icon, color: Colors.white),
                      label: Text(item.label,
                          style: const TextStyle(color: Colors.white)),
                    )
                  : IconButton(
                      icon: Icon(item.icon),
                      tooltip: item.label,
                      onPressed: () => item.onTap?.call(context),
                    );
            }),

            // Taşanlar → More menüsü
            if (overflow.isNotEmpty)
              PopupMenuButton<int>(
                tooltip: 'More',
                icon: const Icon(Icons.more_vert),
                onSelected: (ix) => overflow[ix].onTap?.call(context),
                itemBuilder: (ctx) => List.generate(overflow.length, (ix) {
                  final it = overflow[ix];
                  return PopupMenuItem<int>(
                    value: ix,
                    child: Row(
                      children: [
                        Icon(it.icon, size: 18),
                        const SizedBox(width: 8),
                        Text(it.label),
                      ],
                    ),
                  );
                }),
              ),

            // Dışarıdan verilen ekstra aksiyonlar (varsa)
            if (actions != null) ...actions!,
          ],

          // Tema seçici her durumda en sonda
          const ThemeSelector(),
        ],
      ),

      // Küçük ekranda Drawer
      drawer: !wideScreen
          ? Drawer(
              child: ListView(
                children: [
                  const DrawerHeader(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      image: DecorationImage(
                        image: AssetImage('assets/logo.png'),
                        fit: BoxFit.fitWidth,
                        colorFilter: ColorFilter.mode(
                          Colors.black54,
                          BlendMode.dstATop,
                        ),
                      ),
                    ),
                    child: Text('',
                        style: TextStyle(color: Colors.white, fontSize: 24)),
                  ),
                  ...items.map((item) => ListTile(
                        leading: Icon(item.icon),
                        title: Text(item.label),
                        onTap: () => item.onTap?.call(context),
                      )),
                  if (actions != null && actions!.isNotEmpty) const Divider(),
                  // Drawer'da dış aksiyonları istersen burada da gösterebilirsin
                ],
              ),
            )
          : null,

      body: body ?? const SizedBox.shrink(),
      floatingActionButton: floatingActionButton,
    );
  }

  /// Ekran genişliğine göre kaç aksiyon gösterelim? (ThemeSelector hariç)
  int _maxVisibleForWidth(double w) {
    // İstersen bu sayıların ayarını yapabilirsin
    if (w >= 1400) return 8;
    if (w >= 1100) return 6;
    if (w >= 900) return 5;
    if (w >= 750) return 4;
    if (w >= 650) return 3;
    return 0; // küçük ekranda AppBar'da göstermiyoruz, Drawer var
  }
}
