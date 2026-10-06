import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light = ThemeData(
    brightness: Brightness.light,

    primaryColor: const Color(0xff007bff),

    scaffoldBackgroundColor: const Color(0xfff5f5f5),

    cardColor: Colors.white,

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xff007bff),
      foregroundColor: Colors.white,
      elevation: 0,
    ),

    colorScheme: const ColorScheme.light(
      primary: Color(0xff007bff),
      secondary: Color(0xffffc107),
      surface: Colors.white,
    ),
  );

  static ThemeData dark = ThemeData(
    brightness: Brightness.dark,

    primaryColor: const Color(0xff007bff),

    scaffoldBackgroundColor: const Color(0xff121212),

    cardColor: const Color(0xff1e1e1e),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xff1e1e1e),
      foregroundColor: Colors.white,
      elevation: 0,
    ),

    colorScheme: const ColorScheme.dark(
      primary: Color(0xff007bff),
      secondary: Color(0xffffc107),
      surface: Color(0xff1e1e1e),
    ),
  );
}