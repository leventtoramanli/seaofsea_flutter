import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/utils/api_manager.dart';
import 'package:seaofsea/utils/auth_provider.dart';
import 'package:seaofsea/utils/color_blindness_provider.dart';
import 'package:seaofsea/utils/theme_data.dart';
import 'package:seaofsea/utils/theme_provider.dart';
import 'package:seaofsea/utils/theme_selector.dart';
import 'package:seaofsea/vievs/auth_page.dart';
import 'package:seaofsea/vievs/home_page.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider<ApiManager>(
            create: (_) => ApiManager(
                baseUrl: 'https://seaofsea.com', baseAddress: '/public/api')),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ColorBlindnessProvider()),
      ],
      child: const MmsApp(),
    ),
  );
}

class MmsApp extends StatelessWidget {
  const MmsApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colorBlindnessProvider = Provider.of<ColorBlindnessProvider>(context);
    return MaterialApp(
      title: 'SeaOfSea',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeProvider.themeMode,
      home: Stack(
        children: [
          ColorFiltered(
            colorFilter: colorBlindnessProvider.currentFilter,
            child: const MainPage(),
          ),
          if (colorBlindnessProvider.isEffectOn &&
              colorBlindnessProvider.currentEffect ==
                  ColorBlindnessProvider.blur)
            IgnorePointer(
              ignoring: true,
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: colorBlindnessProvider.blurLevel.clamp(0.0, 5.0),
                  sigmaY: colorBlindnessProvider.blurLevel.clamp(0.0, 5.0),
                ),
                child: Container(
                  color: Colors.black, // Hafif bir renk
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("SeaOfSea"),
        centerTitle: true,
        actions: [
          ThemeSelector(themeProvider: themeProvider),
        ],
      ),
      body: authProvider.isLoggedIn
          ? const HomePage()
          : const AuthPage(
              mode: AuthMode.login,
            ),
    );
  }
}
