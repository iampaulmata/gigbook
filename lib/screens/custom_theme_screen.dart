import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/custom_theme.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/theme_preview.dart';

class CustomThemeScreen extends StatefulWidget {
  const CustomThemeScreen({super.key});

  @override
  State<CustomThemeScreen> createState() => _CustomThemeScreenState();
}

class _CustomThemeScreenState extends State<CustomThemeScreen> {
  late CustomTheme _editing;
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    final activeCustom = settings.activeCustomTheme;
    if (activeCustom != null) {
      _editing = activeCustom;
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

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final settings = context.read<SettingsProvider>();
    await settings.saveCustomTheme(_editing.copyWith(name: name));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Saved "$name"')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom Theme')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
            onTap: () => _pickColor('text', _editing.textColor,
                (c) => setState(() => _editing = _editing.copyWith(textColor: c))),
          ),
          _ColorRow(
            label: 'Chords',
            color: _editing.chordColor,
            onTap: () => _pickColor('chord', _editing.chordColor,
                (c) => setState(() => _editing = _editing.copyWith(chordColor: c))),
          ),
          _ColorRow(
            label: 'Section headers',
            color: _editing.sectionHeaderColor,
            onTap: () => _pickColor(
                'section header',
                _editing.sectionHeaderColor,
                (c) => setState(
                    () => _editing = _editing.copyWith(sectionHeaderColor: c))),
          ),
          _ColorRow(
            label: 'Comments / annotations',
            color: _editing.commentColor,
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

class _ColorRow extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ColorRow(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(colorToHex(color)),
      trailing: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
        ),
      ),
      onTap: onTap,
    );
  }
}
