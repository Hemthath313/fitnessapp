import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for managing app theme (Light/Dark mode)
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  bool _isDarkMode = false; // Default to light mode (Hevy-style)
  
  ThemeProvider() {
    _loadThemePreference();
  }
  
  /// Get current theme mode
  bool get isDarkMode => _isDarkMode;
  
  /// Get current theme mode as ThemeMode enum
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  
  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  /// Toggle between light and dark theme
  Future<void> toggleTheme() async {
    _isProcessing = true;
    notifyListeners();
    
    // Small delay to allow loader to show and system to settle
    await Future.delayed(const Duration(milliseconds: 600));
    
    _isDarkMode = !_isDarkMode;
    await _saveThemePreference();
    ColorManager.updateTheme(_isDarkMode);
    
    _isProcessing = false;
    notifyListeners();
  }
  
  /// Set specific theme mode
  Future<void> setThemeMode(bool isDark) async {
    if (_isDarkMode != isDark) {
      _isDarkMode = isDark;
      await _saveThemePreference();
      ColorManager.updateTheme(_isDarkMode);
      notifyListeners();
    }
  }
  
  /// Load theme preference from storage
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_themeKey) ?? false; // Default to light
      ColorManager.updateTheme(_isDarkMode);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
    }
  }
  
  /// Save theme preference to storage
  Future<void> _saveThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkMode);
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }
}
