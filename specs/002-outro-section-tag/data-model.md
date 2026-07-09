# Data Model: Outro Section Tag Support

No new entities, fields, or persistence schema changes are introduced by this feature.

## Extended entity

- **Section** (defined in `specs/001-chordpro-tag-support/spec.md` and implemented as
  `SectionBlock` in `lib/services/chordpro_parser.dart`): a labeled block of content bounded by a
  start/end directive pair. This feature extends the set of recognized section labels with
  **Outro**, produced by `{soo}`/`{start_of_outro}` ... `{eoo}`/`{end_of_outro}`, alongside the
  existing Verse, Chorus, Bridge, and Tab labels.

  `SectionBlock` already models a section purely as `{label: String}` with no type-specific
  fields — so no schema, class, or constructor change is needed to support the new label value.
  The renderer (`lib/widgets/chordpro_renderer.dart`) displays `block.label.toUpperCase()`
  generically, so "Outro" renders correctly with zero renderer changes.

## State transitions

Unchanged from the existing section-handling behavior described in `001-chordpro-tag-support`:
a start directive opens a section; a matching (or any) end-of-section directive closes it; an
unclosed section implicitly continues through end-of-file. Outro sections follow this same
transition model — they are not tab sections, so `inTabSection` is never set for them.
