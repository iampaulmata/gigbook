# Contract: `.gigbook-theme.json` file format

This is the shareable export/import contract for a single custom theme (FR-008, FR-012, FR-013), mirroring the existing `.gigbook-setlist.json` contract in shape and validation posture (`lib/services/setlist_json.dart`).

## Shape

```json
{
  "type": "gigbook-theme",
  "version": 1,
  "name": "Stage Lighting",
  "colors": {
    "background": "#0D1117",
    "text": "#E6EDF3",
    "chord": "#58A6FF",
    "sectionHeader": "#F0883E",
    "comment": "#8B949E"
  }
}
```

## Field rules

| Field | Required | Validation |
|---|---|---|
| `type` | Yes | MUST equal the literal string `gigbook-theme`. Any other value (or missing) → reject with "That file is not a GigBook theme." |
| `version` | Yes | MUST equal `1`. A higher/unrecognized version → reject with "This theme was created by a newer version of GigBook. Update the app to import it." (per FR-014, resolving the version-mismatch clarification). |
| `name` | Yes | Non-empty string after trimming. Empty/missing → default to `"Imported theme"`, consistent with `parseSetlistJson`'s fallback behavior for setlist names. |
| `colors.background` | Yes | `#RRGGBB` hex string. |
| `colors.text` | Yes | `#RRGGBB` hex string. |
| `colors.chord` | Yes | `#RRGGBB` hex string. |
| `colors.sectionHeader` | Yes | `#RRGGBB` hex string. |
| `colors.comment` | Yes | `#RRGGBB` hex string. |

Any missing/malformed color field, or a `colors` value that isn't a well-formed hex string, is rejected the same way malformed JSON is (FR-014) — no partial theme is created.

## Error conditions → user-facing behavior

| Condition | Behavior |
|---|---|
| File is not valid JSON | Reject: "That file is not a valid GigBook theme." |
| `type` missing or wrong | Reject: "That file is not a GigBook theme." |
| `version` newer than `1` | Reject: "This theme was created by a newer version of GigBook. Update the app to import it." |
| Any `colors.*` field missing/malformed | Reject: "That file is not a valid GigBook theme." |
| `name` collides with an existing saved theme | Do NOT reject the file — prompt the user to choose a different name before completing the import (FR-019). This is a UI-level prompt, not a parse-level rejection. |

## Producing (export)

- Written to a temp file named `<sanitized-name>.gigbook-theme.json` (same sanitization pattern as `SetlistShareService`: strip characters outside `[\w\-. ]`).
- Shared via `SharePlus.instance.share(ShareParams(files: [...], text: 'GigBook theme: <name>'))`.

## Consuming (import)

- Selected via `FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json'])` — a user-initiated local file pick, not an OS share-target intent receiver.
- Parsed by a dedicated `parseThemeJson(String content)` function (mirroring `parseSetlistJson`), throwing a `ThemeFormatException` on any rejection condition above.
