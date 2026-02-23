import 'package:flutter/material.dart';
import '../models/settings.dart';
import '../services/storage_service.dart';

class SettingsController extends ChangeNotifier {
  final StorageService _storage;

  Settings _settings = Settings.defaults();
  bool _loaded = false;

  SettingsController(this._storage);

  Settings get settings => _settings;
  bool get isLoaded => _loaded;

  ThemeMode get themeMode => _settings.themeMode;
  bool get showConflicts => _settings.showConflicts;
  bool get haptics => _settings.haptics;

  Future<void> load() async {
    _settings = await _storage.loadSettings();
    _loaded = true;
    notifyListeners();
  }

  Future<void> setShowConflicts(bool v) async {
    _settings = _settings.copyWith(showConflicts: v);
    notifyListeners();
    await _storage.saveSettings(_settings);
  }

  Future<void> setHaptics(bool v) async {
    _settings = _settings.copyWith(haptics: v);
    notifyListeners();
    await _storage.saveSettings(_settings);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _settings = _settings.copyWith(themeMode: mode);
    notifyListeners();
    await _storage.saveSettings(_settings);
  }
}