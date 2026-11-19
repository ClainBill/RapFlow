/// Maps a playback time to a position on the musical grid.
///
/// Beat 0 is the first downbeat. Times before [downbeatOffset] give negative
/// beats, which the lane draws as count-in.
class BeatGrid {
  const BeatGrid({
    required this.bpm,
    this.downbeatOffset = Duration.zero,
    this.beatsPerBar = 4,
  }) : assert(bpm > 0);

  final double bpm;
  final Duration downbeatOffset;
  final int beatsPerBar;

  double get msPerBeat => 60000.0 / bpm;

  /// Fractional beat index at [time], e.g. 4.5 is halfway through beat 5.
  double beatAt(Duration time) =>
      (time - downbeatOffset).inMicroseconds / 1000.0 / msPerBeat;

  /// Playback time at which [beat] starts.
  Duration timeOfBeat(double beat) =>
      downbeatOffset + Duration(microseconds: (beat * msPerBeat * 1000).round());

  int barOf(int beat) => (beat / beatsPerBar).floor();
}
