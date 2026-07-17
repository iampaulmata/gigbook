import 'dart:ui' show Color;

// Parsed output model

/// A single run of lyric text carrying optional inline styling from a
/// `{tc:VALUE}...{tc}` (text color) and/or `{tb:VALUE}...{tb}` (background)
/// span. A chord/lyric chunk with no inline tags is a single unstyled run.
class LyricRun {
  final String text;
  final Color? textColor;
  final Color? backgroundColor;
  const LyricRun(this.text, {this.textColor, this.backgroundColor});
}

class ChordLyricPair {
  final String? chord;
  final List<LyricRun> lyric;
  const ChordLyricPair({this.chord, required this.lyric});

  /// Concatenated plain text of all runs, ignoring inline styling.
  String get lyricText => lyric.map((r) => r.text).join();
}

abstract class ParsedBlock {}

class SectionBlock extends ParsedBlock {
  final String label;
  SectionBlock(this.label);
}

class LyricBlock extends ParsedBlock {
  final List<ChordLyricPair> pairs;
  final Color? textColor;
  final Color? backgroundColor;
  LyricBlock(this.pairs, {this.textColor, this.backgroundColor});
  bool get isEmpty =>
      pairs.every((p) => p.lyricText.trim().isEmpty && p.chord == null);
}

enum AnnotationStyle { greyBar, italic, boxed, highlight }

/// A single line of performance-note text (e.g. "quiet intro"), kept
/// structurally separate from lyric/chord content. [style] selects one of
/// four visually distinct treatments.
class AnnotationBlock extends ParsedBlock {
  final String text;
  final AnnotationStyle style;
  AnnotationBlock(this.text, this.style);
}

/// Raw literal text captured between `{sot}`/`{eot}`. Lines are preserved
/// verbatim — no `[Chord]` extraction is performed on tab content.
class TabBlock extends ParsedBlock {
  final List<String> lines;
  TabBlock(this.lines);
}

class BlankBlock extends ParsedBlock {}

class ParsedSong {
  final String title;
  final String subtitle;
  final String artist;
  final String? key;
  final int? capo;
  final int? tempo;
  final String? timeSignature;
  final String? tuning;
  final String? preset;
  final List<ParsedBlock> blocks;

  const ParsedSong({
    required this.title,
    this.subtitle = '',
    required this.artist,
    this.key,
    this.capo,
    this.tempo,
    this.timeSignature,
    this.tuning,
    this.preset,
    required this.blocks,
  });
}

/// An intermediate slice of raw line text carrying whichever inline `{tb}`/
/// `{tc}` style was active when it was captured. Used only within
/// [ChordProParser._parseLyricLine] to resolve inline spans.
class _StylePiece {
  final String text;
  final Color? textColor;
  final Color? backgroundColor;
  const _StylePiece(this.text, {this.textColor, this.backgroundColor});
}

// ─── Parser ───────────────────────────────────────────────────────────────────

class ChordProParser {
  // The value group is greedy (`.*`, not `[^}]*`) so a directive value that
  // itself contains a literal `}` — e.g. a `%{key}` live-metadata reference
  // inside a `{c: ...}` comment — still matches through to the final closing
  // brace instead of stopping at the first one.
  static final _directiveRe = RegExp(r'^\{([^:}]+)(?::(.*))?\}$');
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
    // First-declared value wins for these — what the song's stored metadata
    // (library list, header) reports.
    String title = '';
    String subtitle = '';
    String artist = '';
    String? key;
    int? capo;
    int? tempo;
    String? timeSignature;
    // tuning/preset are display-only (spec 005 research.md §5) — no `live*`
    // counterpart, unlike the fields above; they're never resolved via
    // `%{...}` live metadata references.
    String? tuning;
    String? preset;
    final blocks = <ParsedBlock>[];

    // Most-recently-declared value — what `%{...}` references resolve
    // against (FR-021), which may differ from the first-write-wins fields
    // above once a directive is redeclared mid-file.
    String liveTitle = '';
    String liveSubtitle = '';
    String liveArtist = '';
    String? liveKey;
    int? liveCapo;
    int? liveTempo;
    String? liveTimeSignature;

    bool inTabSection = false;
    List<String>? currentTabLines;
    Color? currentTextColor;
    Color? currentBackgroundColor;

