import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../themes/app_theme.dart';

const _kThemePref = 'app_theme_mode';

class ThemeProvider extends ChangeNotifier {
  AppThemeMode _mode = AppThemeMode.sepia;

  AppThemeMode get mode => _mode;
  ThemeData get themeData => AppTheme.forMode(_mode);
  bool get isSepia => _mode == AppThemeMode.sepia;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kThemePref);
    if (saved == AppThemeMode.darkPurple.name) {
      _mode = AppThemeMode.darkPurple;
      notifyListeners();
    }
  }

  Future<void> setMode(AppThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemePref, mode.name);
  }
}
