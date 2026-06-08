import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  ThemeData get currentTheme {
    return _isDarkMode ? darkTheme : lightTheme;
  }

  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0F0F1E),
    primaryColor: const Color(0xFF6A11CB),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF6A11CB),
      secondary: Color(0xFF2575FC),
      surface: Color(0xFF1E1E2E),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
  );

  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF5F7FA),
    primaryColor: const Color(0xFF6A11CB),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF6A11CB),
      secondary: Color(0xFF2575FC),
      surface: Colors.white,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF0F0F1E)),
      bodyMedium: TextStyle(color: Colors.black54),
    ),
  );
}
