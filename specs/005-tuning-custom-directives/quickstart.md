# Quickstart: Tuning Tag and Custom Preset Directive

Manual validation proving the feature works end-to-end. See `spec.md` for the acceptance scenarios this walks through and `contracts/directive-additions.md` for the exact grammar/display contract.

## Prerequisites

- App built and running on a device/emulator (`flutter run`), or via the project's `run`/`verify` skill.

## Scenario 1 — Tuning displays in both locations (US1)

1. Create or edit a `.cho`/`.crd`/`.pro`/`.txt` file containing:
   ```
   {title: Test Song}
   {artist: Test Artist}
   {tuning: Drop D}
   {key: D}
   [D]Hello world
   ```
2. Import it into the library and open it.
3. **Expect**: a "Tuning: Drop D" tag appears directly below "Test Artist".
4. **Expect**: "Tuning: Drop D" also appears in the metadata chip row, alongside "Key: D".

## Scenario 2 — Tuning-only song still shows the metadata row (FR-007)

1. Import a file with `{tuning: Open G}` but no `{key:}`, `{capo:}`, or `{time:}`.
2. **Expect**: the metadata row still appears, showing only "Tuning: Open G".

## Scenario 3 — No tuning means no tag anywhere (FR-009)

1. Import a file with no `{tuning:}` directive.
2. **Expect**: no tuning tag below the artist line, and no "Tuning:" entry in the metadata row (if the row appears at all, it's only for key/capo/time/preset).

## Scenario 4 — Preset directive displays (US2)

1. Import a file containing:
   ```
   {title: Preset Test}
   {artist: Test Artist}
   {preset: Lead Boost}
   ```
2. Open it.
3. **Expect**: "Preset: Lead Boost" appears in the metadata chip row. No duplicate below the artist line (preset is metadata-row-only, unlike tuning).

## Scenario 5 — Custom `x_*` directives remain no-ops (FR-006)

1. Import a file containing `{x_foo: bar}` (and no `preset`).
2. **Expect**: the file imports without error, and nothing related to `x_foo` is visible anywhere in the song view — identical to pre-005 behavior. `preset` is a first-class directive, not part of the `x_*` custom-directive mechanism.

## Scenario 6 — Repeated declarations, first wins (FR-008)

1. Import a file with two `{tuning:}` lines declaring different values (e.g. `{tuning: Drop D}` then later `{tuning: Standard}`).
2. **Expect**: the tag and chip both show "Drop D" (the first-declared value), not "Standard".

## Scenario 7 — Short aliases work, and don't collide with existing ones

1. Import a file containing:
   ```
   {title: Alias Test}
   {t: Not The Title?}
   {artist: Test Artist}
   {tu: Drop D}
   {p: Preset 3}
   ```
2. Open it.
3. **Expect**: the title is still "Alias Test" (the first `{title:}` declaration), NOT "Not The Title?" — confirming `{t:}` still means title, unaffected by this feature.
4. **Expect**: "Tuning: Drop D" appears below the artist and in the chip row (from `{tu:}`).
5. **Expect**: "Preset: Preset 3" appears in the chip row (from `{p:}`).

## Regression check

1. Open a song imported before this feature (no `tuning`/`preset` directives).
2. **Expect**: identical appearance to before this feature — no new blank space, no empty chip, no layout shift (FR-009, FR-010, SC-004).

## Pass/fail

All seven scenarios plus the regression check pass on-device, with `flutter analyze` clean and the new/updated `chordpro_parser_test.dart` cases green.
