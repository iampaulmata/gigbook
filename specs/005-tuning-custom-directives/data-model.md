# Data Model: Tuning Tag and Custom Preset Directive

## ParsedSong (extended)

`ParsedSong` (`lib/services/chordpro_parser.dart`) gains two new optional fields, alongside its existing `key`/`capo`/`tempo`/`timeSignature`:

| Field | Type | Required | Notes |
|---|---|---|---|
| `tuning` | `String?` | No | Set from the `{tuning:VALUE}` directive or its `{tu:VALUE}` alias. `null` if never declared or declared empty. |
| `preset` | `String?` | No | Set from the `{preset:VALUE}` directive or its `{p:VALUE}` alias. `null` if never declared or declared empty. |

**Validation rules**:
- First-declared, non-empty value wins if the directive appears more than once in a file — by its full name, its alias, or a mix of both (FR-008), matching `key`/`capo`/`timeSignature`'s existing resolution rule exactly — no new validation logic, same `??=` pattern.
- No format constraint on the value (free text) — a tuning or preset name is inherently free-form (e.g. "Drop D", "DADGAD", "Preset 3", "Ch. 2 / Boost").

**Lifecycle**: Derived fresh on every parse of a song's raw ChordPro content (`ChordProParser.parse()`), exactly like `timeSignature` — not persisted to the `songs` table, not part of `Song.toMap()`/`Song.fromMap()` (`lib/models/song.dart`). No database migration is needed (research.md §3).

## No new entities

This feature adds fields to an existing entity; it does not introduce a new persisted or transient entity, and does not touch `lib/db/` or `lib/models/song.dart`.
