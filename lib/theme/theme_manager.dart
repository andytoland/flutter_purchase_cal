import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTheme { 
  originalDark, 
  modernDark, 
  light, 
  highContrastDark, 
  softBlueLush, 
  midnightGreen, 
  royalPurple, 
  crimsonRed,
  lavenderMist,
  sageGarden,
  sandyBeach,
  minimalWhite
}

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
      case AppTheme.highContrastDark:
        return ThemeData(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFFFFF00), // Neon Yellow
            surface: Colors.black,
            onSurface: Colors.white,
            onPrimary: Colors.black,
          ),
          scaffoldBackgroundColor: Colors.black,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            foregroundColor: Color(0xFFFFFF00),
          ),
        );
      case AppTheme.softBlueLush:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF7D9BB2),
            brightness: Brightness.light,
            surface: const Color(0xFFF0F4F7),
          ),
          scaffoldBackgroundColor: const Color(0xFFF0F4F7),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF90A4AE),
            foregroundColor: Colors.white,
          ),
        );
      case AppTheme.midnightGreen:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0F3D3E),
            brightness: Brightness.dark,
            primary: const Color(0xFF100720),
            surface: const Color(0xFF1B2430),
          ),
          scaffoldBackgroundColor: const Color(0xFF0F3D3E),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF100720),
            foregroundColor: Color(0xFFE2D5B1),
          ),
        );
      case AppTheme.royalPurple:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF310A31),
            brightness: Brightness.dark,
            primary: const Color(0xFF845EC2),
          ),
          scaffoldBackgroundColor: const Color(0xFF1A1A2E),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF4B4453),
            foregroundColor: Color(0xFFFEFEDF),
          ),
        );
      case AppTheme.crimsonRed:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF880808),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF1A1A1A),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF630330),
            foregroundColor: Colors.white,
          ),
        );
      case AppTheme.lavenderMist:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFE6E6FA),
            brightness: Brightness.light,
            surface: const Color(0xFFF8F8FF),
          ),
          scaffoldBackgroundColor: const Color(0xFFF8F8FF),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFDCD0FF),
            foregroundColor: Colors.black87,
          ),
        );
      case AppTheme.sageGarden:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFE0E7DA),
            brightness: Brightness.light,
            surface: const Color(0xFFF1F4EE),
          ),
          scaffoldBackgroundColor: const Color(0xFFF1F4EE),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFB8C4AF),
            foregroundColor: Colors.black87,
          ),
        );
      case AppTheme.sandyBeach:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFF5F5DC),
            brightness: Brightness.light,
            surface: const Color(0xFFFFFDE7),
          ),
          scaffoldBackgroundColor: const Color(0xFFFFFDE7),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFFFECB3),
            foregroundColor: Colors.black87,
          ),
        );
      case AppTheme.minimalWhite:
        return ThemeData(
          colorScheme: const ColorScheme.light(
            primary: Colors.blueGrey,
            surface: Colors.white,
            onSurface: Colors.black,
            onPrimary: Colors.white,
          ),
          scaffoldBackgroundColor: Colors.white,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 1,
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
