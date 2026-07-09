# Implementation Plan: Outro Section Tag Support

**Branch**: `002-outro-section-tag` | **Date**: 2026-07-08 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/002-outro-section-tag/spec.md`

## Summary

Add recognition of a new ChordPro section directive pair — `{soo}`/`{eoo}` with long-form aliases
`{start_of_outro}`/`{end_of_outro}` — so that outro passages render as a labeled "Outro" section,
matching the existing treatment of Verse/Chorus/Bridge sections. The parser's `SectionBlock` type
already takes an arbitrary label string, so this is a small, additive change to the directive
switch in `ChordProParser`: no new entities, no renderer changes, and no persistence/schema impact.

## Technical Context

**Language/Version**: Dart, Flutter SDK `^3.9.2` (per `pubspec.yaml`)

**Primary Dependencies**: Flutter SDK only — no new third-party packages required

**Storage**: N/A — this is a parser-level (in-memory) change; no `sqflite` schema impact

**Testing**: `flutter test`, specifically `test/services/chordpro_parser_test.dart`

**Target Platform**: Android (primary) and iPad (secondary), via the existing GigBook Flutter app

**Project Type**: Mobile app (single Flutter project — no frontend/backend split)

**Performance Goals**: N/A — one additional `switch` case in an already-linear, single-pass parse; no measurable performance impact

**Constraints**: Offline-capable (inherits existing parser behavior); directive names matched case-insensitively; import must not fail or drop unrelated content when outro directives are present

**Scale/Scope**: One new directive pair (plus long-form alias) recognized by one existing parser method; no new files, entities, or screens

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Offline-First & Local Data Ownership**: Not implicated — this is a local parsing change with no network or sync dependency. **Pass.**
- **II. ChordPro Standard Fidelity**: `{start_of_outro}`/`{end_of_outro}` is not part of the strict upstream ChordPro core-directive list, the same situation as the already-shipped `{sob}`/`{start_of_bridge}` (Bridge). Per research (below), this is handled the same way Bridge already is: added directly to the existing section-directive switch, not silently dropped and not mixed into unrelated directive handling. **Pass**, consistent with existing precedent.
- **III. Stage-Ready UX**: The existing `SectionBlock` renderer (`lib/widgets/chordpro_renderer.dart`) already displays any section label in the same high-contrast, uppercase, always-visible style — no new UI work is needed for Outro to meet this bar. **Pass.**
- **IV. Test-First for Core Logic (NON-NEGOTIABLE)**: This is a parser change (core logic, no UI in the loop). Tests for `{soo}`/`{eoo}`, `{start_of_outro}`/`{end_of_outro}`, case-insensitivity, and the unmatched-end-tag edge case MUST be written and failing before the parser change lands. **Pass**, to be enforced in `/speckit-tasks` ordering.
- **V. Simplicity & YAGNI**: No new abstraction is introduced — the change reuses the existing generic `SectionBlock(label)` and the existing section-directive switch, exactly as Verse/Chorus/Bridge already do. **Pass.**
- **VI. Flutter & Material Idioms**: No widget or state-management changes at all. **Pass.**

No violations — Complexity Tracking is not needed.

## Project Structure

### Documentation (this feature)

```text
specs/002-outro-section-tag/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
lib/
├── services/
│   └── chordpro_parser.dart      # Add {soo}/{start_of_outro} and {eoo}/{end_of_outro} cases
└── widgets/
    └── chordpro_renderer.dart    # No change — generic SectionBlock rendering already covers Outro

test/
└── services/
    └── chordpro_parser_test.dart # Add outro section test cases (written first, per Principle IV)
```

**Structure Decision**: Single Flutter project (existing GigBook app structure under `lib/` and
`test/`). This feature touches exactly one existing service file and its existing test file — no
new directories, packages, or screens are introduced.

## Complexity Tracking

*No entries — Constitution Check has no violations to justify.*
