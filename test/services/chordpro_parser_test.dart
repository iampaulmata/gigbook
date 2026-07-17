import 'package:flutter_test/flutter_test.dart';

import 'package:gigbook/services/chordpro_parser.dart';

void main() {
  group('ChordProParser', () {
    // ─── US1: metadata & section structure (FR-001–FR-011) ──────────────────
    group('US1 metadata and sections', () {
      test('captures title from {title:} and short alias {t:}', () {
        expect(ChordProParser.parse('{title: Amazing Grace}').title,
            'Amazing Grace');
        expect(ChordProParser.parse('{t: Amazing Grace}').title,
            'Amazing Grace');
      });

      test('captures subtitle from {subtitle:}/{st:} distinct from artist',
          () {
        final parsed = ChordProParser.parse(
            '{title: X}\n{subtitle: Hymn}\n{artist: John Newton}');
        expect(parsed.subtitle, 'Hymn');
        expect(parsed.artist, 'John Newton');

        final short = ChordProParser.parse('{title: X}\n{st: Hymn}');
        expect(short.subtitle, 'Hymn');
        expect(short.artist, isEmpty);
      });

      test('captures artist from {artist:}', () {
        expect(ChordProParser.parse('{artist: John Newton}').artist,
            'John Newton');
      });

      test('captures key, capo, tempo, and time signature', () {
        final parsed = ChordProParser.parse(
            '{key: G}\n{capo: 2}\n{tempo: 72}\n{time: 3/4}');
        expect(parsed.key, 'G');
        expect(parsed.capo, 2);
        expect(parsed.tempo, 72);
        expect(parsed.timeSignature, '3/4');
      });

      test('verse/chorus/bridge sections use long-form aliases too', () {
        final parsed = ChordProParser.parse(
            '{start_of_verse}\nline one\n{end_of_verse}\n'
            '{start_of_chorus}\nline two\n{end_of_chorus}\n'
            '{start_of_bridge}\nline three\n{end_of_bridge}');
        final labels = parsed.blocks.whereType<SectionBlock>().map((b) => b.label);
        expect(labels, containsAll(['Verse', 'Chorus', 'Bridge']));
      });

      test('unmatched section start runs through end of file', () {
        final parsed =
            ChordProParser.parse('{title: X}\n{soc}\nno end tag here');
        expect(parsed.blocks.whereType<SectionBlock>(), hasLength(1));
        expect(parsed.blocks.whereType<LyricBlock>(), hasLength(1));
      });

      test('{sot}/{eot} captures raw literal tab text with no chord extraction',
          () {
        final parsed = ChordProParser.parse(
            '{sot}\ne|--0--2--3--|\nB|--1--[3]------|\n{eot}');
        final tabBlocks = parsed.blocks.whereType<TabBlock>();
        expect(tabBlocks, hasLength(1));
        expect(tabBlocks.first.lines,
            ['e|--0--2--3--|', 'B|--1--[3]------|']);
        // Bracket characters inside a tab block are literal, not chords.
        expect(parsed.blocks.whereType<LyricBlock>(), isEmpty);
      });

      test('mixing short and long directive forms: first write wins', () {
        final parsed =
            ChordProParser.parse('{t: First}\n{title: Second}');
        expect(parsed.title, 'First');
      });

      test('falls back to first lyric line as title when no {title} given',
          () {
        final parsed = ChordProParser.parse('Just a plain lyric line');
        expect(parsed.title, 'Just a plain lyric line');
      });

      test('an unclosed {sot} at end of file still emits its captured lines',
          () {
        final parsed = ChordProParser.parse('{sot}\ne|--0--|');
        final tabBlocks = parsed.blocks.whereType<TabBlock>();
        expect(tabBlocks, hasLength(1));
        expect(tabBlocks.first.lines, ['e|--0--|']);
      });

      test(
          'extractMeta does not fold subtitle into artist (regression for the '
          'pre-existing conflation bug)', () {
        final meta = ChordProParser.extractMeta('{title: X}\n{subtitle: Hymn}');
        expect(meta.artist, isEmpty);

        final withArtist = ChordProParser.extractMeta(
            '{title: X}\n{subtitle: Hymn}\n{artist: John Newton}');
        expect(withArtist.artist, 'John Newton');
      });
    });

    // ─── Outro section tag support (spec 002, FR-001–FR-004) ────────────────
    group('Outro section', () {
      test('{soo}/{eoo} produces a SectionBlock labeled "Outro"', () {
        final parsed = ChordProParser.parse(
            '{soo}\n[G]This is the [D]outro section\n{eoo}');
        final labels =
            parsed.blocks.whereType<SectionBlock>().map((b) => b.label);
        expect(labels, contains('Outro'));
      });

      test('{start_of_outro}/{end_of_outro} produces an identical result to '
          '{soo}/{eoo}', () {
        final short = ChordProParser.parse(
            '{soo}\n[G]This is the [D]outro section\n{eoo}');
        final long = ChordProParser.parse(
            '{start_of_outro}\n[G]This is the [D]outro section\n{end_of_outro}');
        final shortLabels =
            short.blocks.whereType<SectionBlock>().map((b) => b.label).toList();
        final longLabels =
            long.blocks.whereType<SectionBlock>().map((b) => b.label).toList();
        expect(longLabels, shortLabels);
      });

      test('mixed-case outro directives are recognized identically to '
          'lowercase', () {
        final parsed = ChordProParser.parse(
            '{SOO}\n[G]This is the [D]outro section\n{EOO}');
        final labels =
            parsed.blocks.whereType<SectionBlock>().map((b) => b.label);
        expect(labels, contains('Outro'));

        final parsedLong = ChordProParser.parse(
            '{Start_Of_Outro}\nlyric line\n{End_Of_Outro}');
        final longLabels =
            parsedLong.blocks.whereType<SectionBlock>().map((b) => b.label);
        expect(longLabels, contains('Outro'));
      });

      test('an unclosed {soo} runs through end of file', () {
        final parsed =
            ChordProParser.parse('{title: X}\n{soo}\nno end tag here');
        expect(parsed.blocks.whereType<SectionBlock>(), hasLength(1));
        expect(parsed.blocks.whereType<LyricBlock>(), hasLength(1));
      });

      test('two outro blocks using mixed short/long forms both render as '
          'separate, correctly-ordered Outro sections', () {
        final parsed = ChordProParser.parse(
            '{soo}\nfirst outro\n{eoo}\n'
            '{start_of_outro}\nsecond outro\n{end_of_outro}');
        final sectionBlocks = parsed.blocks.whereType<SectionBlock>().toList();
        expect(sectionBlocks, hasLength(2));
        expect(sectionBlocks[0].label, 'Outro');
        expect(sectionBlocks[1].label, 'Outro');
      });

      test('an outro section combined with other directives imports without '
          'error or dropped content', () {
        final parsed = ChordProParser.parse(
            '{title: X}\n{sov}\nverse line\n{eov}\n{soo}\noutro line\n{eoo}');
        final labels =
            parsed.blocks.whereType<SectionBlock>().map((b) => b.label);
        expect(labels, containsAll(['Verse', 'Outro']));
        final allText = parsed.blocks
            .whereType<LyricBlock>()
            .map((b) => b.pairs.map((p) => p.lyricText).join())
            .join('\n');
        expect(allText, contains('verse line'));
        expect(allText, contains('outro line'));
      });
    });

    // ─── US2: styled annotation lines (FR-012–FR-015) ────────────────────────
    group('US2 annotation styles', () {
      AnnotationStyle styleOf(String content) =>
          ChordProParser.parse(content).blocks.whereType<AnnotationBlock>().first.style;

      test('{c:}/{comment:} produce greyBar style', () {
        expect(styleOf('{c: Repeat chorus x2}'), AnnotationStyle.greyBar);
        expect(styleOf('{comment: Repeat chorus x2}'), AnnotationStyle.greyBar);
      });

      test('{ci:}/{comment_italic:} produce italic style', () {
        expect(styleOf('{ci: softly}'), AnnotationStyle.italic);
        expect(styleOf('{comment_italic: softly}'), AnnotationStyle.italic);
      });

      test('{cb:}/{comment_box:} produce boxed style', () {
        expect(styleOf('{cb: Key change to D}'), AnnotationStyle.boxed);
        expect(
            styleOf('{comment_box: Key change to D}'), AnnotationStyle.boxed);
      });

      test('{highlight:} produces highlight style (not a background setter)',
          () {
        expect(styleOf('{highlight: Big finish!}'), AnnotationStyle.highlight);
      });

      test('{highlight:} no longer sets the standing background color', () {
        final parsed = ChordProParser.parse(
            '{title: X}\n{highlight: yellow}\n[G]lyric line');
        final lyricBlock = parsed.blocks.whereType<LyricBlock>().first;
        expect(lyricBlock.backgroundColor, isNull);
      });

      test('background/bgcolor/bgcolour still set the standing background',
          () {
        final parsed = ChordProParser.parse(
            '{title: X}\n{background: yellow}\nlyric line');
        final lyricBlock = parsed.blocks.whereType<LyricBlock>().first;
        expect(lyricBlock.backgroundColor, isNotNull);
      });
    });

    // ─── US3: color-coded text (FR-016–FR-020) ───────────────────────────────
    group('US3 color-coded text', () {
      test('standing {textcolour:}/{textcolour} colors lyric lines only, resets',
          () {
        final parsed = ChordProParser.parse(
            '{title: X}\n{textcolour: red}\nline one\n{textcolour}\nline two');
        final lyricBlocks = parsed.blocks.whereType<LyricBlock>().toList();
        expect(lyricBlocks[0].textColor, isNotNull);
        expect(lyricBlocks[1].textColor, isNull);
      });

      test('{textsize:}/{textfont:} are accepted with no data-model effect',
          () {
        final parsed = ChordProParser.parse(
            '{title: X}\n{textsize: 8}\n{textfont: sans}\nline one\n{textsize}\n{textfont}');
        // No exception thrown, and the lyric line is unaffected: LyricBlock
        // carries no font-size/font-family field at all (parser-level proof
        // that these directives cannot influence rendering).
        expect(parsed.blocks.whereType<LyricBlock>(), hasLength(1));
      });

      test('inline {tb:VALUE}...{tb} colors only its enclosed substring', () {
        final parsed =
            ChordProParser.parse('{title: X}\n{tb:yellow} chorus {tb}word');
        final pair = parsed.blocks.whereType<LyricBlock>().first.pairs.single;
        final styled = pair.lyric.where((r) => r.backgroundColor != null);
        final unstyled = pair.lyric.where((r) => r.backgroundColor == null);
        expect(styled.map((r) => r.text).join(), ' chorus ');
        expect(unstyled.map((r) => r.text).join(), 'word');
      });

      test('inline {tc:VALUE}...{tc} colors only its enclosed substring', () {
        final parsed =
            ChordProParser.parse('{title: X}\n{tc:black} lead {tc}word');
        final pair = parsed.blocks.whereType<LyricBlock>().first.pairs.single;
        final styled = pair.lyric.where((r) => r.textColor != null);
        expect(styled.map((r) => r.text).join(), ' lead ');
      });

      test('combined {tb:V}{tc:V}...{tc}{tb} applies both to the same span',
          () {
        final parsed = ChordProParser.parse(
            '{title: X}\n{tb:yellow}{tc:black} both {tc}{tb}after');
        final pair = parsed.blocks.whereType<LyricBlock>().first.pairs.single;
        final combined = pair.lyric.firstWhere((r) => r.text == ' both ');
        expect(combined.textColor, isNotNull);
        expect(combined.backgroundColor, isNotNull);
        final after = pair.lyric.firstWhere((r) => r.text == 'after');
        expect(after.textColor, isNull);
        expect(after.backgroundColor, isNull);
      });

      test('an inline span left unclosed styles only to end of line', () {
        final parsed =
            ChordProParser.parse('{title: X}\n{tb:yellow}rest of line');
        final pair = parsed.blocks.whereType<LyricBlock>().first.pairs.single;
        expect(pair.lyric.every((r) => r.backgroundColor != null), isTrue);
      });

      test('inline spans interleave correctly with [Chord] brackets', () {
        final parsed = ChordProParser.parse(
            '{title: X}\n{tb:yellow}[D]that saved a [G]wretch{tb} like me');
        final pairs = parsed.blocks.whereType<LyricBlock>().first.pairs;
        final gPair = pairs.firstWhere((p) => p.chord == 'G');
        // "wretch" (still inside the span) is styled; " like me" (after the
        // close tag) is not — both live in the same chord/lyric chunk.
        final wretchRun = gPair.lyric.firstWhere((r) => r.text == 'wretch');
        final restRun = gPair.lyric.firstWhere((r) => r.text == ' like me');
        expect(wretchRun.backgroundColor, isNotNull);
        expect(restRun.backgroundColor, isNull);
      });

      test('standing text color never recolors chord symbols', () {
        // Chord color is a rendering concern (ChordProRenderer never reads
        // LyricBlock.textColor for the chord Text, only for lyric Text), so
        // at the parser level we confirm the chord string itself is
        // unaffected by any color/text-run wrapping.
        final parsed = ChordProParser.parse(
            '{title: X}\n{textcolour: red}\n[G]lyric');
        final pair = parsed.blocks.whereType<LyricBlock>().first.pairs.first;
        expect(pair.chord, 'G');
      });
    });

    // ─── US4: live metadata insertion (FR-021–FR-022) ────────────────────────
    group('US4 live metadata insertion', () {
      String lyricTextOf(ParsedSong parsed) => parsed.blocks
          .whereType<LyricBlock>()
          .first
          .pairs
          .map((p) => p.lyricText)
          .join();

      test('%{capo} and %{key} resolve to the declared value in a lyric line',
          () {
        final parsed = ChordProParser.parse(
            '{title: X}\n{key: G}\n{capo: 2}\nCapo: %{capo}, key %{key}');
        expect(lyricTextOf(parsed), 'Capo: 2, key G');
      });

      test('%{...} resolves inside annotation lines too', () {
        final parsed =
            ChordProParser.parse('{title: X}\n{key: G}\n{capo: 2}\n{c: Capo %{capo}, key of %{key}}');
        final annotation = parsed.blocks.whereType<AnnotationBlock>().first;
        expect(annotation.text, 'Capo 2, key of G');
      });

      test('%{...} tracks a mid-file redeclaration of the referenced metadata',
          () {
        final parsed = ChordProParser.parse(
            '{title: X}\n{key: G}\nfirst %{key}\n{key: D}\nsecond %{key}');
        final lyricBlocks = parsed.blocks.whereType<LyricBlock>().toList();
        expect(lyricBlocks[0].pairs.map((p) => p.lyricText).join(), 'first G');
        expect(lyricBlocks[1].pairs.map((p) => p.lyricText).join(), 'second D');
        // The song's own stored key is still the first declaration.
        expect(parsed.key, 'G');
      });

      test('%{...} resolves to empty string when never declared', () {
        final parsed =
            ChordProParser.parse('{title: X}\nTempo is %{tempo} bpm');
        expect(lyricTextOf(parsed), 'Tempo is  bpm');
      });
    });

    // ─── US5: custom app-only directives (FR-023) ────────────────────────────
    group('US5 custom directives', () {
      test('{x_*:...} directives import without error and have no visible effect',
          () {
        final parsed = ChordProParser.parse(
            '{title: X}\n{x_gigbook_note: internal use}\nline one\n{x_someapp_thing: 42}\nline two');
        // No block of any kind carries the directive name or its value.
        final allText = parsed.blocks
            .map((b) => switch (b) {
                  AnnotationBlock(:final text) => text,
                  LyricBlock(:final pairs) =>
                    pairs.map((p) => p.lyricText).join(),
                  _ => '',
                })
            .join('\n');
        expect(allText, isNot(contains('x_gigbook_note')));
        expect(allText, isNot(contains('internal use')));
        expect(allText, isNot(contains('x_someapp_thing')));
        expect(allText, contains('line one'));
        expect(allText, contains('line two'));
      });
    });

    // ─── Tuning directive (spec 005, FR-001–FR-003, FR-007–FR-009) ──────────
    group('Tuning directive', () {
      test('{tuning:VALUE} sets ParsedSong.tuning', () {
        expect(ChordProParser.parse('{tuning: Drop D}').tuning, 'Drop D');
      });

      test('{tu:VALUE} short alias sets tuning too', () {
        expect(ChordProParser.parse('{tu: Open G}').tuning, 'Open G');
      });

      test('first declaration wins across a mix of {tuning:} and {tu:}', () {
        final parsed =
            ChordProParser.parse('{tuning: Drop D}\n{tu: Standard}');
        expect(parsed.tuning, 'Drop D');

        final reversed =
            ChordProParser.parse('{tu: Open G}\n{tuning: DADGAD}');
        expect(reversed.tuning, 'Open G');
      });

      test('a song with no tuning directive has a null tuning', () {
        expect(ChordProParser.parse('{title: X}').tuning, isNull);
      });

      test('{t:} still sets title, unaffected by the new tu alias', () {
        // Regression guard: `tu` was chosen specifically because `t` is
        // already title's alias (spec Clarifications) — this must never
        // become ambiguous.
        final parsed = ChordProParser.parse('{t: My Title}');
        expect(parsed.title, 'My Title');
        expect(parsed.tuning, isNull);
      });
    });

    // ─── Polish: whole-file regression (FR-001–FR-025) ───────────────────────
    test(
        'a file combining every directive from this feature imports without '
        'error and produces the expected structure', () {
      const content = '''
{title: Full Tag Sample}
{subtitle: Feature Verification}
{artist: Test Author}
{key: G}
{capo: 2}
{tempo: 96}
{time: 3/4}

{c: Capo %{capo}, key of %{key} - quiet intro}
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
''';

      // Must not throw (FR-025).
      final parsed = ChordProParser.parse(content);

      expect(parsed.title, 'Full Tag Sample');
      expect(parsed.subtitle, 'Feature Verification');
      expect(parsed.artist, 'Test Author');
      expect(parsed.key, 'G');
      expect(parsed.capo, 2);
      expect(parsed.tempo, 96);
      expect(parsed.timeSignature, '3/4');

      final annotations = parsed.blocks.whereType<AnnotationBlock>().toList();
      expect(annotations.map((a) => a.style), [
        AnnotationStyle.greyBar,
        AnnotationStyle.italic,
        AnnotationStyle.boxed,
        AnnotationStyle.highlight,
      ]);
      expect(annotations[0].text, 'Capo 2, key of G - quiet intro');

      final sections = parsed.blocks.whereType<SectionBlock>().map((s) => s.label);
      expect(sections, containsAll(['Verse', 'Chorus', 'Bridge']));

      final tabBlocks = parsed.blocks.whereType<TabBlock>();
      expect(tabBlocks, hasLength(1));
      expect(tabBlocks.first.lines, ['e|--0--2--3--|', 'B|--1--3------|']);

      final allText = parsed.blocks
          .map((b) => switch (b) {
                AnnotationBlock(:final text) => text,
                LyricBlock(:final pairs) => pairs.map((p) => p.lyricText).join(),
                TabBlock(:final lines) => lines.join('\n'),
                _ => '',
              })
          .join('\n');
      expect(allText, isNot(contains('x_gigbook_note')));
      expect(allText, isNot(contains('this must never be visible')));
      expect(allText, contains('Text size/font directives above must have no visible effect.'));
    });
  });
}
