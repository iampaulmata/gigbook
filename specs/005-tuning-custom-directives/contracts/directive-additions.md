# Contract: Directive Grammar Additions (Tuning + Preset)

This describes the exact delta to apply to the master grammar contract,
[`specs/001-chordpro-tag-support/contracts/chordpro-directive-grammar.md`](../../001-chordpro-tag-support/contracts/chordpro-directive-grammar.md)
— the file the parser test suite (`test/services/chordpro_parser_test.dart`) is written against (research.md §4). Implementation MUST apply this delta to that file directly rather than leaving it to drift out of date.

> **Revised 2026-07-16** (see spec Clarifications): `preset` is now a first-class metadata directive with alias `p`, not the custom `x_preset` form. `tuning` gained the alias `tu` (not `t`, which already belongs to `title`).

## Addition — two new rows under "Metadata directives"

| Directive | Aliases | Sets | FR |
|---|---|---|---|
| `{tuning:VALUE}` | `{tu:VALUE}` | `ParsedSong.tuning` | FR-001 |
| `{preset:VALUE}` | `{p:VALUE}` | `ParsedSong.preset` | FR-004 |

Resolution rule: first declaration wins (by full name, alias, or a mix of both), identical to `key`/`capo`/`time` in the same table.

## "Custom directives" section — unchanged

`preset` is no longer part of this mechanism, so the existing row is untouched:

| Pattern | Effect | FR |
|---|---|---|
| `{x_*:VALUE}` (any name prefixed `x_`) | Accepted, no visible effect (falls to default no-op) | FR-023 |

FR-006 (this feature) simply confirms no regression to that existing rule.

## Display contract (not part of the grammar table, but the reason these two fields exist)

| Field | Displayed where | Condition |
|---|---|---|
| `ParsedSong.tuning` | (a) a labeled tag directly below the artist line, AND (b) the song's metadata chip row (with key/capo/time signature) | Only when non-null (FR-002, FR-003, FR-009) |
| `ParsedSong.preset` | The song's metadata chip row only (no below-artist duplicate) | Only when non-null (FR-005, FR-010) |

The metadata chip row's visibility condition expands from `key != null || capo != null || timeSignature != null` to also include `tuning != null || preset != null` (FR-007) — a song with only a tuning or only a preset must still show the row.
