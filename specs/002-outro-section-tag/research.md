# Research: Outro Section Tag Support

## Decision 1: How to classify `{soo}`/`{start_of_outro}` relative to the ChordPro standard

**Decision**: Treat the outro directive pair the same way the existing `{sob}`/`{start_of_bridge}`
(Bridge) directive is already treated in `ChordProParser` — added directly into the same
section-directive `switch` block that handles Verse/Chorus/Bridge, producing a generic
`SectionBlock('Outro')`, rather than building a separate "extension directive" code path.

**Rationale**: Bridge is not universally part of every ChordPro implementation's core directive
set either, yet the codebase already handles it inline alongside Verse/Chorus without any special
isolation — because `SectionBlock` is a generic, label-only construct with no per-type behavior to
diverge. Constitution Principle II's isolation requirement ("clearly isolated... not mixed into
standard-directive handling") is aimed at directives that *change parser behavior* in
app-specific ways (e.g. `{x_*:...}` custom directives, which are genuinely inert everywhere else).
An outro section behaves identically to every other section type: it starts, contains lyric/chord
lines, and ends. Introducing a separate switch or wrapper purely to mark it "non-core" would add a
structural distinction with no behavioral difference — a violation of Principle V (Simplicity &
YAGNI) to avoid a violation of Principle II that doesn't actually apply here.

**Alternatives considered**:
- *Separate "GigBook extension directives" switch/module*: Rejected — no other section directive
  is isolated this way today, there is no behavioral divergence to justify a new code path, and it
  would create an inconsistency (Bridge inline, Outro isolated) with no user-visible rationale.
- *Reject/no-op the tag as unrecognized*: Rejected — this directly contradicts the feature request
  and spec, which require the section to render as a labeled "Outro" block.

## Decision 2: Default label text when no inline value is supplied

**Decision**: `{soo}` / `{start_of_outro}` with no value produces `SectionBlock('Outro')`,
matching the existing default-label pattern for `{sov}` → `'Verse'`, `{soc}` → `'Chorus'`, `{sob}`
→ `'Bridge'` (`lib/services/chordpro_parser.dart:221-229`).

**Rationale**: Consistency with the three existing section directives, all of which follow
`value.isNotEmpty ? value : '<DefaultLabel>'`. No reason exists to special-case Outro.

**Alternatives considered**: None seriously considered — the existing pattern is unambiguous and
directly reusable.

## Decision 3: Where the end-of-outro tag is handled

**Decision**: Add `'eoo'` and `'end_of_outro'` to the existing combined case group that currently
handles `eov`/`end_of_verse`/`eoc`/`end_of_chorus`/`eob`/`end_of_bridge` (all of which just fall
through to `inTabSection = false`, since only tab sections require special close-time handling).

**Rationale**: An outro section, like verse/chorus/bridge, is lyric/chord content, not raw tab
text — its end tag needs no special handling beyond ensuring `inTabSection` is false (which it
already would be, since outro sections don't set it true). Grouping with the existing non-tab
end-tags keeps the switch statement's structure unchanged and easy to scan.

**Alternatives considered**: A standalone `case 'eoo': case 'end_of_outro':` arm with an empty
body — rejected as redundant; the existing combined case already expresses "these are the
non-tab section enders" and Outro belongs in that set.

All unknowns from the Technical Context are resolved; no `NEEDS CLARIFICATION` markers remain.
