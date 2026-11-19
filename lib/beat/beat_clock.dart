import 'beat_grid.dart';
import 'loop_clock.dart';

/// The heart of the app: where are we on the beat grid right now?
///
/// It reads the player's real position every frame instead of running its
/// own timer, so the visuals cannot drift away from the music. [visualOffset]
/// is the per-device calibration: positive values delay the visuals, which
/// is what Bluetooth headphones need.
class BeatClock {
  BeatClock({
    required this.grid,
    required this.positionSource,
    Duration? loopLength,
    this.visualOffset = Duration.zero,
  }) : _loop = loopLength == null ? null : LoopClock(loopLength: loopLength);

  final BeatGrid grid;
  final Duration Function() positionSource;
  final LoopClock? _loop;
  Duration visualOffset;

  /// Unwrapped playback time, ignoring calibration.
  Duration get time {
    final raw = positionSource();
    return _loop?.unwrap(raw) ?? raw;
  }

  /// Fractional beat the user should be seeing right now.
  double get beat => grid.beatAt(time - visualOffset);

  void reset() => _loop?.reset();
}
