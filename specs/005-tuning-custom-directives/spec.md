# Feature Specification: Tuning Tag and Custom Preset Directive

**Feature Branch**: `005-tuning-custom-directives`

**Created**: 2026-07-16

**Status**: Draft

**Input**: User description: "need to add some new directives/tags for the files. One will be for the tuning that will appear in both the info and in a tag below the Artist when the lyrics are displayed. I also want to use custom directives instead of ignoring them so that I can use a custom directive like `x_preset` so that I can display the preset that I use on my multieffects pedal."

## Clarifications

### Session 2026-07-16

- Q: Preset should be `preset` (alias `p`) instead of the custom `x_preset` directive; should `tuning` also accept a short alias `t`? → A: `t` is already `title`'s alias, so tuning uses `tu` instead — no collision with any existing directive or alias.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - See a song's tuning at a glance (Priority: P1)

A user has tagged a ChordPro file with a tuning (e.g. "Drop D"). While viewing the song on stage, they see the tuning both as a small tag directly under the artist name — visible the instant the song opens — and alongside the song's other performance details (key, capo, time signature).

**Why this priority**: This is the core capability the feature exists to deliver, and it's the more fully-specified of the two requests (explicit dual placement). Musicians switching tunings between songs in a set need this to be immediately visible, not something they hunt for.

**Independent Test**: Import a ChordPro file containing a tuning directive, open the song, and confirm the tuning appears both directly below the artist name and in the song's metadata area.

**Acceptance Scenarios**:

1. **Given** a ChordPro file with a tuning directive and an artist, **When** the user opens the song, **Then** a tuning tag appears directly below the artist name.
2. **Given** the same file, **When** the user views the song, **Then** the tuning also appears in the song's existing metadata area (alongside key/capo/time signature, when present).
3. **Given** a ChordPro file with no tuning directive, **When** the user opens the song, **Then** no tuning tag appears in either location.
4. **Given** a ChordPro file with a tuning directive but no key, capo, or time signature, **When** the user opens the song, **Then** the metadata area still appears, showing only the tuning.

---

### User Story 2 - Display a pedal-preset tag (Priority: P2)

A user tags a ChordPro file with a `preset` directive naming the preset they use on their multi-effects pedal for that song. While viewing the song, they see the preset name displayed alongside the other performance details.

**Why this priority**: Depends on nothing from User Story 1 and is independently useful, but is a narrower, single-directive addition rather than the primary ask.

**Independent Test**: Import a ChordPro file containing a `preset` directive, open the song, and confirm the preset value is visible in the song's metadata area.

**Acceptance Scenarios**:

1. **Given** a ChordPro file with a `preset` directive, **When** the user opens the song, **Then** the preset value appears, clearly labeled, in the song's metadata area.
2. **Given** a ChordPro file with no `preset` directive, **When** the user opens the song, **Then** no preset entry appears.
3. **Given** a ChordPro file with a custom `x_*` directive (e.g. `x_foo`), **When** the user opens the song, **Then** that directive continues to be accepted with no visible effect, unchanged from current behavior — `preset` is its own recognized directive, not part of the custom-directive mechanism.

---

### Edge Cases

- A song declares the same tuning (or preset) directive more than once — the first declared value is used, consistent with how other metadata directives (e.g. title, key) already resolve repeated declarations. This applies whether the full name or its short alias (`tu`/`p`) is used, or a mix of both across repeated declarations.
- A tuning or preset value is unusually long (e.g. a multi-string custom tuning description) — it displays without breaking the layout of the metadata area, consistent with how existing long key/time-signature values are already handled.
- A song has a preset or tuning value but no artist — the tuning tag (which sits below the artist line) simply has no artist line above it; the metadata-area entries are unaffected either way.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST recognize a `tuning` ChordPro directive (short alias `tu`) and capture its value when importing/parsing a song.
- **FR-002**: When a song has a tuning value, the song viewer MUST display it as a labeled tag directly below the artist line.
- **FR-003**: When a song has a tuning value, the song viewer MUST also display it within the song's existing metadata area, alongside key/capo/time signature.
- **FR-004**: The system MUST recognize a `preset` ChordPro directive (short alias `p`) and capture its value when importing/parsing a song.
- **FR-005**: When a song has a preset value, the song viewer MUST display it, clearly labeled (e.g. "Preset"), within the song's existing metadata area.
- **FR-006**: Custom `x_*` directives MUST continue to be accepted with no visible effect, unchanged from current behavior — `preset` is a recognized directive in its own right, not part of that mechanism.
- **FR-007**: The song's metadata area MUST appear whenever at least one of key, capo, time signature, tuning, or preset is present — not only when key/capo/time signature are present, as today.
- **FR-008**: If a song declares the same tuning or preset directive more than once (by its full name, its short alias, or a mix of both), the system MUST use the first declared value.
- **FR-009**: A song with no tuning value MUST NOT display a tuning tag in either display location.
- **FR-010**: A song with no preset value MUST NOT display a preset entry.

### Key Entities

- **Song Metadata**: The set of performance-relevant details already captured per song (title, subtitle, artist, key, capo, tempo, time signature) gains two new optional attributes: tuning and preset.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A song's tuning is visible within 1 second of opening it, with no additional taps or navigation required.
- **SC-002**: 100% of songs containing a tuning directive display it consistently in both the below-artist tag and the metadata area.
- **SC-003**: 100% of songs containing a preset directive display the preset value in the metadata area.
- **SC-004**: Songs without tuning or preset directives render identically to their appearance before this feature — no visual regression for existing content.

## Assumptions

- `tuning` and `preset` are each added as their own recognized directive (like `key` or `capo`), not handled through the general custom-directive (`x_*`) mechanism — the user's revised request treats both as first-class directives, symmetric with each other. Any other custom directive a user wants surfaced in the future would be added the same way, one directive at a time, rather than through an open-ended system for displaying arbitrary, unlabeled `x_*` directives with no defined presentation.
- "The info" refers to the song viewer's existing metadata area (the row currently showing key/capo/time signature chips) — the only such area in the app today.
- `tuning` uses the short alias `tu` and `preset` uses `p`. `t` (already `title`'s alias) and `pr`/other candidates were avoided; `tu` and `p` were checked against the full existing directive/alias table for collisions and are unambiguous (per Clarifications).
- The metadata-area entry for tuning/preset is labeled plainly (e.g. "Tuning: Drop D", "Preset: Preset 3"), matching the existing "Key: …" / "Capo …" / "Time: …" chip style.
- New chips are appended after the existing key/capo/time-signature chips, preserving today's display order for existing songs.
- Live metadata insertion (the existing `%{capo}`, `%{key}` inline-reference mechanism) is out of scope for tuning and preset — the user asked only for the two new display locations described, not for inline lyric-line references.
