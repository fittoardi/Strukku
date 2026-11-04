import 'package:flutter/material.dart';

const _teal = Color(0xFF009688);

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  colorSchemeSeed: _teal,
  brightness: Brightness.light,
  fontFamily: 'Roboto',
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    elevation: 0,
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    filled: true,
  ),
  cardTheme: CardThemeData(
    elevation: 1,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    elevation: 2,
  ),
);

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  colorSchemeSeed: _teal,
  brightness: Brightness.dark,
  fontFamily: 'Roboto',
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    elevation: 0,
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    filled: true,
  ),
  cardTheme: CardThemeData(
    elevation: 1,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    elevation: 2,
  ),
);
