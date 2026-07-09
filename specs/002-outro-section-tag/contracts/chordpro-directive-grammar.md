# Contract: ChordPro Directive Grammar — Outro Section Addendum

This addendum extends the base grammar contract established in
`specs/001-chordpro-tag-support/contracts/chordpro-directive-grammar.md`. It is the reference the
parser test suite (`test/services/chordpro_parser_test.dart`) is written against for this feature.
Directive names are matched case-insensitively, consistent with the base contract.

## Section directives (start/end pairs; unmatched end-of-file closes implicitly)

| Start | End | Aliases | Produces | FR |
|---|---|---|---|---|
| `{soo}` | `{eoo}` | `{start_of_outro}` / `{end_of_outro}` | `SectionBlock('Outro')` + lyric/chord lines | FR-001 |

This row is added to the existing Section directives table from the base contract; it does not
modify or replace any existing row (Verse/Chorus/Bridge/Tab are unchanged).

## Whole-file guarantee

A file combining `{soo}`/`{eoo}` or `{start_of_outro}`/`{end_of_outro}` with any other supported
directive, in any order or nesting, MUST import without error, crash, or loss of unrelated content
(FR-004).
