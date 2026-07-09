---

description: "Task list for Outro Section Tag Support"
---

# Tasks: Outro Section Tag Support

**Input**: Design documents from `/specs/002-outro-section-tag/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/chordpro-directive-grammar.md, quickstart.md

**Tests**: Included and REQUIRED — Constitution Principle IV (Test-First for Core Logic,
NON-NEGOTIABLE) mandates tests for parser changes, written and failing before implementation.

**Organization**: This feature has a single user story (P1), so there is no Setup or
Foundational phase — the change touches exactly two existing files
(`lib/services/chordpro_parser.dart` and `test/services/chordpro_parser_test.dart`), and all
supporting infrastructure (the generic `SectionBlock` type, the renderer, the section-directive
switch) already exists per `research.md` and `data-model.md`. There is no cross-story
parallelism opportunity either, since every task in this feature touches one of only two files.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies) — not applicable to most tasks
  in this feature since only two files are touched
- **[Story]**: US1 (the feature's only user story)

---

## Phase 1: User Story 1 - Import a chart with an outro section (Priority: P1) 🎯 MVP

**Goal**: `{soo}`/`{start_of_outro}` ... `{eoo}`/`{end_of_outro}` renders as a labeled "Outro"
section, matching the existing Verse/Chorus/Bridge treatment.

**Independent Test**: Import a `.cho` file containing a `{soo}...{eoo}` block; verify the song
view shows that block labeled "Outro," in the same position and order as the rest of the file.

### Tests for User Story 1 (write first, MUST fail before implementation)

- [X] T001 [US1] Add failing test: `{soo}` ... `{eoo}` produces a `SectionBlock` labeled "Outro" in `test/services/chordpro_parser_test.dart` (covers spec Acceptance Scenario 1)
- [X] T002 [US1] Add failing test: `{start_of_outro}` ... `{end_of_outro}` produces an identical result to `{soo}`/`{eoo}` in `test/services/chordpro_parser_test.dart` (covers spec Acceptance Scenario 2)
- [X] T003 [US1] Add failing test: mixed-case directives (`{SOO}`, `{Start_Of_Outro}`, `{EOO}`) are recognized identically to their lowercase form in `test/services/chordpro_parser_test.dart` (covers spec Acceptance Scenario 3)
- [X] T004 [US1] Add failing test: an unclosed `{soo}` (no matching `{eoo}`) continues through end-of-file without error in `test/services/chordpro_parser_test.dart` (covers spec Edge Case: unmatched start directive)
- [X] T005 [US1] Add failing test: a file with two outro blocks — one using `{soo}`/`{eoo}`, the other `{start_of_outro}`/`{end_of_outro}` — produces two separate, correctly-ordered "Outro" `SectionBlock`s in `test/services/chordpro_parser_test.dart` (covers spec Edge Cases: mixed short/long forms and repeated outro sections)
- [X] T006 [US1] Add failing test: a file combining an outro section with other supported directives (e.g. `{title:}`, `{sov}`/`{eov}`) imports without error and with no unrelated content dropped in `test/services/chordpro_parser_test.dart` (covers FR-004)

### Implementation for User Story 1

- [X] T007 [US1] Add `case 'soo': case 'start_of_outro':` to the section-directive switch in `lib/services/chordpro_parser.dart`, producing `SectionBlock(value.isNotEmpty ? value : 'Outro')`, placed alongside the existing `sov`/`soc`/`sob` cases (implements FR-001, FR-002; per `research.md` Decision 1 and 2, and `contracts/chordpro-directive-grammar.md`)
- [X] T008 [US1] Add `case 'eoo': case 'end_of_outro':` to the existing combined non-tab section-end case group (alongside `eov`/`eoc`/`eob`) in `lib/services/chordpro_parser.dart` (implements FR-001, FR-003; per `research.md` Decision 3)
- [X] T009 [US1] Run `flutter test test/services/chordpro_parser_test.dart` and confirm T001–T006 now pass

**Checkpoint**: User Story 1 is fully functional and independently testable — this is the entire
feature (there is only one user story).

---

## Phase 2: Polish & Cross-Cutting Concerns

**Purpose**: Final verification before the feature is considered done

- [X] T010 Run `flutter analyze` and resolve any new warnings introduced by the change
- [~] T011 Execute the manual/device validation steps in `quickstart.md` (import a `.cho` file with `{soo}...{eoo}` and one with `{start_of_outro}...{end_of_outro}`, confirm the "OUTRO" label renders identically in style to Verse/Chorus/Bridge on the running app) — partial: debug APK built, installed via `adb install -r`, and launched on the connected Pixel 10 Pro (serial 59190DLCH000SN); confirmed foreground/resumed with no FATAL/AndroidRuntime crashes in logcat. The interactive system file-picker import flow was not driven end-to-end (not scriptable via adb without risky blind UI taps) — see completion report for what this does and doesn't cover

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (User Story 1)**: No prerequisite phases — this is the first and only implementation phase
- **Phase 2 (Polish)**: Depends on Phase 1 completion

### Within Phase 1

- Tests (T001–T006) MUST be written and failing before implementation (T007–T008), per Constitution Principle IV
- T007 and T008 both edit `lib/services/chordpro_parser.dart` — do sequentially, not in parallel
- T009 (verify tests pass) depends on T007 and T008

### Parallel Opportunities

- None within this feature: T001–T006 all edit the same test file, and T007–T008 both edit the
  same parser file. Tasks must be executed sequentially in ID order.

---

## Implementation Strategy

### MVP First (and only) Scope

1. Complete Phase 1: User Story 1 (T001–T009) — this **is** the MVP; the feature has no
   additional stories to layer on afterward.
2. Complete Phase 2: Polish (T010–T011) to close out the feature.

---

## Notes

- [P] markers are omitted throughout — every task in this feature shares one of two files with
  another task in the same phase, so no genuine parallel execution exists.
- Verify T001–T006 fail before starting T007–T008 (Red-Green-Refactor, per Constitution Principle IV).
- Commit after the test phase (T001–T006, all failing) and again after the implementation phase
  (T007–T009, all passing), consistent with the project's normal commit granularity.
