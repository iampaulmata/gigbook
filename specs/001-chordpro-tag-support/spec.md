# Feature Specification: Full ChordPro Tag Support

**Feature Branch**: `001-chordpro-tag-support`

**Created**: 2026-07-08

**Status**: Draft

**Input**: User description: "The application should accept all of the following chordpro tags: Song title {title:...}/{t:...}, Subtitle {subtitle:...}/{st:...}, Artist {artist:...}, Key {key:...}, Capo {capo:...}, Tempo {tempo:...}, Time signature {time:...}, Verse section {sov}...{eov}, Chorus section {soc}...{eoc}, Bridge section {sob}...{eob}, Tab section {sot}...{eot}, Grey-bar comment {comment:...}/{c:...}, Italic comment {comment_italic:...}/{ci:...}, Boxed comment {comment_box:...}/{cb:...}, General highlight line {highlight:...}, Text color (standing) {textcolour:red}...{textcolour}, Text size (standing) {textsize:14}...{textsize}, Text font (standing) {textfont:sans}...{textfont}, Inline background highlight {tb:yellow} text {tb}, Inline text color {tc:black} text {tc}, Combined highlight+color {tb:yellow}{tc:black} text {tc}{tb}, Live metadata insertion %{key}/%{capo}/etc., Custom app-only directive {x_yourapp_tagname:value}"

## Clarifications

### Session 2026-07-08

- Q: Should [Chord] markers inside a tab section ({sot}...{eot}) be parsed into chord/lyric pairs, or should the whole block be shown as raw literal text? → A: Raw literal text — no chord extraction inside tab blocks.
- Q: When a standing text color is active ({textcolour:...}), should chord symbols above the lyrics also be recolored? → A: Lyrics only — chord symbols keep the app's normal chord styling.
- Q: Should %{...} live metadata references resolve inside annotation lines ({comment:}, {highlight:}, etc.), or only inside ordinary lyric lines? → A: Both lyric and annotation lines.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Import a chart with full song metadata and structure (Priority: P1)

A performer imports a ChordPro file that declares title, subtitle, artist, key, capo, tempo, time signature, and marks its verse, chorus, bridge, and tab passages. They expect the library and song view to show all of that information correctly, and to see the song's structure clearly when performing.

**Why this priority**: Metadata and section structure are the foundation of a usable chart — without them, songs are unidentifiable in the library and unreadable as a structured piece during a performance. This is the minimum viable slice of the feature.

**Independent Test**: Import a `.cho` file containing every metadata and section directive listed above; verify the library list and song header show the captured metadata, and the song view shows each section (including tab content) in the correct order with no content missing.

**Acceptance Scenarios**:

1. **Given** a ChordPro file with `{title: Amazing Grace}`, `{subtitle: Hymn}`, `{artist: John Newton}`, `{key: G}`, `{capo: 2}`, `{tempo: 72}`, and `{time: 3/4}` directives, **When** the file is imported, **Then** the library list shows "Amazing Grace" with artist "John Newton", and opening the song shows subtitle, key, capo, tempo, and time signature.
2. **Given** a file with `{sov}...{eov}`, `{soc}...{eoc}`, `{sob}...{eob}`, and `{sot}...{eot}` blocks, **When** viewing the song, **Then** each block is visibly labeled (Verse/Chorus/Bridge) or shown as tab content, in the same order as the source file.
3. **Given** a file that uses the short aliases (`{t:}`, `{st:}`) instead of the long directive names, **When** the file is imported, **Then** the result is identical to using the long-form directive names.

---

### User Story 2 - Import a chart with styled annotation lines (Priority: P2)

A performer imports a chart that includes performance notes — "quiet intro," "key change here," "repeat chorus x2" — marked with grey-bar, italic, boxed, or general-highlight comment directives. They expect these notes to stand out from the lyrics at a glance, and to be visually distinguishable from each other.

**Why this priority**: Annotation lines carry performance-critical instructions. They are of lower priority than core metadata/structure because a song is still usable without them, but readability during a live set depends on being able to tell an instruction apart from a lyric line without stopping to read closely.

**Independent Test**: Import a file containing one line of each comment style (`{comment:}`/`{c:}`, `{comment_italic:}`/`{ci:}`, `{comment_box:}`/`{cb:}`, `{highlight:}`) and verify each renders with a visually distinct style from the lyric lines and from each other.

**Acceptance Scenarios**:

1. **Given** a line `{c: Repeat chorus x2}`, **When** viewing the song, **Then** it renders as a grey-bar annotation line, not as sung lyrics.
2. **Given** a line `{ci: softly}`, **When** viewing the song, **Then** it renders in italic style and is visually distinct from a grey-bar comment.
3. **Given** a line `{cb: Key change to D}`, **When** viewing the song, **Then** it renders with a boxed/bordered style, visually distinct from the other two comment styles.
4. **Given** a line `{highlight: Big finish!}`, **When** viewing the song, **Then** it renders as a fourth, visually distinct annotation style.

---

### User Story 3 - Import a chart with color-coded text (Priority: P3)

A performer imports a chart where the original author used color to mark up meaning — e.g., a duet part in a different color, or a single word highlighted for emphasis mid-line. They expect the coloring to survive import and appear exactly where the original author placed it.

**Why this priority**: Color coding is a visual aid layered on top of already-usable lyrics/chords; it improves clarity but the song remains fully performable without it, so it ranks below structure and annotations.

**Independent Test**: Import a file that sets a standing text color for a passage (`{textcolour:red}...{textcolour}`) and separately marks an inline span (`{tb:yellow} chorus {tb}`, `{tc:black} lead {tc}`, and a combined `{tb:yellow}{tc:black} both {tc}{tb}`); verify the standing color applies to the whole passage and each inline tag colors only its own enclosed text.

**Acceptance Scenarios**:

1. **Given** `{textcolour: red}` followed by several lyric lines and then a bare `{textcolour}`, **When** viewing the song, **Then** every lyric line in between renders in red text and lines after the reset render in the default color.
2. **Given** a lyric line containing `{tb:yellow} chorus {tb}`, **When** viewing the song, **Then** only the word "chorus" has a yellow background; the rest of the line is unstyled.
3. **Given** a lyric line containing `{tc:black} lead {tc}`, **When** viewing the song, **Then** only the word "lead" renders in black text; surrounding text keeps its normal color.
4. **Given** a lyric line containing `{tb:yellow}{tc:black} both {tc}{tb}`, **When** viewing the song, **Then** the word "both" has both a yellow background and black text, and no other text on the line is affected.
5. **Given** a file that also sets `{textsize: 14}` and `{textfont: sans}`, **When** viewing the song, **Then** the rendered text size and font are unaffected — they continue to follow the app's own display settings.

---

### User Story 4 - Import a chart that reuses metadata inline (Priority: P4)

A performer imports a chart where the author wrote instructions like "Capo: %{capo}" directly into the lyrics/instructions instead of retyping the capo number, so the number always matches whatever was declared earlier in the file.

**Why this priority**: This is a convenience/consistency feature rather than a structural or readability necessity — useful but affects fewer files than the higher-priority stories.

**Independent Test**: Import a file with `{capo: 2}` near the top and a later line containing "Capo: %{capo} - use a capo!"; verify the rendered line shows "Capo: 2 - use a capo!".

**Acceptance Scenarios**:

1. **Given** `{key: G}` declared at the top of a file and a lyric line containing `Play in %{key}`, **When** viewing the song, **Then** the line renders as "Play in G".
2. **Given** a line referencing `%{tempo}` when no `{tempo:...}` directive exists anywhere in the file, **When** viewing the song, **Then** the placeholder renders as empty text, not as literal `%{tempo}`.
3. **Given** `{key: G}` at the top, a middle section that redeclares `{key: D}`, and a `%{key}` reference after that redeclaration, **When** viewing the song, **Then** the reference resolves to "D".

---

### User Story 5 - Import a chart with app-specific custom directives (Priority: P5)

A performer imports a chart authored in, or shared from, another ChordPro-compatible tool that embedded its own custom directive (e.g. `{x_someapp_note: value}`). They expect the import to succeed and the song to display normally, with the custom directive simply having no effect.

**Why this priority**: This is a compatibility/safety guarantee rather than a feature the user actively benefits from day-to-day; it ranks lowest because its only observable effect is the absence of a failure.

**Independent Test**: Import a file containing one or more `{x_...: ...}` directives interspersed with normal lyric content; verify the import succeeds and the song displays with no visible trace of the custom directive.

**Acceptance Scenarios**:

1. **Given** a file containing `{x_gigbook_note: internal use}` between two lyric lines, **When** the file is imported, **Then** the import succeeds and neither the directive name nor its value appears anywhere in the rendered song.

