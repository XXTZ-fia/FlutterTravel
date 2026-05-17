import 'package:flutter/material.dart';

class Constants {
  static const String appName = "Flutter Travel";

  static const Color lightPrimary = Color(0xfffcfcff);
  static const Color darkPrimary = Colors.black;
  static final Color lightAccent = Colors.blueGrey.shade900;
  static const Color darkAccent = Colors.white;
  static const Color lightBG = Color(0xfffcfcff);
  static const Color darkBG = Colors.black;
  static const Color badgeColor = Colors.red;

  static ThemeData lightTheme = ThemeData(
    primaryColor: lightPrimary,
    scaffoldBackgroundColor: lightBG,
    colorScheme: ColorScheme.light(
      primary: lightPrimary,
      secondary: lightAccent,
      surface: lightBG,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: lightBG,
      foregroundColor: darkBG,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: darkBG,
        fontSize: 18.0,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: darkPrimary,
    scaffoldBackgroundColor: darkBG,
    colorScheme: const ColorScheme.dark(
      primary: darkPrimary,
      secondary: darkAccent,
      surface: darkBG,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: darkBG,
      foregroundColor: lightBG,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: lightBG,
        fontSize: 18.0,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}
