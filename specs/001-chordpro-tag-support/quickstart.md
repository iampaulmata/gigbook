# Quickstart: Validating Full ChordPro Tag Support

Prerequisites: Flutter SDK matching `pubspec.yaml`'s `^3.9.2` constraint, a connected device or
emulator (see the project's `run` skill).

## 1. Run the parser test suite

```bash
flutter pub get
flutter test test/services/chordpro_parser_test.dart
```

Expected: all tests pass, covering FR-001 through FR-025 and the spec's Edge Cases (see
[contracts/chordpro-directive-grammar.md](./contracts/chordpro-directive-grammar.md) for the
directive-to-requirement mapping each test exercises).

## 2. Exercise the feature on-device

Launch the app (via the project's `run` skill) and import the sample file below — save it as
`chordpro-tag-support-sample.cho` and import it through the normal file-picker import flow.

```chordpro
{title: Full Tag Sample}
{subtitle: Feature Verification}
{artist: Test Author}
{key: G}
{capo: 2}
{tempo: 96}
{time: 3/4}

{c: Capo %{capo}, key of %{key} — quiet intro}
{ci: play softly}
{cb: Watch for the key change}
{highlight: Big finish coming up!}

{sov}
[G]Amazing grace, how [C]sweet the [G]sound
{tb:yellow}[D]that saved a [G]wretch{tb} like me
{eov}

{soc}
{textcolour: red}
[G]I once was [C]lost but [G]now am found
{textcolour}
{tc:black}was blind{tc} but now I [D]see
{eoc}

{sob}
{tb:yellow}{tc:black}both styles{tc}{tb} on one word
{eob}

{sot}
e|--0--2--3--|
B|--1--3------|
{eot}

{textsize: 8}
{textfont: sans}
Text size/font directives above must have no visible effect.

{x_gigbook_note: this must never be visible}
```

## 3. Manually verify against Success Criteria

- **SC-001/SC-007**: Import succeeds with no errors; no raw directive text or `x_gigbook_note`
  content is visible anywhere in the rendered song.
- **SC-002**: Song header shows title, subtitle, artist, key, capo, tempo, and time signature.
- **SC-003**: Verse, chorus, bridge, and tab sections are visually distinct from each other and
  from plain lyric lines; the tab block renders as raw monospace text (the `e|--0--2--3--|`
  line appears verbatim, not parsed for chords).
- **SC-004**: The four annotation lines (grey-bar, italic, boxed, highlight) are each visually
  distinguishable.
- **SC-005**: "that saved a wretch" has only "wretch" (or "like me", depending on placement above)
  on a yellow background; "was blind" appears in black text with the rest of the line unaffected;
  "both styles" has both a yellow background and black text.
- **SC-006**: The grey-bar comment line shows "Capo 2, key of G" (live values, not literal
  `%{capo}`/`%{key}` text).
- Standing red text color applies to the lyric line under `{soc}` but the chord letters above it
  (`G`, `C`) remain in the app's normal chord color, not red.
- The `{textsize:8}`/`{textfont:sans}` line renders at the app's normal configured font
  size/family, not shrunk to size 8.

If every bullet holds, the feature satisfies its spec.
