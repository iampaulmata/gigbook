import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/custom_theme.dart';

class SettingsProvider extends ChangeNotifier {
  static const _keyTheme = 'theme_mode';
  static const _keyFontSize = 'font_size';
  static const _keyScrollSpeed = 'scroll_speed';
  static const _keyShowChords = 'show_chords';
  static const _keyScrollPxPerBeat = 'scroll_px_per_beat';
  static const _keyCustomThemes = 'custom_themes';
  static const _keyActiveCustomThemeName = 'active_custom_theme_name';
  static const _keyUseCustomTheme = 'use_custom_theme';

  ThemeMode _themeMode = ThemeMode.system;
  double _fontSize = 18.0;
  double _scrollSpeed = 50.0; // pixels per second
  bool _showChords = true;
  // Pixels scrolled per beat in tempo-sync mode. Roughly calibrated so one
  // lyric line (~40-45px at default font size) advances every ~4 beats
  // (one bar of 4/4) — i.e. the pace lyrics actually go by in a live song,
  // not a literal per-beat scroll.
  double _scrollPxPerBeat = 10.0;
  List<CustomTheme> _customThemes = [];
  String? _activeCustomThemeName;
  bool _useCustomTheme = false;

  ThemeMode get themeMode => _themeMode;
  double get fontSize => _fontSize;
  double get scrollSpeed => _scrollSpeed;
  bool get showChords => _showChords;
  double get scrollPxPerBeat => _scrollPxPerBeat;
  List<CustomTheme> get customThemes => List.unmodifiable(_customThemes);
  String? get activeCustomThemeName => _activeCustomThemeName;
  bool get useCustomTheme => _useCustomTheme;

  /// The currently-active custom theme, if any (useCustomTheme is true and
  /// activeCustomThemeName still refers to a saved theme).
  CustomTheme? get activeCustomTheme {
    if (!_useCustomTheme || _activeCustomThemeName == null) return null;
    for (final t in _customThemes) {
      if (t.name == _activeCustomThemeName) return t;
    }
    return null;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = ThemeMode.values[prefs.getInt(_keyTheme) ?? 0];
    _fontSize = prefs.getDouble(_keyFontSize) ?? 18.0;
    _scrollSpeed = prefs.getDouble(_keyScrollSpeed) ?? 50.0;
    _showChords = prefs.getBool(_keyShowChords) ?? true;
    _scrollPxPerBeat = prefs.getDouble(_keyScrollPxPerBeat) ?? 10.0;
    _customThemes = _decodeCustomThemes(prefs.getString(_keyCustomThemes));
    _activeCustomThemeName = prefs.getString(_keyActiveCustomThemeName);
    _useCustomTheme = prefs.getBool(_keyUseCustomTheme) ?? false;
    notifyListeners();
  }

  List<CustomTheme> _decodeCustomThemes(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => CustomTheme.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _persistCustomThemes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_customThemes.map((t) => t.toJson()).toList());
    await prefs.setString(_keyCustomThemes, raw);
  }

  bool customThemeNameExists(String name) {
    return _customThemes.any((t) => t.name == name);
  }

  /// Creates a new saved theme or updates an existing one with the same
  /// name (FR-005) — the caller decides which by the name it passes.
  Future<void> saveCustomTheme(CustomTheme theme) async {
    final index = _customThemes.indexWhere((t) => t.name == theme.name);
    if (index >= 0) {
      _customThemes[index] = theme;
    } else {
      _customThemes.add(theme);
    }
    notifyListeners();
    await _persistCustomThemes();
  }

  /// Deletes a saved theme (FR-015). If it was the active theme, falls back
  /// to ThemeMode.system rather than leaving the app in an undefined visual
  /// state (FR-016).
  Future<void> deleteCustomTheme(String name) async {
    _customThemes.removeWhere((t) => t.name == name);
    final prefs = await SharedPreferences.getInstance();

    if (_activeCustomThemeName == name) {
      _activeCustomThemeName = null;
      _useCustomTheme = false;
      await prefs.remove(_keyActiveCustomThemeName);
      await prefs.setBool(_keyUseCustomTheme, false);
    }

    notifyListeners();
    await _persistCustomThemes();
  }

  /// Selects "Custom" as the active app theme, applying [name] (FR-010).
  Future<void> applyCustomTheme(String name) async {
    _activeCustomThemeName = name;
    _useCustomTheme = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyActiveCustomThemeName, name);
    await prefs.setBool(_keyUseCustomTheme, true);
  }

  /// Records [name] as the most recently selected custom theme (FR-010)
  /// without necessarily making Custom the live app theme — used when the
  /// user recalls a saved theme in the Custom Theme screen's editor, so the
  /// *next* time they pick "Custom" in the main theme picker it applies
  /// that recalled theme rather than a stale, earlier selection (bug: the
  /// main picker's "Custom" option got permanently stuck on whichever
  /// theme was applied first).
  Future<void> setMostRecentCustomThemeName(String name) async {
    _activeCustomThemeName = name;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyActiveCustomThemeName, name);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    // A custom theme may currently be active — picking System/Light/Dark
    // MUST actually switch away from it, not just change the mode that
    // will apply once Custom is turned off some other way (bug: switching
    // back to a default theme silently did nothing).
    _useCustomTheme = false;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTheme, mode.index);
    await prefs.setBool(_keyUseCustomTheme, false);
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size.clamp(12.0, 32.0);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyFontSize, _fontSize);
  }

  Future<void> setScrollSpeed(double speed) async {
    _scrollSpeed = speed.clamp(10.0, 200.0);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyScrollSpeed, _scrollSpeed);
  }

  Future<void> setShowChords(bool value) async {
    _showChords = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowChords, value);
  }

  Future<void> setScrollPxPerBeat(double value) async {
    _scrollPxPerBeat = value.clamp(2.0, 40.0);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyScrollPxPerBeat, _scrollPxPerBeat);
  }
}
