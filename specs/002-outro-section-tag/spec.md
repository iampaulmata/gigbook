# Feature Specification: Outro Section Tag Support

**Feature Branch**: `002-outro-section-tag`

**Created**: 2026-07-08

**Status**: Draft

**Input**: User description: "I want to add another tag to the system that allows the recognition {soo}{eoo} with an alias of {start_of_outro}{end_of_outro}."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Import a chart with an outro section (Priority: P1)

A performer imports a ChordPro file whose author marked the song's ending passage with an outro section directive. They expect the song view to show that passage clearly labeled as an outro, the same way verse, chorus, bridge, and tab sections are already labeled.

**Why this priority**: This is the entire scope of the feature — without it, outro content still displays but is visually indistinguishable from an unmarked lyric block, which is exactly the gap the request is closing.

**Independent Test**: Import a `.cho` file containing a `{soo}...{eoo}` block; verify the song view shows that block labeled as "Outro," in the same position and order as the rest of the file.

**Acceptance Scenarios**:

1. **Given** a file containing `{soo}` followed by lyric/chord lines and then `{eoo}`, **When** viewing the song, **Then** that block is displayed labeled as "Outro," visually consistent with how Verse/Chorus/Bridge sections are labeled.
2. **Given** a file that uses `{start_of_outro}` and `{end_of_outro}` instead of `{soo}`/`{eoo}`, **When** viewing the song, **Then** the result is identical to using the short-form tags.
3. **Given** a file with directive names in mixed case (e.g. `{SOO}`, `{Start_Of_Outro}`), **When** the file is imported, **Then** the outro section is recognized the same as its lowercase form, consistent with how other section tags are matched.

---

### Edge Cases

- A `{soo}`/`{start_of_outro}` start directive has no matching end directive: the section is treated as continuing through the rest of the file, consistent with how unmatched verse/chorus/bridge/tab sections are handled.
- A file mixes the short and long forms of the outro tag across multiple outro blocks in the same file (e.g. `{soo}...{eoo}` for one, `{start_of_outro}...{end_of_outro}` for another): both are recognized as Outro sections identically.
- An outro section appears more than once in the same file: each occurrence is rendered as its own separate labeled Outro block, in file order, consistent with how repeated verse/chorus/bridge sections are handled.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST render content between `{soo}`/`{start_of_outro}` and `{eoo}`/`{end_of_outro}` as a labeled Outro section.
- **FR-002**: System MUST match the outro start/end directive names case-insensitively, consistent with the app's existing directive-matching convention.
- **FR-003**: System MUST treat an outro section with no matching end directive as continuing through the rest of the file, consistent with existing section-handling behavior.
- **FR-004**: Importing a file that combines outro sections with any other supported directives, in any order, MUST NOT fail, crash, or drop unrelated content elsewhere in the file.

### Key Entities

- **Section**: A labeled block of content within a song, bounded by a start/end directive pair. This feature adds Outro as a new section label, alongside the existing Verse, Chorus, Bridge, and Tab labels.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A ChordPro file containing `{soo}...{eoo}` or `{start_of_outro}...{end_of_outro}` sections imports successfully with zero errors or crashes.
- **SC-002**: Outro sections are visually distinguishable from ordinary lyric lines and from Verse/Chorus/Bridge/Tab sections in 100% of imported test files.
- **SC-003**: Files using either the short form (`{soo}`/`{eoo}`) or long form (`{start_of_outro}`/`{end_of_outro}`) produce identical rendered output.

## Assumptions

- The Outro section is displayed with its own distinct label ("Outro"), following the same visual treatment pattern already used to distinguish Verse, Chorus, Bridge, and Tab sections from one another and from plain lyric lines.
- Directive names are matched case-insensitively, consistent with the app's existing parsing convention for all other directives.
- Outro section content is parsed for chord/lyric pairs the same way Verse/Chorus/Bridge content is (unlike Tab sections, which are preserved as raw literal text) since the request does not indicate outro content should be treated as tab notation.
