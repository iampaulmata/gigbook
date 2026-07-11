import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/custom_theme.dart';
import '../providers/settings_provider.dart';
import '../services/contrast.dart';
import '../theme/app_theme.dart';
import '../widgets/theme_preview.dart';

/// Asks the user to confirm overwriting an existing saved theme named
/// [name] (FR-017). Shared by the manual save flow here and by the import
/// flow's name-collision handling (FR-019).
Future<bool> confirmNameCollision(BuildContext context, String name) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Theme name already used'),
      content: Text(
          'A saved theme named "$name" already exists. Overwrite it with these colors?'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
        TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Overwrite')),
      ],
    ),
  );
  return confirmed ?? false;
}

class CustomThemeScreen extends StatefulWidget {
  const CustomThemeScreen({super.key});

  @override
  State<CustomThemeScreen> createState() => _CustomThemeScreenState();
}

class _CustomThemeScreenState extends State<CustomThemeScreen> {
  late CustomTheme _editing;
  late final TextEditingController _nameController;
  // The name of the theme this editing session is considered to be editing
  // in place (from initial load or the most recent successful save) — null
  // for a brand-new, never-saved theme. Distinguishes "saving under the same
  // name as what's loaded" (no collision) from "saving under a name that
  // collides with a *different* saved theme" (FR-017, needs confirmation).
  String? _loadedName;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    final activeCustom = settings.activeCustomTheme;
    if (activeCustom != null) {
      _editing = activeCustom;
      _loadedName = activeCustom.name;
    } else {
      // No custom theme yet — seed the editor from the currently active
      // app theme's colors as a starting point (spec Assumptions).
      final theme = Theme.of(context);
      final scheme = theme.colorScheme;
      final chordProColors = theme.extension<ChordProColors>();
      _editing = CustomTheme(
        name: '',
        backgroundColor: scheme.surface,
        textColor: scheme.onSurface,
        chordColor: chordProColors?.chord ?? scheme.primary,
        sectionHeaderColor: chordProColors?.sectionHeader ?? scheme.primary,
        commentColor: chordProColors?.comment ?? scheme.onSurfaceVariant,
      );
      _loadedName = null;
    }
    _nameController = TextEditingController(text: _editing.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickColor(
      String label, Color current, ValueChanged<Color> onChanged) async {
    final picked = await showColorPickerDialog(
      context,
      current,
      title: Text('Pick $label color', style: Theme.of(context).textTheme.titleMedium),
      showColorCode: true,
      colorCodeHasColor: true,
      pickersEnabled: const <ColorPickerType, bool>{
        ColorPickerType.both: false,
        ColorPickerType.primary: true,
        ColorPickerType.accent: true,
        ColorPickerType.bw: false,
        ColorPickerType.custom: false,
        ColorPickerType.wheel: true,
      },
    );
    onChanged(picked);
  }

  /// Text-bearing roles checked against the background for FR-018 —
  /// the label shown to the user matches the row label they'd fix.
  static const _contrastRoles = {
    'Text / lyrics': _RoleColor.text,
    'Chords': _RoleColor.chord,
    'Section headers': _RoleColor.sectionHeader,
    'Comments / annotations': _RoleColor.comment,
  };

  Color _colorFor(_RoleColor role) {
    switch (role) {
      case _RoleColor.text:
        return _editing.textColor;
      case _RoleColor.chord:
        return _editing.chordColor;
      case _RoleColor.sectionHeader:
        return _editing.sectionHeaderColor;
      case _RoleColor.comment:
        return _editing.commentColor;
    }
  }

  bool _rowContrastOk(_RoleColor role) {
    return meetsMinimumContrast(_editing.backgroundColor, _colorFor(role));
  }

  List<String> _failingRoleLabels() {
    return _contrastRoles.entries
        .where((e) => !_rowContrastOk(e.value))
        .map((e) => e.key)
        .toList();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final failing = _failingRoleLabels();
    if (failing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Not readable enough against the background: ${failing.join(', ')}. '
              'Adjust those colors (see the warning icons below) and try again.'),
        ),
      );
      return;
    }

    // A collision only matters against a *different* saved theme — saving
    // back under the name we loaded is an ordinary in-place update, not an
    // overwrite that needs confirming (FR-017).
    final settings = context.read<SettingsProvider>();
    if (name != _loadedName && settings.customThemeNameExists(name)) {
      final confirmed = await confirmNameCollision(context, name);
      if (!confirmed) return;
    }

    // Saving under the currently-loaded name updates that theme in place;
    // saving under a different name creates a new one (FR-005) — either way
    // SettingsProvider.saveCustomTheme upserts by name. _editing/_loadedName
    // are updated to the saved name so the dropdown/name field reflect the
    // save as loaded, rather than still pointing at what was loaded before.
    final saved = _editing.copyWith(name: name);
    await settings.saveCustomTheme(saved);
    if (mounted) {
      setState(() {
        _editing = saved;
        _loadedName = name;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Saved "$name"')));
    }
  }

  /// Recalls a saved theme's colors into the editor and preview (FR-006,
  /// FR-007).
  void _recall(CustomTheme theme) {
    setState(() {
      _editing = theme;
      _loadedName = theme.name;
      _nameController.text = theme.name;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Custom Theme')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (settings.customThemes.isNotEmpty) ...[
            DropdownButtonFormField<String>(
              initialValue: settings.customThemeNameExists(_editing.name)
                  ? _editing.name
                  : null,
              decoration: const InputDecoration(
                labelText: 'Load a saved theme',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final t in settings.customThemes)
                  DropdownMenuItem(value: t.name, child: Text(t.name)),
              ],
              onChanged: (name) {
                if (name == null) return;
                final theme =
                    settings.customThemes.firstWhere((t) => t.name == name);
                _recall(theme);
              },
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Theme name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          _ColorRow(
            label: 'Background',
            color: _editing.backgroundColor,
            onTap: () => _pickColor('background', _editing.backgroundColor,
                (c) => setState(() => _editing = _editing.copyWith(backgroundColor: c))),
          ),
          _ColorRow(
            label: 'Text / lyrics',
            color: _editing.textColor,
            contrastOk: _rowContrastOk(_RoleColor.text),
            onTap: () => _pickColor('text', _editing.textColor,
                (c) => setState(() => _editing = _editing.copyWith(textColor: c))),
          ),
          _ColorRow(
            label: 'Chords',
            color: _editing.chordColor,
            contrastOk: _rowContrastOk(_RoleColor.chord),
            onTap: () => _pickColor('chord', _editing.chordColor,
                (c) => setState(() => _editing = _editing.copyWith(chordColor: c))),
          ),
          _ColorRow(
            label: 'Section headers',
            color: _editing.sectionHeaderColor,
            contrastOk: _rowContrastOk(_RoleColor.sectionHeader),
            onTap: () => _pickColor(
                'section header',
                _editing.sectionHeaderColor,
                (c) => setState(
                    () => _editing = _editing.copyWith(sectionHeaderColor: c))),
          ),
          _ColorRow(
            label: 'Comments / annotations',
            color: _editing.commentColor,
            contrastOk: _rowContrastOk(_RoleColor.comment),
            onTap: () => _pickColor('comment', _editing.commentColor,
                (c) => setState(() => _editing = _editing.copyWith(commentColor: c))),
          ),
          const SizedBox(height: 24),
          Text('Preview', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ThemePreview(theme: _editing),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _save,
            child: const Text('Save theme'),
          ),
        ],
      ),
    );
  }
}

/// The four text-bearing color roles checked for contrast against the
/// background (FR-018) — background itself isn't compared against anything.
enum _RoleColor { text, chord, sectionHeader, comment }

class _ColorRow extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool contrastOk;

  const _ColorRow({
    required this.label,
    required this.color,
    required this.onTap,
    this.contrastOk = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: contrastOk
          ? Text(colorToHex(color))
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_outlined,
                    size: 16, color: theme.colorScheme.error),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '${colorToHex(color)} — too low contrast against the background',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ],
            ),
      trailing: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: contrastOk
                  ? theme.colorScheme.outline
                  : theme.colorScheme.error,
              width: contrastOk ? 1 : 2,
            ),
          ),
        ),
      ),
      onTap: onTap,
    );
  }
}
