import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'app_settings_provider.g.dart';

@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in main.dart');
}

class AppSettingsState {
  final ThemeMode themeMode;
  final String languageCode;

  const AppSettingsState({
    this.themeMode = ThemeMode.system,
    this.languageCode = 'en',
  });

  AppSettingsState copyWith({ThemeMode? themeMode, String? languageCode}) {
    return AppSettingsState(
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
    );
  }
}

@Riverpod(keepAlive: true)
class AppSettings extends _$AppSettings {
  static const String _themeKey = 'theme_mode';
  static const String _langKey = 'language_code';

  @override
  AppSettingsState build() {
    final prefs = ref.read(sharedPreferencesProvider);
    
    final themeString = prefs.getString(_themeKey);
    ThemeMode themeMode = ThemeMode.system;
    if (themeString == 'light') themeMode = ThemeMode.light;
    if (themeString == 'dark') themeMode = ThemeMode.dark;

    final langCode = prefs.getString(_langKey) ?? 'en';

    return AppSettingsState(themeMode: themeMode, languageCode: langCode);
  }

  Future<void> changeTheme(ThemeMode mode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    String themeString = 'system';
    if (mode == ThemeMode.light) themeString = 'light';
    if (mode == ThemeMode.dark) themeString = 'dark';

    await prefs.setString(_themeKey, themeString);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> changeLanguage(String langCode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_langKey, langCode);
    state = state.copyWith(languageCode: langCode);
  }
}