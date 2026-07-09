# GigBook

GigBook is an offline-first Flutter app for musicians who need fast, reliable access to lyrics
and chords on stage. Import ChordPro charts, organize them into setlists, and perform from a
dark, large-text display — no network connection required.

## Features

- **ChordPro library** — import individual files or whole folders (`.cho`, `.crd`, `.pro`,
  `.txt`), browse and search your songs, mark favorites.
- **Full ChordPro tag support** — metadata, sections, annotation lines, text color/highlight,
  and live metadata references. See the [quick reference](#chordpro-tag-quick-reference) below.
- **Setlists** — build ordered setlists for a gig, reorder by drag-and-drop, and step through
  songs in order while performing. Setlists can be exported/imported as JSON to share with other
  band members.
- **Stage-ready display** — adjustable font size, chords on/off toggle, auto-scroll with
  tempo-synced speed, and a high-contrast dark theme designed for low-light stages.
- **Google Drive sync** — link a Drive folder to pull in charts and setlists, push local edits
  back, and get flagged on conflicting remote changes instead of silently overwriting them.
- **Live session** — host or join a nearby live session (via Nearby Connections) so a whole band
  can follow the same "now playing" song and scroll position from the leader's device.

## ChordPro tag quick reference

All tag and directive names below are case-insensitive. Full technical grammar:
[`specs/001-chordpro-tag-support/contracts/chordpro-directive-grammar.md`](specs/001-chordpro-tag-support/contracts/chordpro-directive-grammar.md).

**Metadata**

| Tag | Aliases | Sets |
|---|---|---|
| `{title: ...}` | `{t: ...}` | Song title |
| `{subtitle: ...}` | `{st: ...}` | Subtitle |
| `{artist: ...}` | | Artist |
| `{key: ...}` | | Key |
| `{capo: ...}` | | Capo position |
| `{tempo: ...}` | `{bpm: ...}` | Tempo (BPM) |
| `{time: ...}` | | Time signature |

**Sections**

| Tag | Aliases | Renders as |
|---|---|---|
| `{sov} ... {eov}` | `{start_of_verse} ... {end_of_verse}` | Verse |
| `{soc} ... {eoc}` | `{start_of_chorus} ... {end_of_chorus}` | Chorus |
| `{sob} ... {eob}` | `{start_of_bridge} ... {end_of_bridge}` | Bridge |
| `{sot} ... {eot}` | `{start_of_tab} ... {end_of_tab}` | Tab — shown verbatim, no chord parsing |

**Annotation lines** (performance notes, kept separate from lyrics)

| Tag | Aliases | Style |
|---|---|---|
| `{comment: ...}` | `{c: ...}` | Grey bar |
| `{comment_italic: ...}` | `{ci: ...}` | Italic |
| `{comment_box: ...}` | `{cb: ...}` | Boxed |
| `{highlight: ...}` | | Highlighted |

**Standing text style** (applies to every line until reset)

| Tag | Reset | Effect |
|---|---|---|
| `{textcolour: red}` | `{textcolour}` | Colors following lyric lines only — never the chords above them |
| `{background: yellow}` (or `{bgcolor:}` / `{bgcolour:}`) | bare form | Background color for following lines |
| `{textsize: 14}` | `{textsize}` | Accepted, but has no visual effect — your font-size setting always wins |
| `{textfont: sans}` | `{textfont}` | Accepted, but has no visual effect — the app's font always wins |

**Inline spans** (style just part of a line)

| Tag | Effect |
|---|---|
| `{tb:yellow} text {tb}` | Background highlight on the enclosed text only |
| `{tc:black} text {tc}` | Text color on the enclosed text only |
| `{tb:yellow}{tc:black} text {tc}{tb}` | Both combined on the same span |

**Live metadata in text**

Drop `%{key}`, `%{capo}`, `%{tempo}`, `%{title}`, etc. into a lyric or comment line to insert the
current value of that metadata, e.g. `{c: Capo %{capo}, key of %{key}}`.

**Custom directives**

`{x_anything: value}` — any directive starting with `x_` is accepted and silently ignored, for
compatibility with tags written by other ChordPro tools.

## Getting started

Requires the Flutter SDK (see `pubspec.yaml` for the exact version constraint).

```bash
flutter pub get
flutter run
```

Run the test suite with:

```bash
flutter test
```

## Project structure

- `lib/models/` — plain Dart data models (Song, Setlist, SetlistEntry)
- `lib/db/` — sqflite persistence
- `lib/services/` — ChordPro parsing, import, Drive sync, live session, setlist sharing
- `lib/providers/` — app state (library, setlists, settings, sync, live session)
- `lib/widgets/` / `lib/screens/` — UI
- `specs/` — spec-driven feature specs, plans, and tasks (see `.specify/memory/constitution.md`
  for the project's governing principles)
