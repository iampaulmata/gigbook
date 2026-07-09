# Contract: ChordPro Directive Grammar

This is the grammar `ChordProParser` promises to honor for this feature — the reference the parser
test suite (`test/services/chordpro_parser_test.dart`) is written against. All directive and tag
names are matched case-insensitively (FR-024). Any directive not listed here falls through to a
silent no-op (Constitution II).

## Metadata directives (whole-song, first declaration wins for stored value)

| Directive | Aliases | Sets | FR |
|---|---|---|---|
| `{title:VALUE}` | `{t:VALUE}` | `ParsedSong.title` | FR-001 |
| `{subtitle:VALUE}` | `{st:VALUE}` | `ParsedSong.subtitle` | FR-002 |
| `{artist:VALUE}` | — | `ParsedSong.artist` | FR-003 |
| `{key:VALUE}` | — | `ParsedSong.key` | FR-004 |
| `{capo:VALUE}` | — | `ParsedSong.capo` (parsed as int) | FR-005 |
| `{tempo:VALUE}` | — | `ParsedSong.tempo` (parsed as int) | FR-006 |
| `{time:VALUE}` | — | `ParsedSong.timeSignature` | FR-007 |

## Section directives (start/end pairs; unmatched end-of-file closes implicitly)

| Start | End | Aliases | Produces | FR |
|---|---|---|---|---|
| `{sov}` | `{eov}` | `{start_of_verse}` / `{end_of_verse}` | `SectionBlock('Verse')` + lyric lines | FR-008 |
| `{soc}` | `{eoc}` | `{start_of_chorus}` / `{end_of_chorus}` | `SectionBlock('Chorus')` + lyric lines | FR-009 |
| `{sob}` | `{eob}` | `{start_of_bridge}` / `{end_of_bridge}` | `SectionBlock('Bridge')` + lyric lines | FR-010 |
| `{sot}` | `{eot}` | `{start_of_tab}` / `{end_of_tab}` | `TabBlock(lines)` — raw text, no chord extraction | FR-011 |

## Annotation-line directives (single line each; value is the line's text, post `%{...}` substitution)

| Directive | Aliases | `AnnotationStyle` | FR |
|---|---|---|---|
| `{comment:VALUE}` | `{c:VALUE}` | `greyBar` | FR-012 |
| `{comment_italic:VALUE}` | `{ci:VALUE}` | `italic` | FR-013 |
| `{comment_box:VALUE}` | `{cb:VALUE}` | `boxed` | FR-014 |
| `{highlight:VALUE}` | — | `highlight` | FR-015 |

## Standing (session-scoped) directives

| Directive | Reset form | Effect | FR |
|---|---|---|---|
| `{textcolour:VALUE}` | `{textcolour}` | Sets `LyricBlock.textColor` for lyric text only (not chords) until reset/EOF | FR-016 |
| `{textsize:VALUE}` | `{textsize}` | Parsed, accepted, **no rendering effect** | FR-017 |
| `{textfont:VALUE}` | `{textfont}` | Parsed, accepted, **no rendering effect** | FR-017 |
| `{background:VALUE}` / `{bgcolor:VALUE}` / `{bgcolour:VALUE}` | bare form | Sets `LyricBlock.backgroundColor` until reset/EOF | (unchanged existing behavior; `highlight` removed from this alias group per research.md decision 6) |

`VALUE` for color directives is a named color (see `_namedColors`) or hex (`#RGB`/`#RRGGBB`/
`#AARRGGBB`); an unrecognized value applies no color and does not error.

## Inline directives (span within a single line; must open and close on the same line)

| Open | Close | Effect | FR |
|---|---|---|---|
| `{tb:VALUE}` | `{tb}` | Background color on the enclosed substring only | FR-018 |
| `{tc:VALUE}` | `{tc}` | Text color on the enclosed substring only | FR-019 |
| `{tb:VALUE}{tc:VALUE}` ... `{tc}{tb}` | — | Both styles combined on the same enclosed substring | FR-020 |

An inline span opened but not closed before end-of-line styles the remainder of that line only.

## Live metadata reference (inline text, not a directive)

| Syntax | Resolves to | Scope | FR |
|---|---|---|---|
| `%{title}`, `%{subtitle}`, `%{artist}`, `%{key}`, `%{capo}`, `%{tempo}`, `%{time}` | The metadata value most recently declared at that point in the file | Lyric lines and annotation lines | FR-021 |
| (any of the above, never declared) | empty string | — | FR-022 |

## Custom directives

| Pattern | Effect | FR |
|---|---|---|
| `{x_*:VALUE}` (any name prefixed `x_`) | Accepted, no visible effect (falls to default no-op) | FR-023 |

## Whole-file guarantee

Any file combining any number of the directives above, in any order or nesting, MUST import
without error, crash, or loss of unrelated content (FR-025).
