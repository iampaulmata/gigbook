# Feature Specification: Custom Theme Editor

**Feature Branch**: `004-custom-theme`

**Created**: 2026-07-10

**Status**: Draft

**Input**: User description: "As a user, I want the ability to customize my theme for the app to include the background color, main font color, primary comment color, etc. This should be accessible through the settings menu as a sub-menu. This theme setting should be selectable through the current theme picker as a "Custom" option. In the custom screen, the user can select their colors from a color picker for each editable color and there should be a preview of each element visible to the user so they know what it will look like before applying the changes. The user should also be able to save the theme with a custom name and recall that theme - or any other saved theme - from the custom theme screen using a drop down selector. The themes should be saved in JSON format and should be shareable to other users using the standard Google sharing options."

## Clarifications

### Session 2026-07-10

- Q: How should the system handle a custom color combination that makes text unreadable (e.g., background and lyric text set to nearly the same color)? → A: Block save until contrast meets a minimum
- Q: How should a naming collision on import be resolved (an imported theme's name matches an existing saved theme)? → A: Prompt the user to rename before completing the import — same conflict-resolution pattern as the manual save flow (FR-017)
- Q: What happens when a recipient imports a shared theme JSON file created by a newer app version, containing fields their app doesn't recognize? → A: Reject as incompatible with a clear message, same as any other invalid file

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Create and apply a custom theme (Priority: P1)

A user opens Settings, navigates to a new "Custom Theme" screen, chooses colors for the app's background, lyric text, chords, section headers, and comments/annotations, sees a live preview of a sample song reflecting those choices, saves the theme under a name of their choosing, and applies it so the whole app now uses those colors.

**Why this priority**: This is the core capability the feature exists to deliver. Without it, none of the other stories (recalling themes, sharing themes) have anything to operate on.

**Independent Test**: Can be fully tested by opening the Custom Theme screen, changing each color, confirming the preview updates immediately, saving under a name, selecting "Custom" from the main theme picker, and confirming the song viewer and app chrome render with the saved colors.

**Acceptance Scenarios**:

1. **Given** the user is on the Settings screen, **When** they tap "Custom Theme" under Appearance, **Then** the Custom Theme screen opens showing a color picker control for each editable element and a live preview.
2. **Given** the user is on the Custom Theme screen, **When** they pick a new color for an element (e.g., background), **Then** the preview updates immediately to reflect that color without requiring the user to save first.
3. **Given** the user has chosen colors for all editable elements, **When** they enter a name and save, **Then** the theme is persisted and appears as a selectable saved theme.
4. **Given** a custom theme has been saved, **When** the user opens the app's main theme picker, **Then** a "Custom" option is available alongside the existing System/Light/Dark options, and selecting it applies the saved custom theme's colors throughout the app.
5. **Given** the user has chosen a text/background color pair that falls below the minimum readability contrast, **When** they attempt to save, **Then** the save is blocked and the offending color pair(s) are clearly indicated so the user can adjust them.

---

### User Story 2 - Manage and switch between multiple saved themes (Priority: P2)

A user who has already created one or more custom themes returns to the Custom Theme screen, uses a dropdown selector to recall a previously saved theme (loading its colors into the editor and preview), makes further edits or saves it as a new theme, and switches which saved theme is currently active.

**Why this priority**: Depends on User Story 1 existing (there must be a save mechanism first), but delivers significant standalone value by letting users maintain a personal library of looks (e.g., a high-contrast "Stage" look and a low-glare "Practice Room" look) instead of only ever having one custom theme.

**Independent Test**: Can be fully tested by saving two differently-named custom themes, using the dropdown to switch between them on the Custom Theme screen, and confirming the preview and editor fields update to match the recalled theme's saved colors each time.

**Acceptance Scenarios**:

1. **Given** the user has two or more saved custom themes, **When** they open the dropdown selector on the Custom Theme screen, **Then** all saved theme names are listed.
2. **Given** the dropdown is open, **When** the user selects a different saved theme, **Then** the color pickers and preview update to reflect that theme's saved colors.
3. **Given** a saved theme is loaded into the editor, **When** the user changes a color and saves again under the same name, **Then** the existing saved theme is updated with the new colors.
4. **Given** the user is editing a recalled theme, **When** they save it under a new, different name, **Then** a new saved theme is created and the original theme remains unchanged.

---

### User Story 3 - Share a custom theme with another user (Priority: P3)

A user who has created a custom theme they like shares it from the Custom Theme screen using the device's standard share sheet (e.g., to send via Gmail, Google Drive, Messages, or any other installed sharing target). A recipient who receives the shared file can import it into their own copy of the app, where it appears as a new saved custom theme they can select and apply.

**Why this priority**: Builds on Stories 1 and 2 (there must be saved themes to share) and extends the feature's value beyond a single device, but the app is fully usable for one person without it.

**Independent Test**: Can be fully tested by saving a custom theme, invoking the share action, confirming the system share sheet opens with a JSON file attached, and — on a second device or account — importing that file and confirming the theme appears in the saved themes list with matching colors.

**Acceptance Scenarios**:

1. **Given** a saved custom theme, **When** the user taps "Share" for that theme, **Then** the device's standard share sheet opens with a JSON file representing the theme attached.
2. **Given** a user receives a shared theme JSON file whose name does not collide with an existing saved theme, **When** they open/import it in the app, **Then** it is added directly to their list of saved custom themes under its original name.
3. **Given** a user receives a shared theme JSON file whose name matches an existing saved theme, **When** they open/import it in the app, **Then** the system prompts them to choose a different name before completing the import, rather than silently overwriting or silently renaming the existing theme.
4. **Given** a user attempts to import a file that is not a valid theme JSON, **When** the import is attempted, **Then** the app rejects it with a clear error message and no theme is added.

---

### Edge Cases

- What happens when the user selects "Custom" in the main theme picker but has never created a saved custom theme? (System should not offer an empty/broken "Custom" state — see FR-011.)
- What happens when the user deletes the custom theme that is currently applied as the active app theme?
- What happens when the user tries to save a theme using a name that already exists among their saved themes?
- When an imported theme file's name collides with an existing saved theme's name, the system prompts the user to choose a different name before completing the import (see FR-019) — the same explicit-confirmation pattern used for same-name conflicts during manual save (FR-017).
- If the user picks a text/background color combination that falls below the minimum readability contrast, the system blocks saving and prompts the user to adjust colors until the minimum is met (see FR-018).
- What happens when the user backs out of the Custom Theme screen after changing colors but before saving?
- A shared theme JSON file created by a newer, incompatible app version is rejected on import with a clear message, the same as any other invalid file (see FR-014) — no partial import is attempted.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The Settings screen MUST provide a "Custom Theme" entry point, under the existing Appearance section, that opens a dedicated Custom Theme screen.
- **FR-002**: The Custom Theme screen MUST provide an independent color picker for each of the following elements: background color, main text/lyric color, chord color, section header color, and comment/annotation color.
- **FR-003**: The Custom Theme screen MUST display a live preview showing sample song content (including lyrics, chords, a section header, and a comment/annotation) that updates immediately as the user changes any color, before the theme is saved.
- **FR-004**: The system MUST allow the user to save the current set of colors as a named theme.
- **FR-005**: The system MUST allow the user to save an edited set of colors either as an update to the currently loaded theme (same name) or as a new theme (new name).
- **FR-006**: The Custom Theme screen MUST provide a dropdown selector listing all of the user's saved custom themes, allowing the user to recall any one of them into the editor and preview.
- **FR-007**: Recalling a saved theme from the dropdown MUST load its colors into the color pickers and update the preview to match.
- **FR-008**: The system MUST persist each saved custom theme in JSON format, including the theme's name and its color values for each editable element.
- **FR-009**: The main app theme picker MUST include a "Custom" option alongside the existing System/Light/Dark options.
- **FR-010**: Selecting "Custom" in the main theme picker MUST apply the user's most recently selected or saved custom theme to the entire app (song viewer and app chrome).
- **FR-011**: If no custom theme has been saved yet, the "Custom" option MUST guide the user to the Custom Theme screen to create one rather than applying an undefined or blank theme.
- **FR-012**: The system MUST allow the user to share any saved custom theme as a JSON file using the device's standard share sheet.
- **FR-013**: The system MUST allow the user to import a custom theme from a JSON file received from another user, adding it to their list of saved themes under its original name when that name has no conflict.
- **FR-014**: The system MUST validate imported theme JSON and reject files that are not well-formed, do not match the expected theme structure, or declare a format/version the current app does not recognize (e.g., a file produced by a newer app version), informing the user of the failure without adding a broken or partial theme.
- **FR-015**: The system MUST allow the user to delete a saved custom theme they no longer want.
- **FR-016**: If the user deletes the custom theme that is currently active, the system MUST fall back to a defined default appearance (e.g., System) rather than leaving the app in an undefined visual state.
- **FR-017**: The system MUST prevent two saved custom themes from silently overwriting each other under the same name without explicit user confirmation, whether the conflict arises from a manual save or from an import.
- **FR-018**: The system MUST check the contrast between text-bearing color pairs (background vs. lyric text, background vs. chords, background vs. section headers, background vs. comment/annotation text) against a minimum readability threshold, and MUST block saving the theme until every pair meets that minimum, showing the user which pair(s) are failing.
- **FR-019**: When an imported theme's name collides with an existing saved theme's name, the system MUST prompt the user to choose a different name before completing the import, rather than silently overwriting or silently auto-renaming either theme.

### Key Entities

- **Custom Theme**: A user-created named set of colors. Attributes: name, background color, main text/lyric color, chord color, section header color, comment/annotation color, and a format/version marker to support future compatibility checks.
- **Saved Theme Library**: The collection of all custom themes a given user has created or imported on their device, from which the dropdown selector and the main theme picker's "Custom" option draw.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can create, preview, and apply a new custom theme in under 2 minutes without external instructions.
- **SC-002**: 100% of color changes made in the Custom Theme screen are reflected in the on-screen preview within a perceptible instant (no save step required to preview).
- **SC-003**: Users can maintain and switch between at least 5 saved custom themes without any loss of previously saved color data.
- **SC-004**: A shared theme file, when imported on another device, reproduces the exact same colors as the original 100% of the time.
- **SC-005**: 95% of users attempting to import an invalid or corrupted theme file receive a clear, actionable error message rather than a silent failure or crash.
- **SC-006**: 0% of saved custom themes contain a text/background color pair below the minimum readability contrast threshold.

## Assumptions

- The set of editable theme elements is: background, main text/lyric color, chord color, section header color, and comment/annotation color. This matches the visual roles already distinguished in the app's song renderer; any finer-grained sub-styles (e.g., different comment presentation styles) are derived automatically from the single comment/annotation color rather than exposed as separate pickers.
- "Custom" is a single, flat theme (not itself split into separate light/dark variants), consistent with how it sits alongside System/Light/Dark as one more option in the existing theme picker.
- "Standard Google sharing options" refers to the device's standard share sheet (the same mechanism already used elsewhere in the app to share files, which surfaces Gmail, Google Drive, Messages, and other installed apps as targets), not a bespoke Google Drive-only integration.
- Sharing a theme implies both export (sending) and import (receiving and adding to the recipient's saved themes), since a theme shared with "other users" is only useful if they can bring it into their own app.
- There is no fixed limit on the number of custom themes a user can save, beyond ordinary device storage constraints.
- When the user opens the Custom Theme screen with no prior custom theme saved, the color pickers default to the colors of the currently active app theme (System/Light/Dark) as a starting point for customization.
- The minimum readability contrast threshold (FR-018, SC-006) is the WCAG AA standard contrast ratio (4.5:1) for normal text, a widely recognized industry baseline for legible text-on-background pairing.
