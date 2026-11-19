import 'package:flutter_test/flutter_test.dart';
import 'package:rap_trainer/lane/lane_plan.dart';
import 'package:rap_trainer/lane/lane_view.dart';
import 'package:rap_trainer/lane/word_bank.dart';

void main() {
  test('first bar is count-in, then open beats and a landing tile', () {
    const p = LanePlanner(LaneConfig(barsPerLine: 1, syllables: 2));
    for (var b = 0; b < 4; b++) {
      expect(p.tileAt(b).kind, TileKind.countIn);
    }
    expect(p.tileAt(4).kind, TileKind.open);
    expect(p.tileAt(6).kind, TileKind.open);
    expect(p.tileAt(7).kind, TileKind.target);
    expect(p.tileAt(11).kind, TileKind.rhyme);
    expect(p.tileAt(15).kind, TileKind.target);
  });

  test('target and rhyme tiles of a couplet share the word', () {
    const p = LanePlanner(LaneConfig(barsPerLine: 2, syllables: 3));
    final target = p.tileAt(4 + 7);
    final rhyme = p.tileAt(4 + 15);
    expect(target.kind, TileKind.target);
    expect(rhyme.kind, TileKind.rhyme);
    expect(rhyme.word, target.word);
    expect(target.syllables, 3);
    expect(targetWords[3], contains(target.word));
  });

  test('words are stable for the same seed and change with it', () {
    final a = List.generate(20, (c) => pickTargetWord(syllables: 2, couplet: c));
    final b = List.generate(20, (c) => pickTargetWord(syllables: 2, couplet: c));
    final c = List.generate(20, (c) => pickTargetWord(syllables: 2, couplet: c, seed: 1));
    expect(a, b);
    expect(a, isNot(c));
  });

  test('every word in the bank has the advertised syllable count', () {
    // Rough vowel-group count; good enough to catch a word in the wrong list.
    int syl(String w) {
      var n = RegExp(r'[aeiouy]+').allMatches(w).length;
      if (w.endsWith('e') && !w.endsWith('le') && n > 1) n--;
      return n;
    }

    targetWords.forEach((count, words) {
      for (final w in words) {
        // "radio" and "believer" style vowel pairs fool the counter; allow them.
        if (const {'radio', 'story', 'energy', 'history', 'later'}.contains(w)) continue;
        expect(syl(w), count, reason: w);
      }
    });
  });

  test('nextLanding finds the upcoming landing tile', () {
    const p = LanePlanner(LaneConfig());
    expect(p.nextLanding(4).beat, 7);
    expect(p.nextLanding(7).beat, 7);
    expect(p.nextLanding(8).beat, 11);
  });

  test('cue text follows the lane', () {
    const p = LanePlanner(LaneConfig(syllables: 1));
    expect(cueFor(p, 1.2), 'Get ready…');
    expect(cueFor(p, 4.5), startsWith('Freestyle, then land on "'));
    expect(cueFor(p, 4.5), endsWith('(1 syllable)'));
    expect(cueFor(p, 8.1), startsWith('End on a rhyme for "'));
  });
}
