# Research: Full ChordPro Tag Support

All items below were resolved during specification/clarification; this document records the
resulting technical decisions and the alternatives rejected. No open `NEEDS CLARIFICATION` markers
remain in `plan.md`'s Technical Context.

## 1. Where subtitle & time signature live

**Decision**: Add `subtitle` and `timeSignature` to `ParsedSong` (the parser's in-memory output)
only. Do **not** add `subtitle`/`time_signature` columns to the `songs` table or `Song` model.

**Rationale**: `ChordProRenderer` already re-parses the full song content to build its header
(title/artist/key/capo chips) independently of the DB row, so a render-only field is sufficient to
satisfy SC-002 ("visible from the library list **and/or** song header"). Persisting would require
a `songs` schema migration (currently at version 5) and touches to `import_service.dart`,
`drive_sync_service.dart`, `song_matcher.dart`, and every `Song.toMap`/`fromMap` call site for two
fields with no library-list search/sort use case today.

**Alternatives considered**: Add DB columns + migration to schema v6 — rejected as unnecessary
schema churn for display-only data (Constitution V, Simplicity & YAGNI).

## 2. Fixing the subtitle/artist conflation in `extractMeta`

**Decision**: `ChordProParser.extractMeta` (used by `import_service.dart` to populate the DB
`artist` column at import time) must stop treating `st`/`subtitle` as an artist source — only
`artist`/`author` should populate it.

**Rationale**: Today `extractMeta`'s switch folds `st`/`subtitle`/`artist`/`author` into one
`artist` variable. Left as-is, a file with `{subtitle: Hymn}` and no `{artist:}` would show "Hymn"
as the library artist — directly contradicting FR-002's requirement that subtitle be distinct from
artist. This is a small, targeted fix alongside the main parser change, not a separate feature.

**Alternatives considered**: Leave `extractMeta` unchanged — rejected, produces incorrect library
metadata.

## 3. Annotation-line model (4 comment styles)

**Decision**: Replace the single `CommentBlock` with `AnnotationBlock(text, style)`, where
`style` is a 4-value enum: `greyBar`, `italic`, `boxed`, `highlight`.

**Rationale**: Today `{c:}`, `{ci:}`, and `{cb:}` all produce an identical `CommentBlock` — FR-012
through FR-015 require each of the four to be visually distinct. An enum-on-one-class keeps the
parser switch and renderer switch both flat and simple.

**Alternatives considered**: Four separate block subclasses — rejected as more ceremony for no
behavioral gain (Constitution V).

## 4. Tab section handling

**Decision**: Add `TabBlock(List<String> lines)`. Content between `{sot}`/`{eot}` is captured
verbatim, line by line, and rendered as raw monospace text — `[Chord]` markers inside a tab block
are **not** extracted as chords.

**Rationale**: Per clarification, tab content is typically ASCII fret/tab notation where bracket
characters are part of the notation itself, not chord markup; extracting them would corrupt the
display. Today's parser silently discards tab content entirely, which conflicts with Constitution
II's no-data-loss import guarantee — this decision fixes that gap.

**Alternatives considered**: Route tab lines through the normal chord/lyric line parser — explicitly
rejected during clarification.

## 5. Inline color/background spans

**Decision**: Introduce `LyricRun { String text; Color? textColor; Color? backgroundColor }`.
`ChordLyricPair.lyric` changes from `String` to `List<LyricRun>` (a single unstyled run is the
common case). `{tb:VALUE}...{tb}` and `{tc:VALUE}...{tc}` (including combined use) are parsed into
one or more styled runs within the surrounding chord/lyric chunk. Inline run styling takes
precedence over the line's standing `textColor`/`backgroundColor` for the runs it covers.

**Rationale**: The clarification session settled on true inline (substring-level) fidelity for
`{tb}`/`{tc}` spans (FR-018–020), which a single per-line `Color` cannot represent. `LyricRun` is
the minimal structure that supports it; rendering uses `Text.rich`/`TextSpan`, whose
`TextStyle.backgroundColor` already covers inline highlight without any extra dependency.

**Alternatives considered**: Whole-line approximation — explicitly rejected by clarification. A
general inline-markup AST supporting arbitrary nested tags — rejected as more than this feature
needs (only two inline tag types exist today) per Constitution V.

## 6. `{highlight:...}` redefinition

**Decision**: `{highlight:...}` becomes a 4th `AnnotationBlock` style (a single annotated line),
replacing its current behavior as a standing background-color setter. The `background`/`bgcolor`/
`bgcolour` aliases continue to set the standing background color as before; `highlight` is removed
from that alias group.

**Rationale**: The feature request describes `{highlight}` as a "general highlight **line**" —
i.e., one annotated line, matching the grey-bar/italic/boxed family — not a session-scoped color
state. This was confirmed as an explicit assumption during specification.

**Alternatives considered**: Keep `highlight` as a background-state alias and invent a different
keyword for the annotation style — rejected; the feature request explicitly names `{highlight:}`
for the annotation-line behavior, and no other directive name was requested for it.

## 7. Live metadata substitution (`%{...}`)

**Decision**: Resolve `%{key}`, `%{capo}`, etc. as a text-substitution pass over each raw line's
text, applied *before* chord-bracket and inline-tag parsing, using the same mutable
title/subtitle/artist/key/capo/tempo/timeSignature state the parser already threads line-by-line
through the file. Applied identically inside lyric lines and annotation lines. A reference to
metadata that is never declared anywhere in the file resolves to an empty string.

**Rationale**: This directly implements FR-021/FR-022 using state the parser already maintains —
no second pass over the file or duplicate state machine is needed. Running substitution first
means `%{...}` text can never be mistaken for a chord bracket or inline tag.

**Alternatives considered**: A separate post-processing pass over fully-built blocks — rejected,
would require re-deriving the same per-line metadata snapshot a second time for no benefit.

## 8. Standing text size/font

**Decision**: `{textsize:...}`/`{textsize}` and `{textfont:...}`/`{textfont}` are parsed and
accepted (no error) but have **no rendering effect**; the app's own font-size/theme settings remain
authoritative.

**Rationale**: Confirmed during specification — user-controlled text size is core to stage
readability (Constitution III), and a chart authored with a tiny `textsize` should never make
itself unreadable on stage.

**Alternatives considered**: Absolute override or relative scaling — both explicitly rejected
during clarification.

## 9. Custom directives (`{x_*:...}`)

**Decision**: No new code path needed — `{x_*:...}` directives already fall through the parser's
default (no-op) switch branch and are silently ignored. Confirmed as correct-by-construction rather
than requiring new logic.

**Rationale**: Constitution II requires custom/non-standard directives to be isolated from
standard-directive handling; the existing no-op default already satisfies this, so the only work
item is a regression test proving it (FR-023).

## Testing approach

Per Constitution IV (Test-First for Core Logic, NON-NEGOTIABLE), all `ChordProParser` behavior
changes are covered by `test/services/chordpro_parser_test.dart`, written and failing before the
implementation change that makes it pass. Test cases map to FR-001 through FR-025 and to the
spec's Edge Cases list. `ChordProRenderer` visual changes (annotation styles, tab-block styling,
inline-span rendering, header additions) are verified manually on-device via the project's
`run`/`verify` skills, consistent with the constitution's allowance for widget-level code.
