import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const _keyTheme = 'theme_mode';
  static const _keyFontSize = 'font_size';
  static const _keyScrollSpeed = 'scroll_speed';
  static const _keyShowChords = 'show_chords';
  static const _keyScrollPxPerBeat = 'scroll_px_per_beat';

  ThemeMode _themeMode = ThemeMode.system;
  double _fontSize = 18.0;
  double _scrollSpeed = 50.0; // pixels per second
  bool _showChords = true;
  // Pixels scrolled per beat in tempo-sync mode. Roughly calibrated so one
  // lyric line (~40-45px at default font size) advances every ~4 beats
  // (one bar of 4/4) — i.e. the pace lyrics actually go by in a live song,
  // not a literal per-beat scroll.
  double _scrollPxPerBeat = 10.0;

  ThemeMode get themeMode => _themeMode;
  double get fontSize => _fontSize;
  double get scrollSpeed => _scrollSpeed;
  bool get showChords => _showChords;
  double get scrollPxPerBeat => _scrollPxPerBeat;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = ThemeMode.values[prefs.getInt(_keyTheme) ?? 0];
    _fontSize = prefs.getDouble(_keyFontSize) ?? 18.0;
    _scrollSpeed = prefs.getDouble(_keyScrollSpeed) ?? 50.0;
    _showChords = prefs.getBool(_keyShowChords) ?? true;
    _scrollPxPerBeat = prefs.getDouble(_keyScrollPxPerBeat) ?? 10.0;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTheme, mode.index);
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
