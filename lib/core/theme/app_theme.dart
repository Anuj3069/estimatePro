import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() => ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
  );

  static ThemeData dark() => ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
  );
}
