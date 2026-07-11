import 'package:flutter/material.dart';

import '../services/chordpro_parser.dart';
import '../theme/app_theme.dart';

class ChordProRenderer extends StatelessWidget {
  final String content;
  final bool showChords;
  final double fontSize;

  const ChordProRenderer({
    super.key,
    required this.content,
    required this.showChords,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final parsed = ChordProParser.parse(content);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Song header
        if (parsed.title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              parsed.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        if (parsed.subtitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              parsed.subtitle,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        if (parsed.artist.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              parsed.artist,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        if (parsed.key != null ||
            parsed.capo != null ||
            parsed.timeSignature != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (parsed.key != null) _MetaChip(label: 'Key: ${parsed.key}'),
                if (parsed.capo != null) _MetaChip(label: 'Capo ${parsed.capo}'),
                if (parsed.timeSignature != null)
                  _MetaChip(label: 'Time: ${parsed.timeSignature}'),
              ],
            ),
          )
        else
          const SizedBox(height: 16),

        // Song body
        ...parsed.blocks.map((block) => _buildBlock(context, block)),
      ],
    );
  }

  Widget _buildBlock(BuildContext context, ParsedBlock block) {
    final theme = Theme.of(context);

    if (block is SectionBlock) {
      return Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 6),
        child: Text(
          block.label.toUpperCase(),
          style: TextStyle(
            fontSize: fontSize * 0.72,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            color: _chordProColors(theme).sectionHeader,
          ),
        ),
      );
    }

    if (block is AnnotationBlock) {
      return _buildAnnotation(context, block);
    }

    if (block is TabBlock) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          block.lines.join('\n'),
          style: TextStyle(
            fontSize: fontSize * 0.85,
            fontFamily: 'monospace',
            height: 1.3,
          ),
        ),
      );
    }

    if (block is BlankBlock) {
      return SizedBox(height: fontSize * 0.6);
    }

    if (block is LyricBlock) {
      return _buildLyricLine(context, block);
    }

    return const SizedBox.shrink();
  }

  /// Renders one of the four annotation-line styles: grey-bar, italic,
  /// boxed, or general highlight — kept visually distinct from each other
  /// and from ordinary lyric lines.
  Widget _buildAnnotation(BuildContext context, AnnotationBlock block) {
    final theme = Theme.of(context);
    final baseStyle = TextStyle(
      fontSize: fontSize * 0.9,
      color: _chordProColors(theme).comment,
    );

    switch (block.style) {
      case AnnotationStyle.greyBar:
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Text(block.text, style: baseStyle),
        );
      case AnnotationStyle.italic:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            block.text,
            style: baseStyle.copyWith(fontStyle: FontStyle.italic),
          ),
        );
      case AnnotationStyle.boxed:
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(block.text, style: baseStyle),
        );
      case AnnotationStyle.highlight:
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            block.text,
            style: baseStyle.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
        );
    }
  }

  Widget _buildLyricLine(BuildContext context, LyricBlock block) {
    if (!showChords) {
      final joinedText = block.pairs.map((p) => p.lyricText).join();
      if (joinedText.trim().isEmpty) return SizedBox(height: fontSize * 0.6);
      final spans = block.pairs
          .expand((p) => p.lyric)
          .map((run) => TextSpan(
                text: run.text,
                style: TextStyle(
                  fontSize: fontSize,
                  height: 1.5,
                  color: run.textColor ?? block.textColor,
                  backgroundColor: run.backgroundColor,
                ),
              ))
          .toList();
      return _withLineBackground(
        block.backgroundColor,
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text.rich(TextSpan(children: spans)),
        ),
      );
    }

    return _withLineBackground(
      block.backgroundColor,
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.start,
          children: block.pairs
              .map((pair) => _ChordLyricChunk(
                    pair: pair,
                    fontSize: fontSize,
                    textColor: block.textColor,
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _withLineBackground(Color? color, Widget child) {
    if (color == null) return child;
    return Container(
      width: double.infinity,
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      margin: const EdgeInsets.symmetric(vertical: 1),
      child: child,
    );
  }
}

class _ChordLyricChunk extends StatelessWidget {
  final ChordLyricPair pair;
  final double fontSize;
  final Color? textColor;

  const _ChordLyricChunk({
    required this.pair,
    required this.fontSize,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chordSize = fontSize * 0.72;
    final chordStyle = TextStyle(
      fontSize: chordSize,
      fontWeight: FontWeight.bold,
      color: _chordProColors(theme).chord,
      height: 1.2,
      fontFamily: 'monospace',
    );
    // Non-breaking space so empty lyric slots still take width
    final displayRuns =
        pair.lyricText.isEmpty ? const [LyricRun(' ')] : pair.lyric;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (pair.chord != null)
          Text(pair.chord!, style: chordStyle)
        else
          // Invisible placeholder to keep vertical alignment with chords on the same line
          SizedBox(height: chordSize * 1.2),
        Text.rich(
          TextSpan(
            children: displayRuns
                .map((run) => TextSpan(
                      text: run.text,
                      style: TextStyle(
                        fontSize: fontSize,
                        height: 1.5,
                        color: run.textColor ?? textColor,
                        backgroundColor: run.backgroundColor,
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

/// Falls back to standard ColorScheme roles if a [ThemeData] somehow lacks
/// the [ChordProColors] extension (e.g. a bare ThemeData in a test).
ChordProColors _chordProColors(ThemeData theme) {
  return theme.extension<ChordProColors>() ??
      ChordProColors(
        chord: theme.colorScheme.primary,
        sectionHeader: theme.colorScheme.primary,
        comment: theme.colorScheme.onSurfaceVariant,
      );
}

class _MetaChip extends StatelessWidget {
  final String label;
  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
