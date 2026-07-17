---

description: "Task list template for feature implementation"
---

# Tasks: Tuning Tag and Custom Preset Directive

**Input**: Design documents from `/specs/005-tuning-custom-directives/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/directive-additions.md, quickstart.md

**Tests**: Constitution Principle IV (Test-First for Core Logic, NON-NEGOTIABLE) requires tests for the parser (core logic, no UI in the loop) written and failing before their implementation. The renderer change is UI code, verified via `quickstart.md` manual on-device validation instead of widget tests, per the project's established `run`/`verify` pattern.

**Organization**: Tasks are grouped by user story (US1/US2, matching spec.md priorities P1/P2). There is no Setup or Foundational phase — this feature adds no dependencies and has no infrastructure shared between the two stories beyond files they both happen to edit (noted under Dependencies below).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an incomplete task)
- **[Story]**: Which user story this task belongs to (US1, US2)
- File paths are exact, per plan.md's Project Structure

---

## Phase 1: User Story 1 - See a song's tuning at a glance (Priority: P1) 🎯 MVP

**Goal**: A `{tuning:}` (or `{tu:}`) directive is parsed and displayed both directly below the artist line and in the song's metadata row.

**Independent Test**: Import a ChordPro file with a `{tuning:}` directive, open the song, and confirm the tuning appears both directly below the artist name and in the metadata row.

### Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation (Constitution Principle IV)**

- [X] T001 [US1] Write failing parser tests in `test/services/chordpro_parser_test.dart`: `{tuning:VALUE}` sets `ParsedSong.tuning`; `{tu:VALUE}` (alias) sets it too; first declaration wins across a mix of `{tuning:}` and `{tu:}` redeclarations (FR-008); and — critically — `{t: ...}` still sets `ParsedSong.title`, unaffected by the new `tu` alias (regression guard for the alias-collision decision in spec Clarifications)

### Implementation for User Story 1

- [X] T002 [US1] Add `tuning` (String?) to `ParsedSong` and implement its `case 'tuning': case 'tu':` in the directive `switch` in `lib/services/chordpro_parser.dart`, following the existing `key`/`timeSignature` first-write-wins pattern, to make T001 pass (depends on T001)
- [X] T003 [US1] In `lib/widgets/chordpro_renderer.dart`: add a labeled tuning tag directly below the artist `Text` widget, add a `Tuning: ${parsed.tuning}` `_MetaChip` to the metadata `Wrap` row, and expand the row's visibility condition to include `parsed.tuning != null` (depends on T002)
- [ ] T004 [P] [US1] Add the `tuning` row (directive `{tuning:VALUE}`, alias `{tu:VALUE}`) to the "Metadata directives" table in `specs/001-chordpro-tag-support/contracts/chordpro-directive-grammar.md`, per `contracts/directive-additions.md` (research.md §4)

**Checkpoint**: User Story 1 is fully functional and independently testable (MVP)

---

## Phase 2: User Story 2 - Display a pedal-preset tag (Priority: P2)

**Goal**: A `{preset:}` (or `{p:}`) directive is parsed and displayed in the song's metadata row.

**Independent Test**: Import a ChordPro file with a `{preset:}` directive, open the song, and confirm the preset value appears in the metadata row.

### Tests for User Story 2

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation (Constitution Principle IV)**

- [ ] T005 [US2] Write failing parser tests in `test/services/chordpro_parser_test.dart`: `{preset:VALUE}` sets `ParsedSong.preset`; `{p:VALUE}` (alias) sets it too; first declaration wins across a mix of `{preset:}` and `{p:}` redeclarations; and a custom `{x_foo:VALUE}` directive (unrelated to preset) remains a no-op, confirming `preset` is not part of the `x_*` custom-directive mechanism (FR-006) (depends on Phase 1 completing — same test file as T001)

### Implementation for User Story 2

- [ ] T006 [US2] Add `preset` (String?) to `ParsedSong` and implement its `case 'preset': case 'p':` in the directive `switch` in `lib/services/chordpro_parser.dart`, following the same first-write-wins pattern as `tuning`, to make T005 pass (depends on T005, T002 — same file)
- [ ] T007 [US2] In `lib/widgets/chordpro_renderer.dart`: add a `Preset: ${parsed.preset}` `_MetaChip` to the metadata row (no below-artist duplicate, unlike tuning) and further expand the row's visibility condition to include `parsed.preset != null` (depends on T006, T003 — same file)
- [ ] T008 [P] [US2] Add the `preset` row (directive `{preset:VALUE}`, alias `{p:VALUE}`) to the "Metadata directives" table in `specs/001-chordpro-tag-support/contracts/chordpro-directive-grammar.md`, per `contracts/directive-additions.md` (research.md §4)

**Checkpoint**: Both user stories are independently functional

---

## Phase 3: Polish & Cross-Cutting Concerns

- [ ] T009 [P] Run `flutter analyze` and resolve any new warnings across all files touched by this feature (constitution quality gate)
- [ ] T010 Run the `quickstart.md` validation scenarios 1–7 plus the regression check, on-device (Android primary target; iPad secondary target if available)

---

## Dependencies & Execution Order

### Phase Dependencies

- **User Story 1 (Phase 1)**: No dependencies — can start immediately
- **User Story 2 (Phase 2)**: Both `test/services/chordpro_parser_test.dart` and `lib/services/chordpro_parser.dart` and `lib/widgets/chordpro_renderer.dart` are edited by both stories — for a solo implementer, complete Phase 1 before starting Phase 2 to avoid conflicting concurrent edits to the same files (the two stories are logically independent; the file-sharing is what forces sequencing here, same situation as prior features with a single shared UI/parser file)
- **Polish (Phase 3)**: Depends on both user stories being complete

### Within Each User Story

- Tests written and failing before their implementation (Constitution Principle IV)
- Parser changes (`ParsedSong` field + `switch` case) before the renderer changes that read the new field
- Grammar-doc task (T004/T008) has no code dependency — it can be done anytime once that story's directive name/alias is finalized (already true from spec.md), but is listed after the tests for narrative order

### Parallel Opportunities

- T004 (grammar-doc row for tuning) touches a file no code task touches, so it can run in parallel with T002/T003 once started
- T008 (grammar-doc row for preset) is similarly parallel-capable with T006/T007
- T009 (`flutter analyze`) is independent cleanup

---

## Parallel Example: Phase 1 (User Story 1)

```bash
# T004 (grammar doc) can run alongside T002/T003 (code) — different file, no dependency:
Task: "Add the tuning row to specs/001-chordpro-tag-support/contracts/chordpro-directive-grammar.md"
Task: "Add tuning field + switch case to lib/services/chordpro_parser.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: User Story 1 (tests → parser → renderer → grammar doc)
2. **STOP and VALIDATE**: Run quickstart.md Scenarios 1–3, 6 (tuning-specific) and the `{t:}`-still-means-title check from Scenario 7 on-device
3. This is a usable, demoable MVP — tuning tag alone, independent of preset

### Incremental Delivery

1. Add User Story 1 → validate → MVP
2. Add User Story 2 → validate with quickstart Scenarios 4–5, 7 (preset-specific)
3. Polish: `flutter analyze` clean, full quickstart pass including the regression check

---

## Notes

- [P] tasks touch different files with no incomplete-task dependency
- This feature's two stories share `lib/services/chordpro_parser.dart`, `test/services/chordpro_parser_test.dart`, and `lib/widgets/chordpro_renderer.dart` as common files — sequence US1 → US2 for a solo implementer
- Commit after each task or logical group
- Stop at each checkpoint to validate that story independently before moving on
