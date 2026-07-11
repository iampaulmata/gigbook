import 'package:flutter/material.dart';

import '../models/custom_theme.dart';
import '../theme/app_theme.dart';
import 'chordpro_renderer.dart';

const _sampleSongContent = '''
{title: Sample Song}
{soc: Chorus}
[G]Amazing grace, how [C]sweet the [G]sound
{eoc}
{comment: A comment or annotation line}
''';

/// Live preview of what a [CustomTheme] looks like against real song
/// content — reuses [ChordProRenderer] under a [Theme] override built from
/// the theme being edited, so the preview is pixel-identical to what
/// applying the theme actually produces (FR-003).
class ThemePreview extends StatelessWidget {
  final CustomTheme theme;

  const ThemePreview({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.custom(theme),
      child: Builder(
        builder: (context) => Container(
          width: double.infinity,
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.all(16),
          child: const ChordProRenderer(
            content: _sampleSongContent,
            showChords: true,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
