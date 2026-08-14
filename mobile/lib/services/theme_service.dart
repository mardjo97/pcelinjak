import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';

class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  static const _prefsKey = 'app_theme_mode';
  static const _textScaleKey = 'app_text_scale';
  static const _autorotationKey = 'app_autorotation';

  static const double textScaleSmall = 0.9;
  static const double textScaleNormal = 1.0;
  static const double textScaleLarge = 1.15;
  static const double textScaleExtraLarge = 1.3;

  /// system | light | dark
  String _preference = 'system';
  double _textScaleFactor = textScaleNormal;
  bool _autorotation = true;

  String get preference => _preference;
  double get textScaleFactor => _textScaleFactor;
  bool get autorotation => _autorotation;

  ThemeMode get themeMode {
    switch (_preference) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _preference = prefs.getString(_prefsKey) ?? 'system';
    _textScaleFactor = prefs.getDouble(_textScaleKey) ?? textScaleNormal;
    _autorotation = prefs.getBool(_autorotationKey) ?? true;
    _applyOrientation();
    notifyListeners();
  }

  Future<void> setPreference(String code) async {
    _preference = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, code);
    notifyListeners();
  }

  Future<void> setTextScaleFactor(double value) async {
    if (_textScaleFactor == value) return;
    _textScaleFactor = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_textScaleKey, value);
    notifyListeners();
  }

  Future<void> setAutorotation(bool value) async {
    if (_autorotation == value) return;
    _autorotation = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autorotationKey, value);
    _applyOrientation();
    notifyListeners();
  }

  void _applyOrientation() {
    if (_autorotation) {
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
    }
  }

  static String labelFor(AppLocalizations l10n, String code) {
    switch (code) {
      case 'light':
        return l10n.themeLight;
      case 'dark':
        return l10n.themeDark;
      default:
        return l10n.themeSystem;
    }
  }
}
