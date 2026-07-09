# Data Model: Full ChordPro Tag Support

All types below live in `lib/services/chordpro_parser.dart` unless noted. Nothing in this feature
is persisted to `sqflite` — see [research.md](./research.md) decision 1.

## ParsedSong

In-memory result of parsing one song's ChordPro content; rebuilt on every render, never stored.

| Field | Type | Change | Notes |
|---|---|---|---|
| `title` | `String` | unchanged | from `{title:}`/`{t:}` |
| `subtitle` | `String` | **new** | from `{subtitle:}`/`{st:}` — no longer folds into `artist` (FR-002) |
| `artist` | `String` | unchanged | from `{artist:}` only (see below) |
| `key` | `String?` | unchanged | from `{key:}` |
| `capo` | `int?` | unchanged | from `{capo:}` |
| `tempo` | `int?` | unchanged | from `{tempo:}` |
| `timeSignature` | `String?` | **new** | from `{time:}` (FR-007) |
| `blocks` | `List<ParsedBlock>` | unchanged type | new subtypes below |

First-declared value wins for every metadata field if a directive repeats (unchanged behavior,
now also applies to `subtitle`/`timeSignature`). See "Metadata resolution state" below for how
`%{...}` differs.

## ParsedBlock subtypes

| Type | Status | Purpose |
|---|---|---|
| `SectionBlock(label)` | unchanged | Verse/Chorus/Bridge section header |
| `TabBlock(lines: List<String>)` | **new** | Raw literal text from `{sot}`...`{eot}`; never passed through chord-bracket or inline-tag parsing (FR-011) |
| `AnnotationBlock(text, style)` | **replaces `CommentBlock`** | One performance-note line; `style` is `AnnotationStyle.greyBar \| italic \| boxed \| highlight`, mapped from `{c}/{comment}`, `{ci}/{comment_italic}`, `{cb}/{comment_box}`, `{highlight}` respectively (FR-012–015). `text` has `%{...}` already resolved. |
| `LyricBlock(pairs, textColor?, backgroundColor?)` | pairs' shape changes | `textColor`/`backgroundColor` remain the standing (whole-line) style from `{textcolour:}`/`{background:}` family; unaffected by this feature except that `textColor` no longer reaches chord symbols (FR-016) |
| `BlankBlock` | unchanged | blank-line spacer |

## ChordLyricPair / LyricRun

| Type | Field | Type | Change |
|---|---|---|---|
| `ChordLyricPair` | `chord` | `String?` | unchanged |
| `ChordLyricPair` | `lyric` | `List<LyricRun>` | **changed** from `String` — one unstyled run is the common case |
| `LyricRun` (**new**) | `text` | `String` | plain text segment |
| `LyricRun` | `textColor` | `Color?` | from an enclosing inline `{tc:VALUE}...{tc}` |
| `LyricRun` | `backgroundColor` | `Color?` | from an enclosing inline `{tb:VALUE}...{tb}` |

Inline run styling (from `{tc}`/`{tb}`) takes precedence over the enclosing `LyricBlock`'s standing
`textColor`/`backgroundColor` for the runs it covers (FR-018–020). A chord/lyric chunk with no
inline tags is represented as a single `LyricRun` with both colors `null`.

## AnnotationStyle (new enum)

```
enum AnnotationStyle { greyBar, italic, boxed, highlight }
```

| Value | Source directives | Visual treatment (renderer) |
|---|---|---|
| `greyBar` | `{comment:}` / `{c:}` | grey bar / muted background strip |
| `italic` | `{comment_italic:}` / `{ci:}` | italic text, no bar |
| `boxed` | `{comment_box:}` / `{cb:}` | bordered box |
| `highlight` | `{highlight:}` | 4th distinct treatment (e.g. accent-colored background, no border) |

## Metadata resolution state (parsing-time only, not a stored type)

While scanning lines top to bottom, the parser threads a mutable snapshot of
title/subtitle/artist/key/capo/tempo/timeSignature, updated whenever the corresponding directive
is (re)declared. Two different things read this snapshot:

- **`ParsedSong`'s stored fields** — set once, from the *first* declaration only (existing
  first-write-wins behavior, e.g. today's `title ??= value` pattern).
- **`%{...}` substitution** (FR-021) — reads whichever value is *current* at the line being
  processed, so a reference after a mid-file `{key: D}` redeclaration resolves to "D" even though
  `ParsedSong.key` itself still reports the first-declared key.

Substitution runs over a line's raw text before chord-bracket (`[Chord]`) and inline-tag
(`{tb}`/`{tc}`) parsing, and applies identically whether the line becomes a `LyricBlock` or an
`AnnotationBlock` (FR-021).

## Song / `songs` table (lib/models/song.dart, lib/db/database.dart)

**No changes.** `subtitle` and `timeSignature` are intentionally render-only (research.md decision
1); `title`/`artist`/`key`/`capo`/`tempo` columns and their `Song.toMap`/`fromMap` logic are
untouched. The only related change is in `import_service.dart`'s use of
`ChordProParser.extractMeta`, whose `artist` capture must stop reading `st`/`subtitle` (research.md
decision 2) — `extractMeta`'s return shape (`title`, `artist`, `key`, `capo`, `tempo`) is otherwise
unchanged.

## Validation rules (from spec Edge Cases)

- Unrecognized/invalid color value (named or hex) → no color applied; import does not fail.
- Inline span (`{tb}`/`{tc}`) opened but not closed on the same line → styles the remainder of
  that line only; does not carry to subsequent lines.
- Standing directive (`{textcolour}`, section start) never reset/closed → effect continues to end
  of file.
- `%{name}` with no declaration anywhere in the file → resolves to empty string, never the literal
  `%{name}` text.
- All directive/tag names matched case-insensitively.
