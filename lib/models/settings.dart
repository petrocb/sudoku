import 'package:flutter/material.dart';

class Settings {
  final bool showConflicts;
  final bool haptics;
  final ThemeMode themeMode;

  const Settings({
    required this.showConflicts,
    required this.haptics,
    required this.themeMode,
  });

  factory Settings.defaults() => const Settings(
        showConflicts: true,
        haptics: true,
        themeMode: ThemeMode.system,
      );

  Settings copyWith({
    bool? showConflicts,
    bool? haptics,
    ThemeMode? themeMode,
  }) {
    return Settings(
      showConflicts: showConflicts ?? this.showConflicts,
      haptics: haptics ?? this.haptics,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  Map<String, dynamic> toJson() => {
        'showConflicts': showConflicts,
        'haptics': haptics,
        'themeMode': themeMode.name,
      };

  static Settings fromJson(Map<String, dynamic> json) {
    final themeStr = (json['themeMode'] ?? 'system').toString();
    final ThemeMode mode = switch (themeStr) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    return Settings(
      showConflicts: json['showConflicts'] != false,
      haptics: json['haptics'] != false,
      themeMode: mode,
    );
  }
}