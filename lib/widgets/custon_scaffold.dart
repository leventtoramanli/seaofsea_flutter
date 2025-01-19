import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/menu_items_provider.dart';
import 'package:seaofsea/utils/theme_selector.dart';

class CustomScaffold extends StatelessWidget {
  final String? title;
  final Widget? body;

  const CustomScaffold({
    super.key,
    this.title,
    this.body,
  });

  get index => null;

  @override
  Widget build(BuildContext context) {
    final menuProvider = Provider.of<MenuItemsProvider>(context);
    final bool wideScreen = MediaQuery.of(context).size.width > 650;
    final bool tWideScreen = MediaQuery.of(context).size.width > 850;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/home');
              },
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
          if (wideScreen)
            ...menuProvider.getMenuItems(context).map((item) {
              if (tWideScreen) {
                return Row(
                  children: [
                    TextButton.icon(
                      onPressed: item['onTap'],
                      icon: Icon(item['icon'], color: Colors.white),
                      label: Text(
                        item['label'],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    if (index != menuProvider.getMenuItems(context).length - 1)
                      const Text(
                        '|',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                  ],
                );
              } else {
                return IconButton(
                  icon: Icon(item['icon']),
                  tooltip: item['label'],
                  onPressed: item['onTap'],
                );
              }
            // ignore: unnecessary_to_list_in_spreads
            }).toList(),
          const ThemeSelector(),
        ],
      ),
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
                        colorFilter: ColorFilter.mode(Colors.black54,
                            BlendMode.dstATop // Renk ve resim birleşimi
                            ),
                      ),
                    ),
                    child: Text(
                      '',
                      style: TextStyle(color: Colors.white, fontSize: 24),
                    ),
                  ),
                  ...menuProvider.getMenuItems(context).map((item) {
                    return ListTile(
                      leading: Icon(item['icon']),
                      title: Text(item['label']),
                      onTap: item['onTap'],
                    );
                  // ignore: unnecessary_to_list_in_spreads
                  }).toList(),
                ],
              ),
            )
          : null,
      body: body ?? const SizedBox.shrink(),
    );
  }
}
