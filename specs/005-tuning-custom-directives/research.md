# Research: Tuning Tag and Custom Preset Directive

## 1. Where `tuning` and `preset` fit in the existing metadata model

**Decision**: Add `tuning` (String?) and `preset` (String?) as new first-write-wins fields on `ParsedSong`, parsed inside `ChordProParser.parse()`'s existing directive `switch` — each as its own case with its own short alias (`case 'tuning': case 'tu':` and `case 'preset': case 'p':`), following the exact `value.isEmpty ? null : value` first-write-wins pattern already used for `key`/`timeSignature`. Aliases were checked against every existing directive/alias in the switch (research decision, superseding the original `x_preset`/no-alias design — see spec Clarifications 2026-07-16): `t` is already `title`'s alias, so `tuning` uses `tu`; `p` was free, so `preset` uses it directly.

**Rationale**: `ParsedSong` is already the single place all per-song display metadata lives (title, subtitle, artist, key, capo, tempo, timeSignature); adding two more optional fields there is the smallest change consistent with the existing shape. `preset` is no longer implemented via the `x_*` custom-directive convention — it's a first-class directive symmetric with `tuning`, both following the same established pattern already used for `capo`/`tempo`/`time` (non-core-ChordPro-standard metadata directives the app already treats as first-class, aliased or not). The `switch` statement has no `default:` case, so Dart already no-ops any directive it doesn't explicitly list — every `x_*` custom directive keeps falling through unchanged (FR-006), completely untouched by this feature.

**Alternatives considered**:
- A generic `Map<String, String> customDirectives` field capturing every `x_*` directive — rejected; a generic map has no defined display treatment (label, position) for arbitrary future keys, which the constitution's Simplicity & YAGNI principle argues against building speculatively.
- Implementing `preset` via the `x_preset` custom-directive form (the original design) — superseded by the user's revised request; dropped in favor of a first-class directive, matching `tuning`'s treatment exactly.

## 2. Does adding `preset` as a first-class (non-`x_`) directive fit Constitution Principle II?

**Decision**: Yes — `tuning` and `preset` are documented in the grammar contract's "Metadata directives" table (research decision 4) as GigBook-added directives, the same way `capo`/`tempo`/`time` already are; no `x_` prefix is required for that documentation obligation to be satisfied.

**Rationale**: Principle II requires deviations from the ChordPro standard to be "clearly isolated in the parser and documented as an extension, not mixed into standard-directive handling." The parser already has precedent for first-class, GigBook-chosen metadata directives that aren't part of core ChordPro (`capo`, `tempo`/`bpm`, `time`) — none of them use an `x_` prefix, and all are clearly documented in the grammar contract. `tuning`/`preset` follow that exact precedent rather than the separate `x_*` "truly arbitrary, undocumented custom tag" convention, which remains reserved for directives GigBook has made no promises about (FR-006, unchanged).

**Alternatives considered**: Keeping `preset` on the `x_` prefix (original design) to more visibly mark it as non-standard — superseded by the user's explicit request; also arguably a false distinction, since `capo`/`tempo`/`time` are equally non-core-standard yet unprefixed already.

## 3. Does `extractMeta()` (the lightweight import-time extractor) need `tuning`/`preset`?

**Decision**: No. `extractMeta()` stays unchanged.

**Rationale**: `extractMeta()` already excludes `timeSignature` — a full-parse-only, display-time field — and is used solely for import-time song matching/deduplication (title/artist/key/capo/tempo), not display. `tuning` and `preset` are purely display concerns, re-derived from `Song.content` on every view via `ChordProParser.parse()` inside `ChordProRenderer`, exactly like `timeSignature` already is. No `lib/db/` schema change or `Song` model field is needed — confirmed by `Song` (`lib/models/song.dart`) already omitting `timeSignature` as a stored column for the same reason.

**Alternatives considered**: Adding `tuning`/`preset` columns to the `songs` table — rejected; would require a migration for a value that's already available for free by reparsing stored content, the same tradeoff already made (and documented precedent) for `timeSignature`.

## 4. Grammar contract: amend the existing doc or add a new one?

**Decision**: The existing `specs/001-chordpro-tag-support/contracts/chordpro-directive-grammar.md` is the single reference the parser test suite is written against (per its own header) and remains so — it gets one edit during implementation: two new rows under "Metadata directives," for `tuning` (alias `tu`) and `preset` (alias `p`). The "Custom directives" table (the `x_*` no-op row) is entirely unchanged, since `preset` is no longer part of that mechanism. This feature's own `contracts/directive-additions.md` specifies exactly that delta, scoped to this feature, so it's reviewable independently of editing the shared master file by hand.

**Rationale**: The master grammar doc is explicitly the parser test suite's contract; letting it silently drift out of date (missing the two new metadata directives) after this feature ships would be a documentation bug the next reader trips over. A second, competing "grammar" file would fragment that single source of truth.

**Alternatives considered**: Leave the master doc untouched and only document the change in this feature's spec — rejected; the master doc's own stated purpose ("the reference the parser test suite is written against") means it must reflect what the suite actually verifies.

## 5. Live metadata insertion (`%{...}`) for tuning/preset

**Decision**: Out of scope, per the spec's Assumptions — `tuning` and `preset` are not added to `_liveMetadataRe`'s resolvable set or the `live*` tracking locals in `ChordProParser.parse()`.

**Rationale**: The user's request describes two specific display locations (below-artist tag, metadata area); nothing asks for inline `%{tuning}`/`%{preset}` references within lyric/annotation lines. Adding it would require new `liveTuning`/`livePreset` mutable locals threaded through `substituteLiveMetadata` for a capability nobody asked for (YAGNI).
