import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class AppSettingsState extends Equatable {
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

  @override
  List<Object> get props => [themeMode, languageCode];
}
