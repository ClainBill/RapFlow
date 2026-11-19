import 'package:material_ui/material_ui.dart';

import 'beat_lane_painter.dart';
import 'lane_plan.dart';

/// The beat lane plus the cue line under it. [beat] is listened to directly
/// so only the painter and the cue repaint each frame.
class LaneView extends StatelessWidget {
  const LaneView({super.key, required this.beat, required this.planner});

  final ValueNotifier<double> beat;
  final LanePlanner planner;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: CustomPaint(
            painter: BeatLanePainter(
              beat: () => beat.value,
              planner: planner,
              colors: colors,
              repaint: beat,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<double>(
          valueListenable: beat,
          builder: (context, b, _) => Text(
            cueFor(planner, b),
            key: const Key('cue'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ],
    );
  }
}

/// What the user should be doing at beat [b], in words.
String cueFor(LanePlanner planner, double b) {
  final now = b.floor();
  final tile = planner.tileAt(now);
  if (tile.kind == TileKind.countIn) return 'Get ready…';
  final next = planner.nextLanding(now);
  final s = next.syllables == 1 ? 'syllable' : 'syllables';
  return switch (next.kind) {
    TileKind.target => 'Freestyle, then land on "${next.word}" (${next.syllables} $s)',
    TileKind.rhyme => 'End on a rhyme for "${next.word}"',
    _ => '',
  };
}
