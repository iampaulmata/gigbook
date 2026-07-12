# Data Model: Custom Theme Editor

## CustomTheme

A user-created named set of colors, corresponding to the spec's "Custom Theme" entity.

| Field | Type | Required | Notes |
|---|---|---|---|
| `name` | String | Yes | Unique among the user's saved themes (FR-017). Trimmed, non-empty. |
| `backgroundColor` | Color (stored as `#RRGGBB` hex string) | Yes | App/song-viewer background. |
| `textColor` | Color (hex) | Yes | Main lyric/text color. |
| `chordColor` | Color (hex) | Yes | Chord color; also drives primary/accent-colored chrome elements, consistent with the existing renderer's reuse of `colorScheme.primary` for chords. |
| `sectionHeaderColor` | Color (hex) | Yes | Section header color (e.g. Verse/Chorus labels). |
| `commentColor` | Color (hex) | Yes | Comment/annotation color; the renderer derives its four comment sub-styles (grey-bar, boxed, highlight background/foreground) from this single color at render time, per spec Assumptions — no separate fields needed. |
| `formatVersion` | int | Yes | Set to `1`. Used to reject themes from incompatible future versions (FR-014, FR-019 decision). |

**Validation rules**:
- All five colors MUST individually be valid `#RRGGBB` (or `#AARRGGBB`) hex values.
- Contrast between `backgroundColor` and each of `textColor`, `chordColor`, `sectionHeaderColor`, `commentColor` MUST be ≥ 4.5:1 (WCAG AA, per spec Assumptions) before a theme can be saved (FR-018). This is enforced at save time in the editor, not at parse time on import — an imported theme that fails contrast is still accepted as-is (its creator already passed the check when they saved it; re-deriving trust in a peer's saved theme is out of scope).
- `name` MUST be unique within the Saved Theme Library; a collision during manual save or import triggers the rename-prompt flow (FR-017, FR-019) rather than a silent overwrite or silent rename.

**Lifecycle**: created (via editor save) → optionally updated (re-saved under the same name) → optionally applied (selected as the active custom theme) → optionally shared (exported to JSON) → optionally deleted (requires confirmation, see research.md §6). An imported theme enters the lifecycle at "created," as if the recipient had built it themselves.

## Saved Theme Library

The collection of all `CustomTheme` entries a user has on their device (created locally or imported).

| Field | Type | Notes |
|---|---|---|
| `themes` | List\<CustomTheme\> | Source for the Custom Theme screen's dropdown selector (FR-006) and the main theme picker's "Custom" option (FR-009). |
| `activeThemeName` | String? | Name of the `CustomTheme` currently applied when the user has selected "Custom" in the main picker (FR-010). `null` if no custom theme has ever been saved (FR-011). |

**State transitions**:
- `activeThemeName` is set when the user selects "Custom" in the main picker (defaulting to the most recently saved/selected custom theme) or explicitly picks a different saved theme.
- If the `CustomTheme` referenced by `activeThemeName` is deleted, `activeThemeName` MUST be cleared and the app MUST fall back to `ThemeMode.system` (FR-016).

## Persistence mapping (see research.md §4)

- `themes` → `shared_preferences` key `custom_themes`, stored as a JSON-encoded array of `CustomTheme` objects (same shape as the shareable file format, minus the outer `type` envelope — see `contracts/theme-json-schema.md`).
- `activeThemeName` → `shared_preferences` key `active_custom_theme_name`.
- `useCustomTheme` (whether "Custom" is the selected main-picker option, distinct from `ThemeMode`) → `shared_preferences` key `use_custom_theme`, alongside the existing `theme_mode` key in `SettingsProvider`.