---

### Edge Cases

- A metadata directive (title, subtitle, artist, key, capo, tempo, time) appears more than once in the same file: the first occurrence is used for the song's stored/displayed metadata (library list, header); each occurrence updates the value substituted into `%{...}` references that follow it in the file.
- A section start directive (`{sov}`, `{soc}`, `{sob}`, `{sot}`) has no matching end directive: the section is treated as continuing through the rest of the file.
- A standing directive (`{textcolour:...}`, `{textsize:...}`, `{textfont:...}`) is never explicitly reset: its effect (where applicable) continues through the end of the file.
- An inline span tag (`{tb:...}`, `{tc:...}`) is opened but never closed on the same line: the styling applies to the remainder of that line only and does not carry over to subsequent lines.
- A color value (named color or hex code) given to `{textcolour}`, `{tb}`, or `{tc}` is invalid or unrecognized: the directive is accepted, no styling is applied, and import does not fail.
- A `%{...}` reference names metadata that is never declared anywhere in the file: it renders as empty text.
- Directive, inline-tag, and standing-directive names are written in mixed case (e.g. `{Title:}`, `{TB:yellow}`): they are recognized the same as their lowercase form.
- A file mixes short and long forms of the same directive (e.g. `{t:}` in one place, `{title:}` in another): both populate the same underlying metadata field, first-write-wins as with any repeated metadata directive.
- A tab section contains characters that look like chord brackets (e.g. `[` `]` used in ASCII tab notation): they are shown as-is as part of the raw literal text, not parsed as `[Chord]` markers.
- An annotation line (e.g. `{c: Capo %{capo}}`) contains a `%{...}` reference: it resolves to the current metadata value the same as it would in a lyric line.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST capture a song's title from `{title:...}` or `{t:...}` directives.
- **FR-002**: System MUST capture a song's subtitle from `{subtitle:...}` or `{st:...}` directives, as an attribute distinct from artist.
- **FR-003**: System MUST capture a song's artist from `{artist:...}` directives.
- **FR-004**: System MUST capture a song's key from `{key:...}` directives.
- **FR-005**: System MUST capture a song's capo position from `{capo:...}` directives.
- **FR-006**: System MUST capture a song's tempo from `{tempo:...}` directives.
- **FR-007**: System MUST capture a song's time signature from `{time:...}` directives.
- **FR-008**: System MUST render content between `{sov}`/`{start_of_verse}` and `{eov}`/`{end_of_verse}` as a labeled Verse section.
- **FR-009**: System MUST render content between `{soc}`/`{start_of_chorus}` and `{eoc}`/`{end_of_chorus}` as a labeled Chorus section.
- **FR-010**: System MUST render content between `{sob}`/`{start_of_bridge}` and `{eob}`/`{end_of_bridge}` as a labeled Bridge section.
- **FR-011**: System MUST preserve and display content between `{sot}`/`{start_of_tab}` and `{eot}`/`{end_of_tab}` verbatim as raw literal text, rather than discarding it or extracting `[Chord]` markers from it.
- **FR-012**: System MUST render lines marked by `{comment:...}` or `{c:...}` as grey-bar annotation lines, distinct from lyric lines.
- **FR-013**: System MUST render lines marked by `{comment_italic:...}` or `{ci:...}` in an italic annotation style, distinct from grey-bar and boxed annotation lines.
- **FR-014**: System MUST render lines marked by `{comment_box:...}` or `{cb:...}` in a boxed/bordered annotation style, distinct from grey-bar and italic annotation lines.
- **FR-015**: System MUST render lines marked by `{highlight:...}` as a fourth, visually distinct annotation style.
- **FR-016**: System MUST apply a standing text color from `{textcolour:VALUE}` to the lyric text of all subsequent lines until a bare `{textcolour}` resets it or the file ends, without recoloring the chord symbols above those lines.
- **FR-017**: System MUST accept standing `{textsize:...}`/`{textsize}` and `{textfont:...}`/`{textfont}` directives without error, and MUST NOT change the rendered text size or font — the app's own display settings remain authoritative.
- **FR-018**: System MUST render only the text enclosed between a `{tb:VALUE}` and its closing `{tb}` with the specified background color, leaving the rest of the line unaffected.
- **FR-019**: System MUST render only the text enclosed between a `{tc:VALUE}` and its closing `{tc}` with the specified text color, leaving the rest of the line unaffected.
- **FR-020**: System MUST support combined inline tags (e.g. `{tb:yellow}{tc:black} text {tc}{tb}`) applying both background and text color to the same enclosed span.
- **FR-021**: System MUST substitute `%{key}`, `%{capo}`, `%{tempo}`, `%{title}`, and other `%{...}` metadata references with the current value of that metadata at the point the reference appears, reflecting the most recent prior declaration of that directive in the file. This substitution MUST apply both within ordinary lyric text and within annotation lines (comment/highlight lines).
- **FR-022**: System MUST render a `%{...}` reference as empty text when the named metadata is never declared anywhere in the file, rather than showing the raw placeholder syntax.
- **FR-023**: System MUST accept custom directives matching `{x_*:...}` during import without error, and they MUST have no visible effect on the rendered song.
- **FR-024**: System MUST match all directive names, inline-tag names, and standing-directive names case-insensitively.
- **FR-025**: Importing a file that combines any number of the directives above, in any order, MUST NOT fail, crash, or drop unrelated content elsewhere in the file.

