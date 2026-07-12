# Quickstart: Custom Theme Editor

Manual, on-device validation steps proving the feature works end-to-end. Run via the project's `run`/`verify` skills. See `spec.md` for the acceptance scenarios this walks through, `contracts/theme-json-schema.md` for the file format, and `data-model.md` for entity details.

## Prerequisites

- App built and running on a device/emulator (`flutter run`).
- At least one song imported (for the live preview and for confirming the applied theme in the actual song viewer, not just the preview).

## Scenario 1 — Create, preview, and apply a custom theme (US1)

1. Open Settings → Appearance → **Custom Theme**.
2. Confirm the screen shows a color picker for each of: background, text, chords, section headers, comments — and a live preview panel with sample lyrics/chords/section header/comment.
3. Change the background color. **Expect**: preview updates immediately, no save required.
4. Pick a text color nearly identical to the background color and attempt to save. **Expect**: save is blocked, with the failing color pair(s) indicated (FR-018).
5. Pick a readable text color, name the theme (e.g. "Stage"), and save. **Expect**: theme is persisted.
6. Go to Settings → Appearance → Theme (the main picker). **Expect**: a "Custom" option is now present alongside System/Light/Dark.
7. Select "Custom". **Expect**: the song viewer and app chrome immediately reflect the saved theme's colors.

## Scenario 2 — Manage multiple saved themes (US2)

1. Return to the Custom Theme screen and create a second theme (e.g. "Practice Room") with different colors.
2. Open the dropdown selector. **Expect**: both "Stage" and "Practice Room" are listed.
3. Select "Stage" from the dropdown. **Expect**: color pickers and preview update to match "Stage"'s saved colors.
4. Change a color and save under the same name ("Stage"). **Expect**: "Stage" is updated in place; "Practice Room" is untouched.
5. Change a color and save under a new name ("Stage v2"). **Expect**: a third theme now exists; "Stage" is unchanged.

## Scenario 3 — Share and import a theme (US3)

1. From the Custom Theme screen, share "Stage". **Expect**: the device's standard share sheet opens with a `.gigbook-theme.json` file attached.
2. Save that file locally (e.g. via "Save to device" from the share sheet, or send to a second device/account).
3. On the receiving side, use the import action and pick the saved `.gigbook-theme.json` file.
   - If the name doesn't collide: **Expect** it's added directly to the saved themes list.
   - If the name collides with an existing theme: **Expect** a rename prompt before import completes (FR-019).
4. Attempt to import a non-JSON file (e.g. a `.txt` file). **Expect**: rejected with a clear error message, no theme added (FR-014).

## Scenario 4 — Deletion and fallback

1. Apply a custom theme (select "Custom" with it active).
2. Delete that theme from the Custom Theme screen. **Expect**: a confirmation prompt appears first (destructive action).
3. Confirm deletion. **Expect**: the app falls back to the System theme rather than showing a broken/blank appearance (FR-016).

## Pass/fail

All six numbered expectations above pass on-device (Android primary target; iPad secondary target if available) with `flutter analyze` clean and the new `parseThemeJson`/contrast-check unit tests green.
