import 'package:flutter/material.dart';

// Material3 theme, colors, and text styles
class AppTheme {
  static const Color navy = Color(0xFF1a365d);
  static const Color lightBlue = Color(0xFF3182ce);
  static const Color success = Color(0xFF38a169);
  static const Color warning = Color(0xFFd69e2e);
  static const Color danger = Color(0xFFe53e3e);
  static const Color background = Color(0xFFf7fafc);
  static const Color card = Colors.white;

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: navy,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: navy,
        onPrimary: Colors.white,
        secondary: lightBlue,
        onSecondary: Colors.white,
        error: danger,
        onError: Colors.white,
        background: background,
        onBackground: navy,
        surface: card,
        onSurface: navy,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          elevation: 2,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: navy),
        titleLarge: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: navy),
        bodyLarge: TextStyle(fontSize: 16, color: navy),
        bodyMedium: TextStyle(fontSize: 16, color: navy),
        bodySmall: TextStyle(fontSize: 14, color: navy),
        labelLarge: TextStyle(fontSize: 14, color: navy),
      ),
      iconTheme: const IconThemeData(size: 24, color: navy),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: card,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
      dividerTheme: const DividerThemeData(thickness: 1, color: Color(0xFFe2e8f0)),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: navy,
        contentTextStyle: TextStyle(color: Colors.white, fontSize: 16),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
      ),
    );
  }
} 