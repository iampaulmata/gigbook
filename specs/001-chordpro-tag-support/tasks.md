---

description: "Task list for feature implementation"
---

# Tasks: Full ChordPro Tag Support

**Input**: Design documents from `/specs/001-chordpro-tag-support/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/chordpro-directive-grammar.md, quickstart.md (all present)

**Tests**: Included and REQUIRED for parser (`lib/services/chordpro_parser.dart`) changes per
Constitution Principle IV (Test-First for Core Logic, NON-NEGOTIABLE). Renderer (widget) changes
are verified manually on-device per the constitution's allowance for UI code, using the project's
`run`/`verify` skills — no widget test tasks are generated.

**Organization**: Tasks are grouped by user story (P1–P5 from spec.md) to enable independent
implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US5)
- All parser/renderer tasks touch one of two shared files
  (`lib/services/chordpro_parser.dart`, `lib/widgets/chordpro_renderer.dart`); tasks against the
  same file are ordered sequentially and are not marked `[P]` even within the same story.

## Path Conventions

Single existing Flutter project (`gigbook`) — no new top-level directories. All paths are relative
to the repository root.

---

## Phase 1: Setup

**Purpose**: Establish a baseline and a place for the new test suite

- [X] T001 Run `flutter test` and `flutter analyze` on the current tree (no code changes) to record a pre-change baseline
- [X] T002 [P] Create `test/services/chordpro_parser_test.dart` with the standard `flutter_test` imports and an empty `main()` group, ready for the test tasks below

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Introduce the shared data-model types every user story depends on, without changing
any observable behavior yet. This phase MUST be complete, compiling, and behavior-neutral before
any user story begins.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T003 Add `AnnotationStyle` enum (`greyBar`, `italic`, `boxed`, `highlight`) and rename `CommentBlock` to `AnnotationBlock(text, style)` in `lib/services/chordpro_parser.dart`; update the existing `{c}/{comment}` case to construct `AnnotationBlock(value, AnnotationStyle.greyBar)` as a placeholder (style differentiation lands in US2)
- [X] T004 Add a `TabBlock(List<String> lines)` class (data holder only, not yet populated) and `subtitle`/`timeSignature` fields to `ParsedSong` (default empty/null, not yet populated by the parser) in `lib/services/chordpro_parser.dart`
- [X] T005 Add a `LyricRun { String text; Color? textColor; Color? backgroundColor }` class; change `ChordLyricPair.lyric` from `String` to `List<LyricRun>`; update `_parseLyricLine` and `LyricBlock.isEmpty` so each existing plain-text lyric segment becomes a single unstyled `LyricRun`, leaving current parsed output unchanged, in `lib/services/chordpro_parser.dart`
- [X] T006 Update `_ChordLyricChunk` (and the whole-line no-chords branch) in `lib/widgets/chordpro_renderer.dart` to render `List<LyricRun>` via `Text.rich`/`TextSpan`, producing output pixel-equivalent to today
- [X] T007 Update the block-type switch in `lib/widgets/chordpro_renderer.dart` to match `AnnotationBlock` instead of `CommentBlock`, keeping today's single visual treatment for every annotation line for now
- [X] T008 Run `flutter analyze` and `flutter test`, and manually launch the app to confirm it builds and renders existing songs identically to the Phase 1 baseline

**Checkpoint**: App compiles and behaves exactly as before; new types exist but are inert — ready for user-story work.

---

## Phase 3: User Story 1 - Import a chart with full song metadata and structure (Priority: P1) 🎯 MVP

**Goal**: Title/subtitle/artist/key/capo/tempo/time signature are all captured and shown, and
verse/chorus/bridge/tab sections are all preserved and structurally rendered.

**Independent Test**: Import the `quickstart.md` sample file (or any `.cho` exercising every
metadata directive and all four section types); verify the library list and song header show the
captured metadata, and every section — including tab content — appears in source order with
nothing dropped.

### Tests for User Story 1 ⚠️

**Write these tests FIRST in `test/services/chordpro_parser_test.dart`; confirm they FAIL before implementation.**

- [X] T009 [P] [US1] Add failing tests for FR-001–FR-011: `{title}/{t}`, `{subtitle}/{st}` (distinct from artist), `{artist}`, `{key}`, `{capo}`, `{tempo}`, `{time}`; `{sov}/{eov}`, `{soc}/{eoc}`, `{sob}/{eob}` (+ long-form aliases, + unmatched end-of-file runs to EOF); `{sot}/{eot}` captured as raw literal `TabBlock` lines with no `[Chord]` extraction, including bracket-lookalike characters

### Implementation for User Story 1

- [X] T010 [US1] Add `{subtitle:}`/`{st:}` (separate from artist) and `{time:}` cases to the parser's directive switch in `lib/services/chordpro_parser.dart` (depends on T009, T004)
- [X] T011 [US1] Fix `ChordProParser.extractMeta` in `lib/services/chordpro_parser.dart` to stop reading `st`/`subtitle` into its `artist` result (depends on T009)
- [X] T012 [US1] Implement `{sot}`/`{eot}` raw-line capture into `TabBlock` (replacing today's tab-content skip) in `lib/services/chordpro_parser.dart`, and confirm `{sov}/{soc}/{sob}` + long-form aliases still produce correctly labeled `SectionBlock`s (depends on T009, T004)
- [X] T013 [US1] Run `flutter test test/services/chordpro_parser_test.dart` and confirm all US1 tests pass (depends on T010, T011, T012)
- [X] T014 [US1] Render `subtitle` and `timeSignature` in the song header, and render `TabBlock` as raw monospace text, in `lib/widgets/chordpro_renderer.dart` (depends on T006, T012)
- [X] T015 [US1] Manually verify User Story 1's acceptance scenarios on-device using the `quickstart.md` sample file, per the project's `run`/`verify` skill (depends on T014) — verified on Pixel 10 Pro: header shows title/subtitle/artist/key/capo/tempo/time chips correctly, all four section types render in order including tab content

**Checkpoint**: User Story 1 is fully functional and independently testable (MVP).

---

## Phase 4: User Story 2 - Import a chart with styled annotation lines (Priority: P2)

**Goal**: `{c}/{comment}`, `{ci}/{comment_italic}`, `{cb}/{comment_box}`, and `{highlight}` each
render as a visually distinct annotation-line style.

**Independent Test**: Import a file with one line of each of the four styles; verify each is
visually distinguishable from lyric lines and from the other three.

### Tests for User Story 2 ⚠️

**Write these tests FIRST in `test/services/chordpro_parser_test.dart`; confirm they FAIL before implementation.**

- [X] T016 [P] [US2] Add failing tests for FR-012–FR-015: `{c}/{comment}` → `AnnotationStyle.greyBar`, `{ci}/{comment_italic}` → `.italic`, `{cb}/{comment_box}` → `.boxed`, `{highlight}` → `.highlight`

### Implementation for User Story 2

- [X] T017 [US2] Add `{comment_italic:}/{ci:}` → `AnnotationStyle.italic`, `{comment_box:}/{cb:}` → `.boxed`, and `{highlight:}` → `.highlight` cases to the parser's directive switch; remove `highlight` from the `background`/`bgcolor`/`bgcolour` alias group, in `lib/services/chordpro_parser.dart` (depends on T016, T003)
- [X] T018 [US2] Run `flutter test test/services/chordpro_parser_test.dart` and confirm all US2 tests pass (depends on T017)
- [X] T019 [US2] Render the four distinct `AnnotationStyle` treatments (grey-bar, italic, boxed, highlight) in `lib/widgets/chordpro_renderer.dart` (depends on T007, T017)
- [X] T020 [US2] Manually verify User Story 2's acceptance scenarios on-device (all four styles visually distinct), per `run`/`verify` skill (depends on T019) — verified on Pixel 10 Pro: grey-bar, italic, boxed, and highlight annotation lines all render as visually distinct treatments

**Checkpoint**: User Stories 1 and 2 both work independently.

---

## Phase 5: User Story 3 - Import a chart with color-coded text (Priority: P3)

**Goal**: Standing `{textcolour:}` colors lyric text (never chords); `{textsize}`/`{textfont}`
are accepted but visually inert; inline `{tb:}`/`{tc:}` spans (including combined) style exactly
their enclosed substring.

**Independent Test**: Import a file combining a standing `{textcolour:red}...{textcolour}` passage
with inline `{tb:yellow}`/`{tc:black}`/combined spans; verify the standing color covers the whole
passage's lyrics only (chords unaffected) and each inline tag colors only its own substring.

### Tests for User Story 3 ⚠️

**Write these tests FIRST in `test/services/chordpro_parser_test.dart`; confirm they FAIL before implementation.**

- [X] T021 [P] [US3] Add failing tests for FR-016–FR-020 and related Edge Cases: standing `{textcolour:}`/bare-reset applies to `LyricBlock.textColor` only; `{textsize}`/`{textfont}` produce no data-model effect; inline `{tb:VALUE}...{tb}`, `{tc:VALUE}...{tc}`, and combined spans produce correctly bounded `LyricRun`s; an inline tag left unclosed styles only to end of line

### Implementation for User Story 3

- [X] T022 [US3] Implement inline `{tb:VALUE}...{tb}` / `{tc:VALUE}...{tc}` (including combined) span parsing in `_parseLyricLine`, splitting matched lyric segments into styled `LyricRun`s, in `lib/services/chordpro_parser.dart` (depends on T021, T005)
- [X] T023 [US3] Confirm standing `{textcolour:}` continues to set only `LyricBlock.textColor` (never chord styling) and that `{textsize}`/`{textfont}` remain no-ops; add explicit switch cases with a one-line comment documenting the intentional no-op if not already covered by the default branch, in `lib/services/chordpro_parser.dart` (depends on T021) — kept as a documented no-op comment rather than dead-code case labels (Constitution V); regression tests already assert both existing behaviors
- [X] T024 [US3] Run `flutter test test/services/chordpro_parser_test.dart` and confirm all US3 tests pass (depends on T022, T023)
- [X] T025 [US3] Render inline `LyricRun` colors/backgrounds via `TextSpan` (`style.color`/`style.backgroundColor`) in `_ChordLyricChunk` in `lib/widgets/chordpro_renderer.dart` (depends on T006, T022) — already satisfied by the Foundational-phase `Text.rich` rendering (T006); no additional renderer change needed
- [X] T026 [US3] Manually verify User Story 3's acceptance scenarios on-device (standing color excludes chords, inline spans, inert textsize/textfont), per `run`/`verify` skill (depends on T025) — verified on Pixel 10 Pro: standing red lyric color with chords staying blue, inline yellow background span, inline black text span, combined span, and the textsize/textfont line rendering at normal size/font

**Checkpoint**: User Stories 1, 2, and 3 all work independently.

---

## Phase 6: User Story 4 - Import a chart that reuses metadata inline (Priority: P4)

**Goal**: `%{key}`, `%{capo}`, etc. resolve to the current metadata value, inside both lyric and
annotation lines, tracking mid-file redeclarations.

**Independent Test**: Import a file with `{capo: 2}` and a later line containing
`Capo: %{capo} - use a capo!`; verify it renders as `Capo: 2 - use a capo!`.

### Tests for User Story 4 ⚠️

**Write these tests FIRST in `test/services/chordpro_parser_test.dart`; confirm they FAIL before implementation.**

- [X] T027 [P] [US4] Add failing tests for FR-021–FR-022: `%{...}` resolves to the most-recently-declared value at that point in the file (including after a mid-file redeclaration), resolves inside both lyric lines and annotation lines, and renders as an empty string when the named metadata is never declared

### Implementation for User Story 4

- [X] T028 [US4] Implement `%{...}` substitution as a text pre-pass applied to each line (both lyric and annotation), run before chord-bracket/inline-tag parsing, using the parser's running metadata state, in `lib/services/chordpro_parser.dart` (depends on T027, T010, T017, T022) — also required two bugfixes surfaced by the tests: `_directiveRe`'s value group had to become greedy (`.*`) to admit a `}`-containing `%{...}` inside a directive value, and separate `live*` (last-write) tracking variables had to be added alongside the existing first-write-wins metadata locals
- [X] T029 [US4] Run `flutter test test/services/chordpro_parser_test.dart` and confirm all US4 tests pass (depends on T028)
- [X] T030 [US4] Manually verify User Story 4's acceptance scenarios on-device (capo/key references, mid-file redeclaration, undeclared reference), per `run`/`verify` skill (depends on T029) — verified on Pixel 10 Pro: grey-bar annotation shows "Capo 2, key of G - quiet intro" with live values substituted, not literal `%{...}` text

**Checkpoint**: User Stories 1–4 all work independently.

---

## Phase 7: User Story 5 - Import a chart with app-specific custom directives (Priority: P5)

**Goal**: `{x_*:...}` directives are accepted during import with zero visible effect.

**Independent Test**: Import a file containing `{x_gigbook_note: internal use}` between two lyric
lines; verify import succeeds and no trace of the directive is visible anywhere.

### Tests for User Story 5 ⚠️

**Write this test FIRST in `test/services/chordpro_parser_test.dart`; confirm it currently passes or fails as expected before implementation.**

- [X] T031 [P] [US5] Add a regression test for FR-023: a file containing `{x_gigbook_note: internal use}` (and other `{x_*:...}` patterns) imports without error and produces no visible block/content from that directive

### Implementation for User Story 5

- [X] T032 [US5] Run `flutter test test/services/chordpro_parser_test.dart`; the existing default no-op switch branch is expected to already satisfy FR-023 — if the test fails, add an explicit `x_*` no-op case with a comment explaining why, in `lib/services/chordpro_parser.dart` (depends on T031) — test passed immediately against the existing default branch; no code change required
- [X] T033 [US5] Manually verify User Story 5's acceptance scenario on-device (custom directive has zero visible effect), per `run`/`verify` skill (depends on T032) — verified on Pixel 10 Pro: `{x_gigbook_note: ...}` produces no visible trace anywhere in the rendered song

**Checkpoint**: All five user stories are independently functional.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Whole-feature regression coverage and final validation

- [X] T034 [P] Add a whole-file regression test in `test/services/chordpro_parser_test.dart` combining every directive from FR-001–FR-025 in one fixture (mirroring the `quickstart.md` sample), asserting no exceptions and the full expected block/metadata structure (depends on T013, T018, T024, T029, T032)
- [X] T035 Run `flutter analyze` across all modified files (`lib/services/chordpro_parser.dart`, `lib/widgets/chordpro_renderer.dart`, `lib/services/import_service.dart`) and resolve any new warnings (depends on T034) — clean, no issues found
- [X] T036 Execute the full `quickstart.md` manual verification checklist end-to-end on-device, confirming SC-001 through SC-007 (depends on T035) — Completed on a Pixel 10 Pro (Android 16) via `flutter run` + adb: pushed the quickstart sample to Downloads, imported it through the app's real file-picker flow, and confirmed every bullet in `quickstart.md`'s checklist by inspecting the rendered song (subtitle/time chip, all four section types incl. raw tab text, all four annotation styles, standing red color excluding chords, inline yellow/black/combined spans, inert textsize/textfont, and zero visible trace of the `x_gigbook_note` directive). Test song and pushed file were deleted afterward to leave the user's real library untouched.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories; must leave the app compiling and behavior-unchanged
- **User Stories (Phase 3–7)**: All depend on Foundational phase completion
  - US1 → US2 → US3 → US4 → US5 is the recommended order (US4 depends on metadata/annotation work landed in US1/US2/US3; US5 has no real dependency and could move earlier if desired)
- **Polish (Phase 8)**: Depends on all five user stories being complete

### User Story Dependencies

- **US1 (P1)**: Depends only on Foundational — no dependency on other stories
- **US2 (P2)**: Depends only on Foundational — independently testable even if done before/without US1
- **US3 (P3)**: Depends only on Foundational — independently testable on its own
- **US4 (P4)**: Functionally reads metadata/annotation text produced by US1–US3's directive handling, so it is sequenced last among the metadata-relevant stories, but its own test/implementation pair is self-contained
- **US5 (P5)**: Depends only on Foundational — no real dependency on any other story

### Within Each User Story

- Tests written and failing before implementation (Constitution IV, parser only)
- Parser change before renderer change before manual on-device verification
- Story complete (tests green + manual verification) before moving to the next priority

### Parallel Opportunities

- T001 and T002 (Setup) can run in parallel
- Each story's test-writing task (T009, T016, T021, T027, T031) is marked `[P]` — safe to write in parallel with other stories' test tasks since they only add new `test()` blocks to the same file (resolve merge conflicts by appending, not overlapping)
- Implementation tasks within a story that touch different files could run in parallel, but every parser task in this feature touches `lib/services/chordpro_parser.dart`, so in practice most implementation tasks are sequential within a story

---

## Parallel Example: Test-writing across stories

```bash
# All of these only add new test() cases to the same file, so they can be drafted in parallel
# and merged, even though the file itself is shared:
Task: "Add failing tests for FR-001–FR-011 in test/services/chordpro_parser_test.dart"
Task: "Add failing tests for FR-012–FR-015 in test/services/chordpro_parser_test.dart"
Task: "Add failing tests for FR-016–FR-020 in test/services/chordpro_parser_test.dart"
Task: "Add failing tests for FR-021–FR-022 in test/services/chordpro_parser_test.dart"
Task: "Add a regression test for FR-023 in test/services/chordpro_parser_test.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks all stories, must stay behavior-neutral)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: run `flutter test`, then manually verify via `quickstart.md`
5. Ship if ready — metadata + section structure alone already fixes today's tab-content data loss and subtitle/artist conflation

### Incremental Delivery

1. Setup + Foundational → foundation ready, app unchanged
2. Add US1 → validate independently → MVP
3. Add US2 → validate independently
4. Add US3 → validate independently
5. Add US4 → validate independently
6. Add US5 → validate independently
7. Polish → whole-file regression test, `flutter analyze`, full `quickstart.md` pass

---

## Notes

- `[P]` tasks touch either a different file or only append independent `test()` blocks
- `[Story]` label maps every user-story-phase task back to spec.md's US1–US5
- Constitution IV requires parser tests written and failing before parser implementation in every
  story phase above — do not skip the "Tests" sub-phase or reorder it after implementation
- Renderer (widget) changes are validated manually on-device, not via widget tests, per the
  constitution's allowance for UI code
- Commit after each task or logical group
- Stop at any checkpoint to validate a story independently before continuing
