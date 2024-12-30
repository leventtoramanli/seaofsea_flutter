import 'package:flutter/material.dart';

const Color seedColor = Color(0xFF213555); // Denizcilik için temel mavi

ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.light),
  brightness: Brightness.light,
  appBarTheme: AppBarTheme(
    backgroundColor: ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.light).primary,
    foregroundColor: Colors.white, // Başlık ve ikonlar
    elevation: 4,
    shadowColor: Colors.black,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.grey.shade200,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0),
      borderSide: const BorderSide(color: Colors.transparent),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0),
      borderSide: const BorderSide(color: Colors.transparent),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0),
      borderSide: BorderSide(color: ColorScheme.fromSeed(seedColor: seedColor).primary),
    ),
    labelStyle: TextStyle(color: seedColor),
  ),
);

ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.dark),
  brightness: Brightness.dark,
  appBarTheme: AppBarTheme(
    backgroundColor: ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.dark).surface,
    foregroundColor: Colors.white,
    elevation: 2,
    shadowColor: Colors.white,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.grey.shade800,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0),
      borderSide: const BorderSide(color: Colors.transparent),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0),
      borderSide: const BorderSide(color: Colors.transparent),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0),
      borderSide: BorderSide(color: ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.dark).primary),
    ),
    labelStyle: const TextStyle(color: Colors.white),
  ),
);

BoxDecoration getLightBoxDecoration() {
  return BoxDecoration(
    color: Colors.grey.shade100,
    borderRadius: BorderRadius.circular(12.0),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.shade400,
        blurRadius: 12,
        offset: const Offset(0, 6),
      ),
    ],
  );
}

BoxDecoration getDarkBoxDecoration() {
  return BoxDecoration(
    color: Colors.grey.shade900,
    borderRadius: BorderRadius.circular(12.0),
    boxShadow: const [
      BoxShadow(
        color: Colors.black54,
        blurRadius: 12,
        offset: Offset(0, 6),
      ),
    ],
  );
}
