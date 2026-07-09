# GigBook

GigBook is an offline-first Flutter app for musicians who need fast, reliable access to lyrics
and chords on stage. Import ChordPro charts, organize them into setlists, and perform from a
dark, large-text display — no network connection required.

## Features

- **ChordPro library** — import individual files or whole folders (`.cho`, `.crd`, `.pro`,
  `.txt`), browse and search your songs, mark favorites.
- **Full ChordPro tag support** — metadata (title, subtitle, artist, key, capo, tempo, time
  signature), verse/chorus/bridge/tab sections, four annotation-line styles (grey-bar, italic,
  boxed, highlight), standing and inline text color/highlight spans, and live `%{...}` metadata
  references in lyrics. See [`specs/001-chordpro-tag-support`](specs/001-chordpro-tag-support) for
  the full directive grammar this parser implements.
- **Setlists** — build ordered setlists for a gig, reorder by drag-and-drop, and step through
  songs in order while performing. Setlists can be exported/imported as JSON to share with other
  band members.
- **Stage-ready display** — adjustable font size, chords on/off toggle, auto-scroll with
  tempo-synced speed, and a high-contrast dark theme designed for low-light stages.
- **Google Drive sync** — link a Drive folder to pull in charts and setlists, push local edits
  back, and get flagged on conflicting remote changes instead of silently overwriting them.
- **Live session** — host or join a nearby live session (via Nearby Connections) so a whole band
  can follow the same "now playing" song and scroll position from the leader's device.

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
