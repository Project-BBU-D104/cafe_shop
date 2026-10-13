import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light = ThemeData(
    brightness: Brightness.light,

    primaryColor: const Color(0xff35180C),

    scaffoldBackgroundColor: const Color(0xffFFF9F7),

    cardColor: Colors.white,

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xff24130C),
      elevation: 0,
    ),

    colorScheme: const ColorScheme.light(
      primary: Color(0xff35180C),
      onPrimary: Colors.white,
      primaryContainer: Color(0xffFFF0EB),
      onPrimaryContainer: Color(0xff35180C),
      secondary: Color(0xff9A4D21),
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: Color(0xff24130C),
      error: Color(0xffCA0B00),
    ),

    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: const Color(0xffFFF0EB),
      hintStyle: TextStyle(color: Colors.grey.shade600),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(
          color: Color(0xff35180C),
          width: 1,
        ),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xff35180C),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xff35180C),
      foregroundColor: Colors.white,
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xffFFF0EB),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? const Color(0xff35180C)
              : Colors.grey.shade600,
        ),
      ),
    ),

    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Color(0xffFFF0EB),
      selectedIconTheme: IconThemeData(
        color: Color(0xff35180C),
      ),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? const Color(0xff35180C)
            : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? const Color(0xff35180C).withValues(alpha: 0.5)
            : null,
      ),
    ),

    dialogTheme: const DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Color(0xff35180C),
    ),

    listTileTheme: const ListTileThemeData(
      iconColor: Color(0xff35180C),
    ),

    dividerTheme: const DividerThemeData(
      color: Color(0xffEADDD6),
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