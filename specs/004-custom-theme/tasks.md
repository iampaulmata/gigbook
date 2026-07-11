---

description: "Task list template for feature implementation"
---

# Tasks: Custom Theme Editor

**Input**: Design documents from `/specs/004-custom-theme/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/theme-json-schema.md, quickstart.md

**Tests**: Constitution Principle IV (Test-First for Core Logic, NON-NEGOTIABLE) requires tests for non-UI logic (`contrast.dart`, `theme_json.dart`) written and failing before their implementation. The Custom Theme screen and picker dialog are UI code, verified via `quickstart.md` manual on-device validation instead of widget tests, per the project's established `run`/`verify` pattern.

**Organization**: Tasks are grouped by user story (US1/US2/US3, matching spec.md priorities P1/P2/P3) to enable independent implementation and testing of each.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an incomplete task)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- File paths are exact, per plan.md's Project Structure

---

## Phase 1: Setup

**Purpose**: Add the one new dependency this feature needs

- [X] T001 Add `flex_color_picker` to `pubspec.yaml` dependencies (research.md §2) and run `flutter pub get`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared model, validation logic, and persistence layer that every user story builds on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T002 [P] Create `CustomTheme` model in `lib/models/custom_theme.dart` — fields `name`, `backgroundColor`, `textColor`, `chordColor`, `sectionHeaderColor`, `commentColor`, `formatVersion` (data-model.md), with `toJson()`/`fromJson()` using `#RRGGBB` hex string colors
- [X] T003 [P] Write contrast-ratio utility tests in `test/services/contrast_test.dart` — WCAG relative-luminance formula, 4.5:1 AA threshold (spec Assumptions), covering a passing pair, a failing pair, and boundary cases. Tests MUST fail (no implementation exists yet) per Constitution Principle IV
- [X] T004 Implement the contrast-ratio utility in `lib/services/contrast.dart` to make T003 pass (depends on T003)
- [X] T005 [P] Extend `SettingsProvider` in `lib/providers/settings_provider.dart`: add `useCustomTheme` (bool), `activeCustomThemeName` (String?), and CRUD for the saved-theme list (`getCustomThemes()`, `saveCustomTheme()`, `deleteCustomTheme()` — the latter MUST clear `activeCustomThemeName`/`useCustomTheme` and fall back to `ThemeMode.system` when deleting the currently-active theme (FR-016) — `setActiveCustomTheme()`, `setUseCustomTheme()`), persisted as a JSON-encoded list via `shared_preferences` keys `custom_themes` / `active_custom_theme_name` / `use_custom_theme` (research.md §4, depends on T002)

**Checkpoint**: Foundation ready — user story implementation can now begin

---

## Phase 3: User Story 1 - Create and apply a custom theme (Priority: P1) 🎯 MVP

**Goal**: User opens the Custom Theme screen, picks colors for all five roles, sees a live preview, is blocked from saving an unreadable combination, saves under a name, and applies it app-wide via the main theme picker's new "Custom" option.

**Independent Test**: Open the Custom Theme screen, change each color, confirm the preview updates immediately, save under a name, select "Custom" from the main theme picker, and confirm the song viewer and app chrome render with the saved colors.

### Implementation for User Story 1

- [X] T006 [P] [US1] Create the live preview widget in `lib/widgets/theme_preview.dart` — renders sample title, lyrics, a chord, a section header, and a comment/annotation using a supplied `CustomTheme`'s colors
- [X] T007 [P] [US1] Add an `AppTheme.custom(CustomTheme)` `ThemeData` factory in `lib/theme/app_theme.dart` (research.md §1), reusing the app's existing Material 3 `ColorScheme` construction pattern
- [X] T008 [US1] Wire `useCustomTheme` into `lib/app.dart`'s `MaterialApp`: when true, set both `theme` and `darkTheme` to `AppTheme.custom(...)` for the active theme and force `themeMode: ThemeMode.light` (research.md §1) (depends on T005, T007)
- [X] T009 [US1] Create the Custom Theme screen scaffold in `lib/screens/custom_theme_screen.dart` — five `flex_color_picker` controls (background, text, chord, section header, comment) bound to local editable `CustomTheme` state, feeding `ThemePreview` for live updates (depends on T001, T002, T006)
- [X] T010 [US1] Implement the save flow in `lib/screens/custom_theme_screen.dart`: name input, contrast validation via `lib/services/contrast.dart` against all four text-bearing pairs, blocking save and indicating the failing pair(s) when below threshold (FR-018), otherwise persisting via `SettingsProvider.saveCustomTheme` (depends on T004, T005, T009)
- [X] T011 [US1] Add a "Custom Theme" entry point under the Appearance section in `lib/screens/settings_screen.dart`, navigating to `CustomThemeScreen` (FR-001) (depends on T009)
- [X] T012 [US1] Extend the main theme picker dialog in `lib/screens/settings_screen.dart` with a "Custom" option (FR-009): with no saved themes it routes to `CustomThemeScreen` (FR-011); otherwise it applies the most recently selected/saved custom theme via `SettingsProvider.setUseCustomTheme` (FR-010) (depends on T005, T008, T011)

**Checkpoint**: User Story 1 is fully functional and independently testable (MVP)

---

## Phase 4: User Story 2 - Manage and switch between multiple saved themes (Priority: P2)

**Goal**: User recalls any saved theme via a dropdown, updates it in place or saves it under a new name, and deletes themes they no longer want.

**Independent Test**: Save two differently-named custom themes, use the dropdown to switch between them, and confirm the editor/preview update to match each recalled theme's saved colors.

### Implementation for User Story 2

