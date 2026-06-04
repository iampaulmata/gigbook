// Parsed output model

class ChordLyricPair {
  final String? chord;
  final String lyric;
  const ChordLyricPair({this.chord, required this.lyric});
}

abstract class ParsedBlock {}

class SectionBlock extends ParsedBlock {
  final String label;
  SectionBlock(this.label);
}

class LyricBlock extends ParsedBlock {
  final List<ChordLyricPair> pairs;
  LyricBlock(this.pairs);
  bool get isEmpty => pairs.every((p) => p.lyric.trim().isEmpty && p.chord == null);
}

class CommentBlock extends ParsedBlock {
  final String text;
  CommentBlock(this.text);
}

class BlankBlock extends ParsedBlock {}

class ParsedSong {
  final String title;
  final String artist;
  final String? key;
  final int? capo;
  final List<ParsedBlock> blocks;

  const ParsedSong({
    required this.title,
    required this.artist,
    this.key,
    this.capo,
    required this.blocks,
  });
}

// ─── Parser ───────────────────────────────────────────────────────────────────

class ChordProParser {
  static final _directiveRe = RegExp(r'^\{([^:}]+)(?::([^}]*))?\}$');
  static final _chordRe = RegExp(r'\[([^\]]*)\]');

  // Known section keywords (lower-case)
  static const _sectionKeywords = {
    'verse', 'chorus', 'bridge', 'intro', 'outro',
    'pre-chorus', 'prechorus', 'hook', 'interlude',
    'instrumental', 'ending', 'tag', 'break', 'solo',
    'refrain', 'coda',
  };

  static ParsedSong parse(String content) {
    final lines = content.split('\n');
    String title = '';
    String artist = '';
    String? key;
    int? capo;
    final blocks = <ParsedBlock>[];

    bool inTabSection = false;

    for (var raw in lines) {
      final line = raw.trimRight();

      // ── Directive line ──────────────────────────────────────────────────
      final dm = _directiveRe.firstMatch(line.trim());
      if (dm != null) {
        final directive = dm.group(1)!.trim().toLowerCase();
        final value = dm.group(2)?.trim() ?? '';

        switch (directive) {
          case 't':
          case 'title':
            if (title.isEmpty) title = value;
          case 'st':
          case 'subtitle':
          case 'artist':
          case 'author':
            if (artist.isEmpty) artist = value;
          case 'key':
            key ??= value.isEmpty ? null : value;
          case 'capo':
            capo ??= int.tryParse(value);
          case 'c':
          case 'ci':
          case 'comment':
          case 'comment_italic':
          case 'comment_box':
            if (value.isNotEmpty) blocks.add(CommentBlock(value));
          case 'sov':
          case 'start_of_verse':
            blocks.add(SectionBlock(value.isNotEmpty ? value : 'Verse'));
          case 'soc':
          case 'start_of_chorus':
            blocks.add(SectionBlock(value.isNotEmpty ? value : 'Chorus'));
          case 'sob':
          case 'start_of_bridge':
            blocks.add(SectionBlock(value.isNotEmpty ? value : 'Bridge'));
          case 'verse':
            blocks.add(SectionBlock(value.isNotEmpty ? value : 'Verse'));
          case 'chorus':
            // {chorus} with no value = repeat chorus marker; with value = label
            if (value.isNotEmpty) blocks.add(SectionBlock(value));
          case 'sot':
          case 'start_of_tab':
            inTabSection = true;
          case 'eov':
          case 'end_of_verse':
          case 'eoc':
          case 'end_of_chorus':
          case 'eob':
          case 'end_of_bridge':
          case 'eot':
          case 'end_of_tab':
            inTabSection = false;
          // ignore all other directives (textfont, define, etc.)
        }
        continue;
      }

      // Skip tab sections
      if (inTabSection) continue;

      // ── Blank line ──────────────────────────────────────────────────────
      if (line.trim().isEmpty) {
        if (blocks.isNotEmpty && blocks.last is! BlankBlock) {
          blocks.add(BlankBlock());
        }
        continue;
      }

      // ── Section label in [bracket] notation (whole-line) ───────────────
      final bracketLabel = _extractBracketSectionLabel(line.trim());
      if (bracketLabel != null) {
        blocks.add(SectionBlock(bracketLabel));
        continue;
      }

      // ── Lyric / chord line ──────────────────────────────────────────────
      final pairs = _parseLyricLine(line);
      final block = LyricBlock(pairs);
      if (!block.isEmpty) {
        blocks.add(block);
      }
    }

    // Fall back: try to extract title from filename-style content (first non-blank line)
    if (title.isEmpty) {
      for (final block in blocks) {
        if (block is LyricBlock) {
          title = block.pairs.map((p) => p.lyric).join().trim();
          if (title.isNotEmpty) {
            blocks.remove(block);
            break;
          }
        }
      }
    }

    return ParsedSong(
      title: title,
      artist: artist,
      key: key,
      capo: capo,
      blocks: blocks,
    );
  }

