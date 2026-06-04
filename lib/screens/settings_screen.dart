import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ── Appearance ─────────────────────────────────────────────────
          _SectionHeader('Appearance'),
          ListTile(
            title: const Text('Theme'),
            subtitle: Text(_themeName(settings.themeMode)),
            leading: const Icon(Icons.brightness_6_outlined),
            onTap: () => _pickTheme(context, settings),
          ),

          // ── Song viewer ────────────────────────────────────────────────
          _SectionHeader('Song viewer'),
          SwitchListTile(
            title: const Text('Show chords by default'),
            subtitle: const Text('Can be toggled per song'),
            secondary: const Icon(Icons.music_note_outlined),
            value: settings.showChords,
            onChanged: settings.setShowChords,
          ),
          ListTile(
            title: const Text('Default font size'),
            subtitle: Text('${settings.fontSize.round()} pt'),
            leading: const Icon(Icons.format_size),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: settings.fontSize > 12
                      ? () => settings.setFontSize(settings.fontSize - 2)
                      : null,
                ),
                Text('${settings.fontSize.round()}',
                    style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: settings.fontSize < 32
                      ? () => settings.setFontSize(settings.fontSize + 2)
                      : null,
                ),
              ],
            ),
          ),

          // ── Auto-scroll ────────────────────────────────────────────────
          _SectionHeader('Auto-scroll'),
          ListTile(
            title: const Text('Default scroll speed'),
            subtitle: Text('${settings.scrollSpeed.round()} px / second'),
            leading: const Icon(Icons.speed),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Slider(
              value: settings.scrollSpeed,
              min: 10,
              max: 200,
              divisions: 38,
              label: '${settings.scrollSpeed.round()}',
              onChanged: settings.setScrollSpeed,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Slow',
                    style: Theme.of(context).textTheme.bodySmall),
                Text('Fast',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _themeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System default';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  Future<void> _pickTheme(
      BuildContext context, SettingsProvider settings) async {
    final picked = await showDialog<ThemeMode>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Choose theme'),
        children: ThemeMode.values.map((mode) {
          return ListTile(
            title: Text(_themeName(mode)),
            leading: mode == settings.themeMode
                ? const Icon(Icons.check)
                : const SizedBox(width: 24),
            onTap: () => Navigator.pop(context, mode),
          );
        }).toList(),
      ),
    );
    if (picked != null) settings.setThemeMode(picked);
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
