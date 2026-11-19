import 'package:flutter_test/flutter_test.dart';
import 'package:rap_trainer/beat/beat_clock.dart';
import 'package:rap_trainer/beat/beat_grid.dart';
import 'package:rap_trainer/beat/bundled_beats.dart';
import 'package:rap_trainer/beat/loop_clock.dart';

void main() {
  group('BeatGrid', () {
    test('90 BPM puts a beat every 666.7 ms', () {
      const g = BeatGrid(bpm: 90);
      expect(g.beatAt(Duration.zero), 0);
      expect(g.beatAt(const Duration(milliseconds: 2000)), closeTo(3, 1e-9));
      expect(g.timeOfBeat(4).inMilliseconds, 2666);
    });

    test('downbeat offset shifts beat 0 and gives negative count-in beats', () {
      const g = BeatGrid(bpm: 120, downbeatOffset: Duration(milliseconds: 250));
      expect(g.beatAt(const Duration(milliseconds: 250)), 0);
      expect(g.beatAt(Duration.zero), closeTo(-0.5, 1e-9));
      expect(g.timeOfBeat(2), const Duration(milliseconds: 1250));
    });

    test('barOf floors negative beats into bar -1', () {
      const g = BeatGrid(bpm: 90);
      expect(g.barOf(-1), -1);
      expect(g.barOf(0), 0);
      expect(g.barOf(7), 1);
    });
  });

  group('LoopClock', () {
    test('keeps counting up across loop wraps', () {
      final c = LoopClock(loopLength: const Duration(seconds: 10));
      expect(c.unwrap(const Duration(seconds: 9)), const Duration(seconds: 9));
      expect(c.unwrap(const Duration(milliseconds: 9990)),
          const Duration(milliseconds: 9990));
      expect(c.unwrap(const Duration(milliseconds: 20)),
          const Duration(milliseconds: 10020));
      expect(c.loops, 1);
    });

    test('small backward jitter is not a wrap', () {
      final c = LoopClock(loopLength: const Duration(seconds: 10));
      c.unwrap(const Duration(milliseconds: 5000));
      expect(c.unwrap(const Duration(milliseconds: 4990)),
          const Duration(milliseconds: 4990));
      expect(c.loops, 0);
    });
  });

  group('BeatClock', () {
    test('applies the visual offset so visuals lag the audio', () {
      var pos = const Duration(milliseconds: 1000);
      final clock = BeatClock(
        grid: const BeatGrid(bpm: 60),
        positionSource: () => pos,
        visualOffset: const Duration(milliseconds: 200),
      );
      expect(clock.beat, closeTo(0.8, 1e-9));
      pos = const Duration(milliseconds: 3000);
      expect(clock.beat, closeTo(2.8, 1e-9));
    });

    test('bundled beat loops on a whole bar', () {
      final len = practice90.loopLength.inMicroseconds / 1e6;
      expect(len, closeTo(16 * 4 * 60 / 90, 1e-3));
      final clock = BeatClock(
        grid: practice90.grid,
        positionSource: () => Duration.zero,
        loopLength: practice90.loopLength,
      );
      expect(clock.beat, 0);
    });
  });
}
