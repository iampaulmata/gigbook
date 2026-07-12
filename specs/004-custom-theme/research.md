# Research: Custom Theme Editor

## 1. How to add a 4th theme option alongside Flutter's `ThemeMode`

**Decision**: Introduce a separate app-level selection concept — `useCustomTheme: bool` plus `activeCustomThemeName: String?` — stored in `SettingsProvider` alongside the existing `themeMode`. `lib/app.dart`'s `MaterialApp` keeps its `theme`/`darkTheme`/`themeMode` trio, but when `useCustomTheme` is true, both `theme` and `darkTheme` are set to a single `ThemeData` built from the active custom theme's colors (via a new `AppTheme.custom(...)` factory), and `themeMode` is forced to `ThemeMode.light` so OS brightness switches can't flip between two identical custom `ThemeData` instances unpredictably.

**Rationale**: Flutter's `ThemeMode` enum (`system`/`light`/`dark`) is a framework type and cannot be extended with a fourth value. The existing app already separates "which mode" (`themeMode`) from "what the mode looks like" (`AppTheme.light`/`AppTheme.dark`), so adding a custom look as a third `ThemeData` source fits the constitution's requirement (Principle VI) that deviations be "implemented as an explicit theme variant rather than ad hoc per-widget styling" — the same pattern already used for the dark-mode stage-legibility overrides.

**Alternatives considered**:
- Subclassing or wrapping `ThemeMode` — rejected, not possible with a framework enum.
- A single `ThemeData? customOverride` field checked ad hoc at each color-consuming widget — rejected, violates Principle VI's "not ad hoc per-widget styling."

## 2. Color picker widget

**Decision**: Add `flex_color_picker` as a new dependency for the color-picker UI in the Custom Theme screen.

**Rationale**: The constitution requires new dependencies to be "justified by a capability the Flutter SDK ... cannot reasonably provide" and to "support both Android and iOS." Flutter's SDK has no built-in full color-picker widget (RGB/hex entry + visual swatch selection), and hand-rolling an accessible one is exactly the kind of premature-effort the Simplicity & YAGNI principle warns against when a well-maintained package already solves it. `flex_color_picker` is actively maintained, works on both target platforms, integrates cleanly with Material `ColorScheme`, and offers both a swatch picker and a hex/RGB input mode in one widget, avoiding the need for a second package for manual hex entry.

**Alternatives considered**:
- `flutter_colorpicker` — comparable feature set, also viable; `flex_color_picker` was preferred for its more active maintenance cadence and built-in wheel + hex input in a single widget.
- Hand-built HSV wheel — rejected as unjustified complexity for a single-screen feature (YAGNI).

## 3. Contrast (readability) validation

**Decision**: Implement WCAG relative-luminance contrast ratio as a small, pure, synchronous Dart utility function (no new dependency), used to check each of the four text-bearing color pairs called out in FR-018 against the 4.5:1 WCAG AA threshold (per spec Assumptions).

**Rationale**: The formula (relative luminance from sRGB channels, then `(L1 + 0.05) / (L2 + 0.05)`) is small and self-contained — pulling in a package for it would be unjustified per Simplicity & YAGNI. As pure logic with no UI in the loop, it falls under Principle IV (Test-First for Core Logic) and needs unit tests written before the implementation.

**Alternatives considered**: A contrast-checking package — rejected, unnecessary dependency for ~15 lines of math.

## 4. Persistence of saved custom themes

**Decision**: Store the user's saved custom themes as a single JSON-encoded list under one `shared_preferences` key (e.g. `custom_themes`), plus a `active_custom_theme_name` key for which one is currently applied — extending `SettingsProvider`'s existing `shared_preferences`-backed pattern rather than adding a table to the `sqflite` database.

**Rationale**: The constitution reserves `sqflite` for "structured song/setlist data" and `shared_preferences` for "user settings only (theme, font size, scroll speed, chord visibility)" — theme selection is explicitly named as a `shared_preferences` concern already. Saved custom themes are small (a name + five hex colors each) and low in expected count (single digits to low dozens per user), well within comfortable `shared_preferences` usage, so adding a second persistence mechanism or a new `sqflite` table would violate "Do not introduce a second persistence mechanism for data that already fits [an existing] model" in spirit — here the existing model that fits is the settings-preferences one, not the relational one, since there are no cross-entity relationships (a theme doesn't reference songs, setlists, or other themes).

**Alternatives considered**:
- New `sqflite` table — rejected; adds schema/migration overhead for data with no relational structure, contrary to Simplicity & YAGNI.
- `Hive`/`Isar` — explicitly disallowed by the constitution's Technology Constraints without a documented exception.

## 5. JSON export/import format and flow

**Decision**: Mirror the existing setlist-sharing pattern (`lib/services/setlist_json.dart` + `lib/services/setlist_share_service.dart`) exactly: a `type`/`version` envelope (`gigbook-theme` / `1`), a dedicated `parseThemeJson()` function with a matching `ThemeFormatException`, export via `share_plus`'s `SharePlus.instance.share(ShareParams(files: [...]))` writing a temp `.gigbook-theme.json` file, and import via `file_picker`'s `FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json'])` — i.e., import is a user-initiated "pick a file I already have" action, not an OS share-target intent receiver requiring manifest changes.

**Rationale**: This is a direct precedent already in the codebase for "shareable using standard Google sharing options" (resolved in the spec's Assumptions as the device's standard share sheet). Reusing the exact pattern keeps the codebase's JSON-interchange approach consistent (Principle VI's spirit of one established idiom over introducing a second), and confirms the "reject as incompatible" decision from spec clarification is directly expressible via the same `type`/`version` check `parseSetlistJson` already performs.

**Alternatives considered**:
- An Android intent-filter share-target receiver (app registers to receive incoming shares directly) — rejected as unnecessary scope beyond what the spec or existing pattern calls for, and inconsistent with how setlists are already imported.

## 6. Destructive-action confirmation for theme deletion

**Decision**: Deleting a saved custom theme (FR-015) requires an explicit confirmation dialog, consistent with how song/setlist deletion already works.

**Rationale**: Constitution Principle III states destructive actions "MUST require explicit confirmation." Theme deletion is destructive (loses saved color data) and falls under this existing rule without needing a spec change — it's an application of an already-established app-wide pattern, not a new design decision.

**Alternatives considered**: None — this is a direct constitutional requirement, not a judgment call.