  /// Returns a section label if the entire trimmed line is a bracketed section
  /// name (e.g. "[Verse 1]", "[Chorus]"), null otherwise.
  static String? _extractBracketSectionLabel(String line) {
    if (!line.startsWith('[') || !line.endsWith(']')) return null;
    // Must be a single bracket group covering the whole line
    if (line.indexOf('[', 1) != -1) return null;
    final inner = line.substring(1, line.length - 1).trim();
    if (inner.isEmpty) return null;
    final lower = inner.toLowerCase();
    // Check if it starts with a known section keyword
    for (final kw in _sectionKeywords) {
      if (lower == kw || lower.startsWith('$kw ') || lower.startsWith('$kw\t')) {
        return inner;
      }
    }
    // Also treat as section label if the content contains a space
    // (e.g. "[Verse 1]", "[Pre Chorus]") — real chords don't have spaces
    if (inner.contains(' ')) return inner;
    return null;
  }

  /// Parses a lyric line containing optional [Chord] markers into pairs.
  static List<ChordLyricPair> _parseLyricLine(String line) {
    final pairs = <ChordLyricPair>[];
    int pos = 0;
    String? pendingChord;

    for (final match in _chordRe.allMatches(line)) {
      // Lyric text before this chord
      final lyric = line.substring(pos, match.start);
      if (pendingChord != null || lyric.isNotEmpty) {
        pairs.add(ChordLyricPair(chord: pendingChord, lyric: lyric));
      }
      pendingChord = match.group(1)!.trim();
      pos = match.end;
    }

    // Remaining lyric after last chord
    final trailing = line.substring(pos);
    pairs.add(ChordLyricPair(chord: pendingChord, lyric: trailing));

    // If no chords at all, return a single pair with just the lyric
    if (pairs.isEmpty) {
      pairs.add(ChordLyricPair(lyric: line));
    }

    return pairs;
  }

  /// Quick metadata-only extraction — avoids a full parse when just the
  /// title/artist are needed (e.g. during import).
  static ({String title, String artist, String? key, int? capo}) extractMeta(
      String content) {
    String title = '';
    String artist = '';
    String? key;
    int? capo;

    for (final raw in content.split('\n')) {
      final line = raw.trim();
      final dm = _directiveRe.firstMatch(line);
      if (dm == null) continue;
      final directive = dm.group(1)!.trim().toLowerCase();
      final value = dm.group(2)?.trim() ?? '';
      switch (directive) {
        case 't':
        case 'title':
          if (title.isEmpty) title = value;
        case 'st':
        case 'subtitle':
        case 'artist':
        case 'author':
          if (artist.isEmpty) artist = value;
        case 'key':
          key ??= value.isEmpty ? null : value;
        case 'capo':
          capo ??= int.tryParse(value);
      }
      if (title.isNotEmpty && artist.isNotEmpty && key != null && capo != null) {
        break;
      }
    }

    return (title: title, artist: artist, key: key, capo: capo);
  }
}