    // Resolves `%{...}` references against whichever metadata value was
    // most recently declared at the point this is called — captures the
    // mutable `live*` locals above by reference, so it always reflects the
    // current parsing position rather than the song's first-declared values.
    String substituteLiveMetadata(String text) => _substituteLiveMetadata(
          text,
          title: liveTitle,
          subtitle: liveSubtitle,
          artist: liveArtist,
          key: liveKey,
          capo: liveCapo,
          tempo: liveTempo,
          timeSignature: liveTimeSignature,
        );

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
            liveTitle = value;
          case 'st':
          case 'subtitle':
            if (subtitle.isEmpty) subtitle = value;
            liveSubtitle = value;
          case 'artist':
          case 'author':
            if (artist.isEmpty) artist = value;
            liveArtist = value;
          case 'key':
            key ??= value.isEmpty ? null : value;
            liveKey = value.isEmpty ? null : value;
          case 'capo':
            capo ??= int.tryParse(value);
            liveCapo = int.tryParse(value);
          case 'tempo':
          case 'bpm':
            tempo ??= int.tryParse(value);
            liveTempo = int.tryParse(value);
          case 'time':
            timeSignature ??= value.isEmpty ? null : value;
            liveTimeSignature = value.isEmpty ? null : value;
          // GigBook-added metadata directive (spec 005), not part of core
          // ChordPro — same first-class treatment as capo/tempo/time above.
          case 'tuning':
          case 'tu':
            tuning ??= value.isEmpty ? null : value;
          case 'preset':
          case 'p':
            preset ??= value.isEmpty ? null : value;
          case 'color':
          case 'colour':
          case 'textcolor':
          case 'textcolour':
            currentTextColor = _parseColor(value);
          case 'background':
          case 'bgcolor':
          case 'bgcolour':
            currentBackgroundColor = _parseColor(value);
          case 'c':
          case 'comment':
            if (value.isNotEmpty) {
              blocks.add(AnnotationBlock(
                  substituteLiveMetadata(value), AnnotationStyle.greyBar));
            }
          case 'ci':
          case 'comment_italic':
            if (value.isNotEmpty) {
              blocks.add(AnnotationBlock(
                  substituteLiveMetadata(value), AnnotationStyle.italic));
            }
          case 'cb':
          case 'comment_box':
            if (value.isNotEmpty) {
              blocks.add(AnnotationBlock(
                  substituteLiveMetadata(value), AnnotationStyle.boxed));
            }
          case 'highlight':
            if (value.isNotEmpty) {
              blocks.add(AnnotationBlock(
                  substituteLiveMetadata(value), AnnotationStyle.highlight));
            }
          case 'sov':
          case 'start_of_verse':
            blocks.add(SectionBlock(value.isNotEmpty ? value : 'Verse'));
          case 'soc':
          case 'start_of_chorus':
            blocks.add(SectionBlock(value.isNotEmpty ? value : 'Chorus'));
          case 'sob':
          case 'start_of_bridge':
            blocks.add(SectionBlock(value.isNotEmpty ? value : 'Bridge'));
          case 'soo':
          case 'start_of_outro':
            blocks.add(SectionBlock(value.isNotEmpty ? value : 'Outro'));
          case 'verse':
            blocks.add(SectionBlock(value.isNotEmpty ? value : 'Verse'));
          case 'chorus':
            // {chorus} with no value = repeat chorus marker; with value = label
            if (value.isNotEmpty) blocks.add(SectionBlock(value));
          case 'sot':
          case 'start_of_tab':
            inTabSection = true;
            currentTabLines = [];
          case 'eov':
          case 'end_of_verse':
          case 'eoc':
          case 'end_of_chorus':
          case 'eob':
          case 'end_of_bridge':
          case 'eoo':
          case 'end_of_outro':
            inTabSection = false;
          case 'eot':
          case 'end_of_tab':
            inTabSection = false;
            if (currentTabLines != null) {
              blocks.add(TabBlock(currentTabLines));
              currentTabLines = null;
            }
          // `textsize`/`textfont` are intentionally left unhandled here: per
          // spec clarification, standing font-size/font-family directives
          // must never override the app's own display settings, so they —
          // like `define` and other unrecognized directives — are no-ops.
        }
        continue;
      }

      // Raw literal capture inside a tab section — no chord/bracket parsing.
      if (inTabSection) {
        currentTabLines?.add(line);
        continue;
      }

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
      final pairs = _parseLyricLine(substituteLiveMetadata(line));
      final block = LyricBlock(
        pairs,
        textColor: currentTextColor,
        backgroundColor: currentBackgroundColor,
      );
      if (!block.isEmpty) {
        blocks.add(block);
      }
    }

    // An unclosed {sot} runs through end of file — flush what was captured.
    if (currentTabLines != null) {
      blocks.add(TabBlock(currentTabLines));
    }

    // Fall back: try to extract title from filename-style content (first non-blank line)
    if (title.isEmpty) {
      for (final block in blocks) {
        if (block is LyricBlock) {
          title = block.pairs.map((p) => p.lyricText).join().trim();
          if (title.isNotEmpty) {
            blocks.remove(block);
            break;
          }
        }
      }
    }

    return ParsedSong(
      title: title,
      subtitle: subtitle,
      artist: artist,
      key: key,
      capo: capo,
      tempo: tempo,
      timeSignature: timeSignature,
      tuning: tuning,
      preset: preset,
      blocks: blocks,
    );
  }

  static final _liveMetadataRe = RegExp(r'%\{([a-zA-Z]+)\}');

  /// Replaces `%{name}` references with the given metadata snapshot, taken
  /// at whichever point in the file the caller is currently at. A reference
  /// to metadata with no value resolves to an empty string.
  static String _substituteLiveMetadata(
    String text, {
    required String title,
    required String subtitle,
    required String artist,
    required String? key,
    required int? capo,
    required int? tempo,
    required String? timeSignature,
  }) {
    if (!text.contains('%{')) return text;
    return text.replaceAllMapped(_liveMetadataRe, (m) {
      switch (m.group(1)!.toLowerCase()) {
        case 'title':
          return title;
        case 'subtitle':
          return subtitle;
        case 'artist':
          return artist;
        case 'key':
          return key ?? '';
        case 'capo':
          return capo?.toString() ?? '';
        case 'tempo':
          return tempo?.toString() ?? '';
        case 'time':
          return timeSignature ?? '';
        default:
          return '';
      }
    });
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

  /// Parses a lyric line containing optional [Chord] markers into pairs,
  /// resolving any inline `{tb:VALUE}...{tb}` / `{tc:VALUE}...{tc}` spans
  /// (including combined use) into per-run styling along the way.
  static List<ChordLyricPair> _parseLyricLine(String line) {
    final pieces = _splitInlineStyles(line);
    final cleanLine = pieces.map((p) => p.text).join();

    final pairs = <ChordLyricPair>[];
    int pos = 0;
    String? pendingChord;

    for (final match in _chordRe.allMatches(cleanLine)) {
      if (pendingChord != null || match.start > pos) {
        pairs.add(ChordLyricPair(
          chord: pendingChord,
          lyric: _runsForRange(pieces, pos, match.start),
        ));
      }
      pendingChord = match.group(1)!.trim();
      pos = match.end;
    }

    // Remaining lyric after last chord
    pairs.add(ChordLyricPair(
      chord: pendingChord,
      lyric: _runsForRange(pieces, pos, cleanLine.length),
    ));

    // If no chords at all, return a single pair with just the lyric
    if (pairs.isEmpty) {
      pairs.add(ChordLyricPair(lyric: _runsForRange(pieces, 0, cleanLine.length)));
    }

    return pairs;
  }

  static final _inlineTagRe = RegExp(r'\{(tb|tc)(?::([^}]*))?\}');

  /// Splits a raw line into text pieces carrying whichever inline `{tb}`/
  /// `{tc}` style is active at that point, with the tag markers themselves
  /// removed. `[Chord]` brackets are left untouched as ordinary text — chord
  /// extraction runs afterward, over the concatenated (tag-free) text.
  static List<_StylePiece> _splitInlineStyles(String line) {
    final pieces = <_StylePiece>[];
    Color? tbColor;
    Color? tcColor;
    int pos = 0;

    for (final match in _inlineTagRe.allMatches(line)) {
      final segment = line.substring(pos, match.start);
      if (segment.isNotEmpty) {
        pieces.add(_StylePiece(segment, textColor: tcColor, backgroundColor: tbColor));
      }
      final value = match.group(2);
      if (match.group(1) == 'tb') {
        tbColor = value != null ? _parseColor(value) : null;
      } else {
        tcColor = value != null ? _parseColor(value) : null;
      }
      pos = match.end;
    }

    final trailing = line.substring(pos);
    if (trailing.isNotEmpty || pieces.isEmpty) {
      pieces.add(_StylePiece(trailing, textColor: tcColor, backgroundColor: tbColor));
    }
    return pieces;
  }

  /// Slices the styled pieces (as produced by [_splitInlineStyles]) into the
  /// `LyricRun`s covering [start, end) of their concatenated (clean) text.
  static List<LyricRun> _runsForRange(
      List<_StylePiece> pieces, int start, int end) {
    final runs = <LyricRun>[];
    int pos = 0;
    for (final piece in pieces) {
      final pieceStart = pos;
      final pieceEnd = pos + piece.text.length;
      pos = pieceEnd;
      final overlapStart = start > pieceStart ? start : pieceStart;
      final overlapEnd = end < pieceEnd ? end : pieceEnd;
      if (overlapStart < overlapEnd) {
        runs.add(LyricRun(
          piece.text.substring(overlapStart - pieceStart, overlapEnd - pieceStart),
          textColor: piece.textColor,
          backgroundColor: piece.backgroundColor,
        ));
      }
    }
    if (runs.isEmpty) {
      runs.add(const LyricRun(''));
    }
    return runs;
  }

  /// Quick metadata-only extraction — avoids a full parse when just the
  /// title/artist are needed (e.g. during import).
  static ({String title, String artist, String? key, int? capo, int? tempo})
      extractMeta(String content) {
    String title = '';
    String artist = '';
    String? key;
    int? capo;
    int? tempo;

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
        case 'artist':
        case 'author':
          if (artist.isEmpty) artist = value;
        case 'key':
          key ??= value.isEmpty ? null : value;
        case 'capo':
          capo ??= int.tryParse(value);
        case 'tempo':
        case 'bpm':
          tempo ??= int.tryParse(value);
      }
      if (title.isNotEmpty &&
          artist.isNotEmpty &&
          key != null &&
          capo != null &&
          tempo != null) {
        break;
      }
    }

    return (title: title, artist: artist, key: key, capo: capo, tempo: tempo);
  }

  // ─── Color tags ─────────────────────────────────────────────────────────
  //
  // Custom (non-standard) directives for tinting lines — handy for marking
  // up who sings what:
  //   {color: blue}       following lines use blue text until changed
  //   {highlight: yellow} following lines get a yellow background
  //   {color}             (empty value) resets text color to default
  //   {highlight}         (empty value) resets background to default
  // Accepts common color names or hex codes (#RGB, #RRGGBB, #AARRGGBB).

  static const Map<String, int> _namedColors = {
    'red': 0xFFE53935,
    'orange': 0xFFFB8C00,
    'yellow': 0xFFFDD835,
    'green': 0xFF43A047,
    'teal': 0xFF00897B,
    'blue': 0xFF1E88E5,
    'purple': 0xFF8E24AA,
    'pink': 0xFFD81B60,
    'cyan': 0xFF00ACC1,
    'brown': 0xFF6D4C41,
    'gray': 0xFF757575,
    'grey': 0xFF757575,
    'black': 0xFF000000,
    'white': 0xFFFFFFFF,
  };

  static Color? _parseColor(String raw) {
    final value = raw.trim().toLowerCase();
    if (value.isEmpty || value == 'none' || value == 'default') return null;

    if (value.startsWith('#')) {
      var hex = value.substring(1);
      if (hex.length == 3) {
        hex = hex.split('').map((c) => '$c$c').join();
      }
      if (hex.length == 6) hex = 'ff$hex';
      if (hex.length != 8) return null;
      final n = int.tryParse(hex, radix: 16);
      return n != null ? Color(n) : null;
    }

    final named = _namedColors[value];
    return named != null ? Color(named) : null;
  }
}
