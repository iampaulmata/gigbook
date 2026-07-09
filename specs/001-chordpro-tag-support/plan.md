# Implementation Plan: Full ChordPro Tag Support

**Branch**: `001-chordpro-tag-support` | **Date**: 2026-07-08 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-chordpro-tag-support/spec.md`

## Summary

Extend `ChordProParser`/`ChordProRenderer` to recognize the full directive set requested in the
spec — metadata (title/subtitle/artist/key/capo/tempo/time), verse/chorus/bridge/tab sections,
four distinct annotation-line styles, standing text color (lyrics only), standing text-size/font
(parsed but visually inert), true inline color/background spans, live `%{...}` metadata
substitution (lyric + annotation lines), and silently-ignored `x_*` custom directives — without
adding new dependencies or database schema changes. Subtitle and time signature are surfaced only
at render time (not persisted), keeping the change scoped to the parser and renderer.

## Technical Context

**Language/Version**: Dart, Flutter SDK constraint `^3.9.2` (per `pubspec.yaml`)

**Primary Dependencies**: Flutter SDK only (`Text.rich`/`TextSpan` for inline styling); no new
package — existing `provider` state management is unaffected by this feature

**Storage**: `sqflite` (existing `songs` table) — **no schema changes**; subtitle/time signature
are parsed live at render time rather than persisted (see research.md decision 1)

**Testing**: `flutter_test` (existing dev dependency); new `test/services/chordpro_parser_test.dart`
written before the parser changes, per Constitution Principle IV

**Target Platform**: Android (primary), iPad (secondary) — pure Dart/Flutter, no platform channels

**Project Type**: mobile-app (single existing Flutter project; no new top-level structure)

**Performance Goals**: No perceptible delay opening a song of typical length (tens to a few
hundred lines) on a mid-range Android tablet — matches current behavior, no regression budget
beyond "stays imperceptible"

**Constraints**: Fully offline (Constitution I); no new third-party dependency without
justification (Constitution Technology Constraints)

**Scale/Scope**: Single-song files (tens to a few hundred lines each); single-user local library —
not a scale-sensitive change

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Assessment |
|---|---|
| I. Offline-First & Local Data Ownership | **Pass** — purely local parsing/rendering change; no network path touched. |
| II. ChordPro Standard Fidelity | **Pass** — this feature *is* the fidelity work; unknown/custom (`x_*`) directives stay in the no-op default branch, isolated from standard-directive handling. |
| III. Stage-Ready UX | **Pass** — standing `{textsize}`/`{textfont}` are explicitly inert (app's own font settings stay authoritative); standing text color never recolors chords, preserving the existing chords-secondary visual hierarchy. |
| IV. Test-First for Core Logic (NON-NEGOTIABLE) | **Pass, enforced in tasks** — `chordpro_parser.dart` changes require `test/services/chordpro_parser_test.dart` written and failing first; renderer visual changes verified on-device per `run`/`verify` skills. |
| V. Simplicity & YAGNI | **Pass** — deliberately no DB migration for subtitle/time signature (render-only fields); one small `LyricRun` model added instead of a general inline-markup AST. |
| VI. Flutter & Material Idioms | **Pass** — no new state-management paradigm; new visual styles are widget variants using the existing `AppTheme`/Material 3 color scheme. |

No violations identified. Complexity Tracking table below is not applicable.

## Project Structure

### Documentation (this feature)

```text
specs/001-chordpro-tag-support/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/
│   └── chordpro-directive-grammar.md
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
lib/
├── services/
│   ├── chordpro_parser.dart      # MODIFIED — directive coverage, new block/run types
│   └── import_service.dart       # MODIFIED — extractMeta: stop folding subtitle into artist
└── widgets/
    └── chordpro_renderer.dart    # MODIFIED — 4 annotation styles, tab block, inline spans,
                                   #            subtitle/time-signature header, standing-color
                                   #            no longer recolors chords

test/
└── services/
    └── chordpro_parser_test.dart # NEW — parser test suite (written before implementation)
```

**Structure Decision**: Single existing Flutter project (`gigbook`); no new modules, packages, or
top-level directories. All production changes are confined to two existing service/widget files
plus a one-line-scoped fix in `import_service.dart`; the only new file is the parser's test suite.

## Complexity Tracking

*No Constitution Check violations were identified for this feature — table intentionally omitted.*
