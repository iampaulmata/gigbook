# Quickstart: Validating Outro Section Tag Support

## Prerequisites

- Flutter SDK installed and `flutter test` runnable from the repo root.
- The parser change described in `plan.md` implemented in
  `lib/services/chordpro_parser.dart` (see `contracts/chordpro-directive-grammar.md` for the
  exact directive/alias/output mapping).

## Automated validation

1. Run the parser test suite:
   ```sh
   flutter test test/services/chordpro_parser_test.dart
   ```
2. Confirm it includes (per Constitution Principle IV, written before the implementation) cases
   covering:
   - `{soo}` ... `{eoo}` produces a section labeled "Outro".
   - `{start_of_outro}` ... `{end_of_outro}` produces the identical result.
   - Mixed case (`{SOO}`, `{Start_Of_Outro}`) is recognized the same as lowercase.
   - An outro section with no matching end tag continues through end-of-file without error.
   - A file combining an outro section with other directives (metadata, verse, chorus, etc.)
     imports without error or dropped content.
3. Run the full analyzer/lint gate before considering the change complete:
   ```sh
   flutter analyze
   ```

## Manual/device validation (per the project's `run`/`verify` skills)

1. Create or edit a `.cho` test file containing, at minimum:
   ```
   {title: Outro Test}
   {soo}
   [G]This is the [D]outro section
   {eoo}
   ```
2. Import it into the running app (see the project's `run` skill for launching on the connected
   test device).
3. Open the song and confirm:
   - The block renders with a visible "OUTRO" section label, styled identically to Verse/Chorus/
     Bridge labels (same font size, weight, letter-spacing, and primary-color treatment).
   - Chords and lyrics within the outro render normally (not as raw tab text).
4. Repeat with `{start_of_outro}` / `{end_of_outro}` in place of `{soo}` / `{eoo}` and confirm
   identical rendering.

## Expected outcome

Both the short-form and long-form outro tags produce a visually distinct "Outro" section, matching
the existing Verse/Chorus/Bridge experience, with no parser errors and no unrelated content lost.
