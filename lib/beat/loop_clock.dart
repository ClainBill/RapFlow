/// Turns a looping player's position (which jumps back to 0 at each loop)
/// into a time that keeps counting up, so the beat lane never rewinds.
class LoopClock {
  LoopClock({required this.loopLength});

  final Duration loopLength;
  int _loops = 0;
  Duration? _last;

  int get loops => _loops;

  /// Feed the raw player position; returns the unwrapped time.
  Duration unwrap(Duration raw) {
    final last = _last;
    // A jump back by more than half a loop means the player wrapped around.
    if (last != null && last - raw > loopLength ~/ 2) {
      _loops++;
    }
    _last = raw;
    return loopLength * _loops + raw;
  }

  void reset() {
    _loops = 0;
    _last = null;
  }
}
