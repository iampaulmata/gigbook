# Implementation Plan: Tuning Tag and Custom Preset Directive

**Branch**: `005-tuning-custom-directives` | **Date**: 2026-07-16 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/005-tuning-custom-directives/spec.md`

## Summary

Add two new ChordPro directives recognized by the existing parser: `{tuning:VALUE}` (alias `{tu:VALUE}`) and `{preset:VALUE}` (alias `{p:VALUE}`) — both first-class metadata directives, parsed and stored the same way as `key`/`capo`/`time`; the general `x_*` custom-directive no-op rule is untouched by this feature. Both new fields are display-only, re-derived on every parse — no database changes. `tuning` renders in two places (a tag directly below the artist line, and the existing metadata chip row); `preset` renders in the metadata chip row only. The chip row's visibility condition expands to include either new field.

## Technical Context

**Language/Version**: Dart ^3.9.2 (Flutter 3.35, stable channel) — unchanged from the rest of the project.

**Primary Dependencies**: None new. Pure additions to `lib/services/chordpro_parser.dart` and `lib/widgets/chordpro_renderer.dart`, both already part of the codebase.

**Storage**: N/A — `tuning`/`preset` are re-derived from `Song.content` on every render via `ChordProParser.parse()`, exactly like the existing `timeSignature` field; no `songs` table column or migration (research.md §3).

**Testing**: `flutter_test`. Per Constitution Principle IV (Test-First, NON-NEGOTIABLE), new cases in `test/services/chordpro_parser_test.dart` are written and failing before the parser changes that make them pass. The renderer change is UI code, verified via `quickstart.md` manual on-device validation, consistent with how `chordpro_renderer.dart` was already treated in prior features.

**Target Platform**: Android (primary), iPad/iOS (secondary) — per constitution Technology Constraints; no platform-specific code involved.

**Project Type**: Mobile app (single Flutter project; existing `lib/` layout, no new files beyond a grammar contract doc).

**Performance Goals**: Negligible — two additional `switch` cases and two additional conditional `Text`/chip widgets; no measurable impact on parse or render time.

**Constraints**: Must not change parsing or rendering behavior for any song lacking `{tuning:}`/`{preset:}` directives (spec SC-004) — a strict backward-compatibility requirement, not just a nice-to-have. Must not collide with any existing directive/alias — `tu`/`p` were checked against the full existing table (research.md §1; `t` was ruled out as it's already `title`'s alias).

**Scale/Scope**: Two new optional string fields on one existing model, two new `switch` cases, one widget-tree addition, one grammar-doc amendment. No new screens, providers, or services.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|---|---|---|
| I. Offline-First & Local Data Ownership | PASS | Pure local parsing/rendering; no network, sync, or account involvement whatsoever. |
| II. ChordPro Standard Fidelity | PASS | `tuning` and `preset` both follow the same unprefixed, first-class-directive convention already established by `key`/`capo`/`tempo`/`time` — non-core-ChordPro-standard directives the app already documents and treats as first-class (research.md §2). The general `x_*` custom-directive mechanism and its no-op rule (FR-023) are completely untouched by this feature (FR-006). Both new directives are documented in the grammar contract per this principle's requirement. |
| III. Stage-Ready UX | PASS | Tuning is surfaced immediately below the artist name — exactly the "at a glance, no extra taps" bar this principle sets for performance-critical screens (SC-001). No new taps, no buried settings. |
| IV. Test-First for Core Logic | PASS (planned) | Parser is core logic (no UI in the loop); new test cases in `chordpro_parser_test.dart` are written first, enforced in tasks.md ordering. |
| V. Simplicity & YAGNI | PASS | No generic custom-directive display system (research.md §1) — scoped to exactly the one field the user asked for. No new DB column/migration for data already available by reparsing (research.md §3), matching existing `timeSignature` precedent. |
| VI. Flutter & Material Idioms | PASS | Reuses the existing `_MetaChip` widget for both display locations rather than introducing a new visual component. |

No violations — Complexity Tracking is not needed.

**Post-Phase 1 re-check**: `data-model.md` (two nullable String fields, no new entity) and `contracts/directive-additions.md` (a documented, scoped grammar delta with an explicit master-doc amendment) confirm the above holds; no new violations introduced by the detailed design.

## Project Structure

### Documentation (this feature)

```text
specs/005-tuning-custom-directives/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
│   └── directive-additions.md
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

Single Flutter mobile app; this feature only touches two existing files plus one existing cross-feature doc — no new files, screens, providers, or services.

```text
lib/
├── services/
│   └── chordpro_parser.dart       # MODIFIED — ParsedSong gains tuning/preset fields;
│                                   #   two new switch cases + aliases (tuning/tu, preset/p)
└── widgets/
    └── chordpro_renderer.dart     # MODIFIED — tuning tag below artist line; tuning/preset
                                    #   chips in the existing metadata row; row visibility
                                    #   condition expanded

test/
└── services/
    └── chordpro_parser_test.dart  # MODIFIED — new cases for tuning and preset (incl. their
                                    #   tu/p aliases), written before the parser changes per
                                    #   Constitution Principle IV

specs/
└── 001-chordpro-tag-support/
    └── contracts/
        └── chordpro-directive-grammar.md  # MODIFIED — apply the delta from this feature's
                                            #   contracts/directive-additions.md (research.md §4)
```

**Structure Decision**: Single Flutter project, no new structure. All changes land in two existing `lib/` files (already covered by the project's `lib/services` / `lib/widgets` convention), one existing test file, and one existing cross-feature grammar doc — reflecting how small and additive this feature is relative to the codebase's established layout.

## Complexity Tracking

Not applicable — the Constitution Check above shows no violations.