### Key Entities

- **Song Metadata**: Title, subtitle, artist, key, capo, tempo, and time signature captured from a song's directives; first-declared values are what the library and song header display.
- **Section**: A labeled block of content within a song — Verse, Chorus, Bridge, or Tab — bounded by a start/end directive pair. Tab section content is raw literal text, not parsed into chord/lyric pairs.
- **Annotation Line**: A single line of performance-note text carrying one of four styles (grey-bar, italic, boxed, general highlight), kept visually and structurally separate from lyric/chord content. May itself contain a Live Metadata Reference.
- **Styled Text Span**: A run of lyric text carrying an optional text color and/or background color, whether applied to a whole passage (standing) or to a specific substring within one line (inline). Standing text color affects lyric text only; chord symbols retain their normal styling.
- **Live Metadata Reference**: A placeholder within lyric text or an annotation line that resolves to the current value of a named Song Metadata field at the point it appears.
- **Custom Directive**: An app-namespaced directive recognized syntactically during import but producing no visible behavior in this app.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A ChordPro file exercising every directive in this specification imports successfully with zero errors or crashes, across a representative test corpus.
- **SC-002**: For any file declaring title, subtitle, artist, key, capo, tempo, and/or time signature, 100% of those declared values are visible from the library list and/or song header without opening the raw file.
- **SC-003**: Verse, chorus, bridge, and tab sections are visually distinguishable from each other and from ordinary lyric lines in 100% of imported test files.
- **SC-004**: The four annotation-line styles (grey-bar, italic, boxed, general highlight) are each visually distinguishable from lyric lines and from one another.
- **SC-005**: Inline colored/highlighted spans appear on exactly the substring specified by the source file, with zero bleed into surrounding text, across the test corpus.
- **SC-006**: Live metadata placeholders resolve to the correct current value in 100% of test cases, including cases where the referenced metadata is redeclared earlier in the same file.
- **SC-007**: Files containing unrecognized or custom app-only directives import with zero visible artifacts (no raw directive text, no error banners) in 100% of test cases.

## Assumptions

- Directive names, inline-tag names, and standing-directive names are matched case-insensitively, consistent with the app's existing parsing convention.
- Per clarification, `{textsize:...}` and `{textfont:...}` are parsed and accepted but never change on-screen rendering; the app's own font-size and theme settings remain authoritative for stage readability.
- Per clarification, inline `{tb:...}`/`{tc:...}` spans render with true inline (substring-level) fidelity, including combined use on the same span, rather than being approximated at whole-line granularity.
- `{highlight:...}` is treated as a fourth annotation-line style (alongside grey-bar, italic, and boxed comments), since the feature request describes it as a "general highlight line" — a single annotated line — rather than a session-scoped background-color state.
- Subtitle is captured as an attribute distinct from artist, since the feature request lists them as separate tags; this changes today's behavior where subtitle and artist are folded into a single field.
- Tab section content is preserved and displayed rather than discarded, since silently dropping it would conflict with the project's no-data-loss import principle (see Clarifications for its raw-literal-text treatment).
- Custom app-only directives (`{x_...}`) are always silently ignored (no visible effect, no error), consistent with their purpose as safe, forward-compatible extension points in the ChordPro standard.
- When a metadata directive repeats within a file, the first occurrence is authoritative for stored/displayed metadata, while `%{...}` references pick up the most recent prior value at their position in the file.
