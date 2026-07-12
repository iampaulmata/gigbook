# Implementation Plan: Custom Theme Editor

**Branch**: `004-custom-theme` | **Date**: 2026-07-10 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/004-custom-theme/spec.md`

## Summary

Add a per-user "Custom" app theme: a new Custom Theme screen (reached from Settings → Appearance) where the user picks colors for five roles (background, text, chords, section headers, comments) via a color-picker widget, sees a live preview, and saves the result as a named theme enforcing a minimum WCAG AA contrast between background and each text-bearing color. Saved themes are recalled via a dropdown, selectable app-wide as a "Custom" option alongside the existing System/Light/Dark picker, and exportable/importable as `.gigbook-theme.json` files through the device's standard share sheet — mirroring the app's existing setlist JSON-sharing pattern exactly.

## Technical Context

**Language/Version**: Dart ^3.9.2 (Flutter 3.35, stable channel)

**Primary Dependencies**: `flutter`, `provider` (state management), `shared_preferences` (theme persistence), `share_plus` (export), `file_picker` (import) — all already in `pubspec.yaml`. New: `flex_color_picker` for the color-picker UI (see research.md §2).

**Storage**: `shared_preferences`, extending the existing settings-persistence pattern (JSON-encoded list of saved themes under one key; no new `sqflite` table — see research.md §4).

**Testing**: `flutter_test`. Unit tests required first (Constitution Principle IV) for the non-UI logic: `parseThemeJson`/`ThemeFormatException` validation and the WCAG contrast-ratio utility. The Custom Theme screen and picker dialog are verified via manual on-device testing per `quickstart.md`, consistent with the project's `run`/`verify` skills.

**Target Platform**: Android (primary), iPad/iOS (secondary) — per constitution Technology Constraints.

**Project Type**: Mobile app (single Flutter project; existing `lib/` layout extended, no new top-level structure).

**Performance Goals**: Color-picker changes reflect in the live preview within a single frame (no perceptible lag), matching SC-002.

**Constraints**: Theme creation, saving, switching, and applying MUST work fully offline (Constitution Principle I); only the share/import step touches the OS share sheet or file picker, both of which already work offline-adjacent the same way setlist sharing does.

**Scale/Scope**: Single-user, on-device data; expected saved-theme count is single digits to low dozens per user — no multi-tenant or server-side concerns.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|---|---|---|
| I. Offline-First & Local Data Ownership | PASS | Create/save/switch/apply require no network. Share/import are opt-in and additive, using the same OS share sheet / file picker pattern already accepted for setlists. |
| II. ChordPro Standard Fidelity | N/A | Feature does not touch the ChordPro parser. |
| III. Stage-Ready UX | PASS | FR-018's mandatory contrast check directly serves on-stage legibility. Theme deletion (destructive) requires confirmation, consistent with existing song/setlist deletion behavior (research.md §6). Feature is reached through Settings, not a stage-critical screen, so no new taps are added to the performance-critical path. |
| IV. Test-First for Core Logic | PASS (planned) | `parseThemeJson` validation and the contrast-ratio utility are non-UI logic requiring tests written first; enforced in tasks.md ordering. |
| V. Simplicity & YAGNI | PASS | Reuses `shared_preferences` instead of a new persistence layer; reuses the existing setlist JSON/share pattern instead of inventing a new one; only new dependency (`flex_color_picker`) is justified by a capability the SDK lacks. |
| VI. Flutter & Material Idioms | PASS | New screen/widgets follow existing `lib/screens`/`lib/widgets` conventions; state via `ChangeNotifier`/`provider` (extending `SettingsProvider`, no new state-management paradigm); custom theme implemented as an explicit `AppTheme.custom(...)` `ThemeData` variant, matching the existing light/dark pattern. |

No violations — Complexity Tracking is not needed.

**Post-Phase 1 re-check**: Data model (JSON-list-in-`shared_preferences`, no relational structure) and the JSON contract (mirrors `setlist_json.dart` exactly) confirm the above holds; no new violations introduced by the detailed design.

## Project Structure

### Documentation (this feature)

```text
specs/004-custom-theme/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
│   └── theme-json-schema.md
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

Single Flutter mobile app; this feature extends the existing `lib/` layout with no new top-level directories.

```text
lib/
├── models/
│   └── custom_theme.dart          # NEW — CustomTheme data class (data-model.md)
├── providers/
│   └── settings_provider.dart     # MODIFIED — add useCustomTheme, activeCustomThemeName,
│                                   #   saved-theme list, and their shared_preferences I/O
├── screens/
│   ├── settings_screen.dart       # MODIFIED — add "Custom Theme" entry under Appearance;
│                                   #   extend theme picker dialog with a "Custom" option
│   └── custom_theme_screen.dart   # NEW — color pickers, live preview, save/dropdown/share/import UI
├── services/
│   ├── theme_json.dart            # NEW — parseThemeJson()/ThemeFormatException, mirrors setlist_json.dart
│   ├── theme_share_service.dart   # NEW — export/import via share_plus + file_picker, mirrors
│                                   #   setlist_share_service.dart
│   └── contrast.dart              # NEW — WCAG contrast-ratio utility (research.md §3)
├── theme/
│   └── app_theme.dart             # MODIFIED — add AppTheme.custom(CustomTheme) ThemeData factory
├── widgets/
│   └── theme_preview.dart         # NEW — sample lyrics/chord/section-header/comment preview,
│                                   #   reusable by the Custom Theme screen
└── app.dart                       # MODIFIED — resolve theme/darkTheme/themeMode against
                                    #   useCustomTheme (research.md §1)

test/
├── services/
│   ├── theme_json_test.dart       # NEW — written before theme_json.dart per Principle IV
│   └── contrast_test.dart         # NEW — written before contrast.dart per Principle IV
```

**Structure Decision**: Single Flutter project (no frontend/backend or API split — this is a local, offline-first mobile app). All new code follows the existing `lib/models` / `lib/providers` / `lib/screens` / `lib/services` / `lib/theme` / `lib/widgets` convention already established in this codebase, and new non-UI logic (`theme_json.dart`, `contrast.dart`) gets unit tests under `test/services/` following the existing `chordpro_parser_test.dart` precedent.

## Complexity Tracking

Not applicable — the Constitution Check above shows no violations.
