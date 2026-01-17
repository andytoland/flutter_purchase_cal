import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTheme { originalDark, modernDark, light }

class ThemeManager extends ChangeNotifier {
  static const String _themeKey = 'selected_theme';
  static const String _bgKey = 'selected_background';
  
  AppTheme _currentTheme = AppTheme.originalDark;
  String? _selectedBackgroundImage;

  AppTheme get currentTheme => _currentTheme;
  String? get selectedBackgroundImage => _selectedBackgroundImage;

  ThemeManager() {
    _loadTheme();
  }

  void setTheme(AppTheme theme) async {
    _currentTheme = theme;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme.name);
  }

  void setBackgroundImage(String? path) async {
    _selectedBackgroundImage = path;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove(_bgKey);
    } else {
      await prefs.setString(_bgKey, path);
    }
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Theme
    final themeName = prefs.getString(_themeKey);
    if (themeName != null) {
      _currentTheme = AppTheme.values.firstWhere(
        (t) => t.name == themeName,
        orElse: () => AppTheme.originalDark,
      );
    }

    // Load Background
    _selectedBackgroundImage = prefs.getString(_bgKey);
    
    notifyListeners();
  }

  ThemeData getThemeData() {
    switch (_currentTheme) {
      case AppTheme.modernDark:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1A1A2E),
            brightness: Brightness.dark,
            primary: const Color(0xFF0F3460),
            surface: const Color(0xFF16213E),
          ),
          scaffoldBackgroundColor: const Color(0xFF1A1A2E),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0F3460),
            foregroundColor: Colors.white,
          ),
        );
      case AppTheme.light:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blueGrey,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.blueGrey,
            foregroundColor: Colors.white,
          ),
        );
      case AppTheme.originalDark:
      default:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.black,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
        );
    }
  }
}
