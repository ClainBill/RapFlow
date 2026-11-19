import 'word_bank.dart';

enum TileKind {
  /// Before the first line starts.
  countIn,

  /// A free beat: rap anything.
  open,

  /// Last beat of the first line of a couplet: say the target word.
  target,

  /// Last beat of the second line: end on a rhyme for the target word.
  rhyme,
}

class LaneTile {
  const LaneTile({
    required this.beat,
    required this.kind,
    this.line,
    this.word,
    this.syllables = 0,
  });

  final int beat;
  final TileKind kind;
  final int? line;
  final String? word;
  final int syllables;

  bool get isLanding => kind == TileKind.target || kind == TileKind.rhyme;
}

class LaneConfig {
  const LaneConfig({
    this.barsPerLine = 1,
    this.syllables = 2,
    this.beatsPerBar = 4,
    this.countInBars = 1,
    this.seed = 0,
  })  : assert(barsPerLine > 0),
        assert(syllables >= 1 && syllables <= 4);

  final int barsPerLine;
  final int syllables;
  final int beatsPerBar;
  final int countInBars;
  final int seed;

  int get beatsPerLine => barsPerLine * beatsPerBar;

  LaneConfig copyWith({int? barsPerLine, int? syllables, int? seed}) => LaneConfig(
        barsPerLine: barsPerLine ?? this.barsPerLine,
        syllables: syllables ?? this.syllables,
        beatsPerBar: beatsPerBar,
        countInBars: countInBars,
        seed: seed ?? this.seed,
      );
}

/// Decides what every beat of the Setup and Land lane shows.
///
/// Lines come in couplets: line 1 lands on a target word of N syllables,
/// line 2 lands on "rhyme it" with the same N, then a new couplet starts.
class LanePlanner {
  const LanePlanner(this.config);

  final LaneConfig config;

  LaneTile tileAt(int beat) {
    final b = beat - config.countInBars * config.beatsPerBar;
    if (b < 0) return LaneTile(beat: beat, kind: TileKind.countIn);

    final line = b ~/ config.beatsPerLine;
    final isLast = b % config.beatsPerLine == config.beatsPerLine - 1;
    if (!isLast) return LaneTile(beat: beat, kind: TileKind.open, line: line);

    final couplet = line ~/ 2;
    final word = pickTargetWord(
      syllables: config.syllables,
      couplet: couplet,
      seed: config.seed,
    );
    return LaneTile(
      beat: beat,
      kind: line.isEven ? TileKind.target : TileKind.rhyme,
      line: line,
      word: word,
      syllables: config.syllables,
    );
  }

  /// Next landing tile at or after [beat], for the countdown ring.
  LaneTile nextLanding(int beat) {
    var b = beat;
    while (true) {
      final t = tileAt(b);
      if (t.isLanding) return t;
      b++;
    }
  }
}