- [X] T013 [US2] Add a dropdown selector to `lib/screens/custom_theme_screen.dart` listing `SettingsProvider.getCustomThemes()`, recalling the selected theme's colors into the editable state and preview (FR-006, FR-007) (depends on T010)
- [X] T014 [US2] Implement save-as-update vs. save-as-new in `lib/screens/custom_theme_screen.dart`'s save flow: saving under the currently-loaded name updates that theme in place; saving under a different name creates a new one (FR-005) (depends on T013)
- [X] T015 [US2] Implement a name-collision confirmation prompt in `lib/screens/custom_theme_screen.dart` for manual saves that match an existing theme's name (FR-017); structure it for reuse by User Story 3's import flow (depends on T014)
- [X] T016 [US2] Add a delete action with confirmation dialog for saved themes in `lib/screens/custom_theme_screen.dart` (FR-015), calling `SettingsProvider.deleteCustomTheme` (whose fallback behavior was implemented in T005) (depends on T013)

**Checkpoint**: User Stories 1 AND 2 both work independently

---

## Phase 5: User Story 3 - Share a custom theme with another user (Priority: P3)

**Goal**: User shares a saved theme as a `.gigbook-theme.json` file via the standard share sheet; a recipient imports it, with collisions and invalid/incompatible files handled per the JSON contract.

**Independent Test**: Save a custom theme, invoke the share action, confirm the system share sheet opens with a JSON file attached, then import that file (on a second device/account) and confirm the theme appears in the saved list with matching colors.

### Implementation for User Story 3

- [X] T017 [P] [US3] Write theme JSON parsing tests in `test/services/theme_json_test.dart` covering: a valid file, malformed JSON, wrong/missing `type`, a newer/unrecognized `version`, and missing/malformed `colors.*` fields (contracts/theme-json-schema.md). Tests MUST fail before implementation per Constitution Principle IV
- [X] T018 [US3] Implement `lib/services/theme_json.dart` — `parseThemeJson()` and `ThemeFormatException`, per contracts/theme-json-schema.md, to make T017 pass (depends on T017)
- [X] T019 [US3] Implement `lib/services/theme_share_service.dart` — export via `share_plus` (write a temp `<name>.gigbook-theme.json`, `SharePlus.instance.share`) and import via `file_picker` (`pickFiles(type: FileType.custom, allowedExtensions: ['json'])` + `parseThemeJson`), mirroring `setlist_share_service.dart` exactly (depends on T002, T018)
- [X] T020 [US3] Add a "Share" action per saved theme in `lib/screens/custom_theme_screen.dart` invoking `ThemeShareService.share` (FR-012) (depends on T013, T019)
- [ ] T021 [US3] Add an "Import" action in `lib/screens/custom_theme_screen.dart` invoking `ThemeShareService`'s import, reusing the name-collision rename prompt from T015 on a name match (FR-013, FR-019) and surfacing `ThemeFormatException` messages as clear, user-facing errors (FR-014) (depends on T015, T019)

**Checkpoint**: All three user stories are independently functional

---

## Phase 6: Polish & Cross-Cutting Concerns

- [ ] T022 [P] Run `flutter analyze` and resolve any new warnings across all files touched by this feature (constitution quality gate)
- [ ] T023 Run the `quickstart.md` validation scenarios 1–4 on-device (Android primary target; iPad secondary target if available)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup (T001, for `flex_color_picker` to exist when later phases need it) — BLOCKS all user stories
- **User Stories (Phase 3–5)**: All depend on Foundational (Phase 2) completion
  - US1 has no dependency on US2 or US3
  - US2 builds on US1's screen and save flow (same file, `custom_theme_screen.dart`) — implement after US1
  - US3 builds on US2's collision-prompt component and US1's screen — implement after US2
  - This feature's stories share one screen file, so — unlike fully decoupled stories — US2/US3 are best done sequentially after US1 rather than in parallel by separate people
- **Polish (Phase 6)**: Depends on all desired user stories being complete

### Within Each User Story

- Foundational data/logic (model, contrast utility, provider CRUD) before any UI task that consumes it
- Screen scaffold before the save flow, dropdown, delete, share, or import actions that extend it
- Tests for `contrast.dart` and `theme_json.dart` written and failing before their implementations (Constitution Principle IV)

### Parallel Opportunities

- T002 (model), T003 (contrast tests), and T005 (provider) can run in parallel within Phase 2 — different files, and T005's only dependency (T002) doesn't block T003
- T006 (preview widget) and T007 (`AppTheme.custom`) can run in parallel within Phase 3 — different files, no shared dependency
- T017 (theme JSON tests) can start in parallel with Phase 4 (US2) work, since it touches an unrelated file and has no dependency on US2

---

## Parallel Example: Phase 2 (Foundational)

```bash
Task: "Create CustomTheme model in lib/models/custom_theme.dart"
Task: "Write contrast-ratio utility tests in test/services/contrast_test.dart"
Task: "Extend SettingsProvider in lib/providers/settings_provider.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Run quickstart.md Scenario 1 on-device
5. This is a usable, demoable MVP — one custom theme, creatable and applicable

### Incremental Delivery

1. Setup + Foundational → foundation ready
2. Add User Story 1 → validate with quickstart Scenario 1 → MVP
3. Add User Story 2 → validate with quickstart Scenario 2 (multi-theme management)
4. Add User Story 3 → validate with quickstart Scenario 3 (share/import)
5. Polish: `flutter analyze` clean, full quickstart pass (Scenario 4 covers deletion/fallback)

---

## Notes

- [P] tasks touch different files with no incomplete-task dependency
- This feature's three stories share `lib/screens/custom_theme_screen.dart` as a common file, so most cross-story parallelism is limited — sequence US1 → US2 → US3 for a solo implementer
- Commit after each task or logical group
- Stop at each checkpoint to validate that story independently before moving on
