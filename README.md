# RapFlow

An offline-first Flutter app for Android to practise rap flow, rhyming and
freestyle over beats. Design doc: https://claude.ai/artifact/2SjfRnUDCvhwnw6oLD4im3

## Phase 1: beat-sync prototype

The riskiest part of the app is keeping visuals locked to the music, so phase 1
proves that with the **Setup and Land** lane over a bundled beat:

- Beat tiles scroll right to left past a fixed *now* line.
- Open tiles are free beats: rap anything.
- The last beat of a line is a landing tile showing a target word, with one dot
  per syllable. The next line's landing tile says *rhyme it*.
- A ring closes in on each landing tile during the bar before it.
- Settings: 1, 2 or 4 bars per line, 1 to 4 syllables, new words, and a sync
  offset slider for headphone latency (saved on the device).

No mic, speech recognition or scoring yet.

### Sync gate

Phase 1 is done when the tiles stay within about 20 ms of the beat for a full
3-minute session on a real phone (Samsung S22 Ultra). To check:

1. Run the app with wired headphones or the phone speaker.
2. Press Start and watch the four beat dots and the tiles crossing the now
   line against the kick and snare.
3. If the visuals feel early or late, move the sync offset slider until they
   line up, then leave it running for at least 3 minutes (about 4 loops of the
   beat) and check it never drifts.

## Running

```sh
flutter pub get
flutter run            # emulator or a phone with USB debugging
flutter test           # unit and widget tests
flutter analyze
```

## Code map

| Path | What it does |
| --- | --- |
| `lib/beat/beat_grid.dart` | Maps playback time to fractional beats (BPM, downbeat offset) |
| `lib/beat/loop_clock.dart` | Unwraps a looping player's position so time keeps counting up |
| `lib/beat/beat_clock.dart` | Reads the player's real position every frame, applies calibration |
| `lib/beat/bundled_beats.dart` | Beats shipped with the app and their exact grids |
| `lib/lane/lane_plan.dart` | Decides what each beat tile shows (count-in, open, target, rhyme) |
| `lib/lane/word_bank.dart` | Phase 1 target words by syllable count |
| `lib/lane/beat_lane_painter.dart` | Draws the lane, tiles, syllable dots and countdown ring |
| `lib/screens/setup_and_land_screen.dart` | The prototype screen and its controls |
| `tool/make_practice_beat.py` | Synthesises the bundled 90 BPM practice beat (our own, royalty-free) |
