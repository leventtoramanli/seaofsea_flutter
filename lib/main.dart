import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seaofsea/services/providers.dart';
import 'package:seaofsea/services/routes.dart';
import 'package:seaofsea/utils/auth_provider.dart';
import 'package:seaofsea/utils/color_blindness_provider.dart';
import 'package:seaofsea/utils/theme_data.dart';
import 'package:seaofsea/utils/theme_provider.dart';
import 'package:seaofsea/utils/theme_selector.dart';
import 'package:seaofsea/vievs/auth_page.dart';
import 'package:seaofsea/vievs/home_page.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  if (const bool.fromEnvironment('dart.vm.product') == false) {
    HttpOverrides.global = MyHttpOverrides();
  }
  runApp(
    MultiProvider(
      providers: providers,
      child: const MmsApp(),
    ),
  );
}

class MmsApp extends StatelessWidget {
  const MmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colorBlindnessProvider = Provider.of<ColorBlindnessProvider>(context);

    return Directionality(
      textDirection: TextDirection.ltr, // Yazı yönü belirtildi
      child: Stack(
        children: [
          // Renk filtresi uygulaması
          ColorFiltered(
            colorFilter: colorBlindnessProvider.currentFilter,
            child: MaterialApp(
              title: 'SeaOfSea',
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: themeProvider.themeMode,
              onGenerateRoute: generateRoute,
              initialRoute: '/',
            ),
          ),
          // Blur efekti ve tıklama yönetimi
          if (colorBlindnessProvider.isEffectOn &&
              colorBlindnessProvider.currentEffect ==
                  ColorBlindnessProvider.blur)
            BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: colorBlindnessProvider.blurLevel.clamp(0.0, 5.0),
                sigmaY: colorBlindnessProvider.blurLevel.clamp(0.0, 5.0),
              ),
              child: Container(
                color: Colors.black.withAlpha(10), // Hafif bir opaklık
                child: GestureDetector(
                  onTap: () {
                    // Kullanıcı bulanıklığı kapatabilir
                    colorBlindnessProvider.toggleEffect();
                  },
                  child: const SizedBox.expand(), // Tüm alanı kapsar
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
