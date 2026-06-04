import 'package:flutter/material.dart';

import '../services/chordpro_parser.dart';

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
        if (parsed.key != null || parsed.capo != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                if (parsed.key != null)
                  _MetaChip(label: 'Key: ${parsed.key}'),
                if (parsed.key != null && parsed.capo != null)
                  const SizedBox(width: 8),
                if (parsed.capo != null)
                  _MetaChip(label: 'Capo ${parsed.capo}'),
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
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }

    if (block is CommentBlock) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          block.text,
          style: TextStyle(
            fontSize: fontSize * 0.9,
            fontStyle: FontStyle.italic,
            color: theme.colorScheme.onSurfaceVariant,
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

  Widget _buildLyricLine(BuildContext context, LyricBlock block) {
    if (!showChords) {
      final text = block.pairs.map((p) => p.lyric).join();
      if (text.trim().isEmpty) return SizedBox(height: fontSize * 0.6);
      return Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(text, style: TextStyle(fontSize: fontSize, height: 1.5)),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.start,
        children: block.pairs
            .map((pair) => _ChordLyricChunk(
                  pair: pair,
                  fontSize: fontSize,
                ))
            .toList(),
      ),
    );
  }
}

class _ChordLyricChunk extends StatelessWidget {
  final ChordLyricPair pair;
  final double fontSize;

  const _ChordLyricChunk({required this.pair, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chordSize = fontSize * 0.72;
    final chordStyle = TextStyle(
      fontSize: chordSize,
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.primary,
      height: 1.2,
      fontFamily: 'monospace',
    );
    final lyricStyle = TextStyle(fontSize: fontSize, height: 1.5);
    // Non-breaking space so empty lyric slots still take width
    final lyricText = pair.lyric.isEmpty ? ' ' : pair.lyric;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (pair.chord != null)
          Text(pair.chord!, style: chordStyle)
        else
          // Invisible placeholder to keep vertical alignment with chords on the same line
          SizedBox(height: chordSize * 1.2),
        Text(lyricText, style: lyricStyle),
      ],
    );
  }
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
