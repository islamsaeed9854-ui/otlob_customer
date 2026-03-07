import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings_state.dart';

@singleton
class AppSettingsCubit extends Cubit<AppSettingsState> {
  final SharedPreferences _prefs;

  static const String _themeKey = 'theme_mode';
  static const String _langKey = 'language_code';

  AppSettingsCubit(this._prefs) : super(const AppSettingsState()) {
    _loadSettings();
  }

  void _loadSettings() {
    final themeString = _prefs.getString(_themeKey);
    ThemeMode themeMode = ThemeMode.system;
    if (themeString == 'light') themeMode = ThemeMode.light;
    if (themeString == 'dark') themeMode = ThemeMode.dark;

    final langCode = _prefs.getString(_langKey) ?? 'en';

    emit(state.copyWith(themeMode: themeMode, languageCode: langCode));
  }

  Future<void> changeTheme(ThemeMode mode) async {
    String themeString = 'system';
    if (mode == ThemeMode.light) themeString = 'light';
    if (mode == ThemeMode.dark) themeString = 'dark';

    await _prefs.setString(_themeKey, themeString);
    emit(state.copyWith(themeMode: mode));
  }

  Future<void> changeLanguage(String langCode) async {
    await _prefs.setString(_langKey, langCode);
    emit(state.copyWith(languageCode: langCode));
  }
}
