import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'lane_plan.dart';

/// Draws the Setup and Land beat lane: beat tiles scroll right to left past
/// a fixed "now" line. Open tiles are outlined, landing tiles are filled and
/// show their word with one dot per syllable, and a ring closes in on the
/// next landing tile during the bar before it arrives.
class BeatLanePainter extends CustomPainter {
  BeatLanePainter({
    required this.beat,
    required this.planner,
    required this.colors,
    super.repaint,
  });

  /// Listenable value read at paint time, so the lane repaints every frame
  /// without rebuilding widgets.
  final ValueGetter<double> beat;
  final LanePlanner planner;
  final ColorScheme colors;

  static const double beatWidth = 76;
  static const double tileGap = 8;
  static const double nowFraction = 0.28;

  @override
  void paint(Canvas canvas, Size size) {
    final cur = beat();
    final nowX = size.width * nowFraction;
    final midY = size.height * 0.62;
    final tileH = math.min(64.0, size.height * 0.36);
    final bpb = planner.config.beatsPerBar;

    final first = (cur - nowX / beatWidth).floor() - 1;
    final last = (cur + (size.width - nowX) / beatWidth).ceil() + 1;

    for (var b = first; b <= last; b++) {
      final x = nowX + (b - cur) * beatWidth;
      final rect = Rect.fromLTWH(x + tileGap / 2, midY - tileH / 2,
          beatWidth - tileGap, tileH);
      final tile = planner.tileAt(b);

      // Bar line before each downbeat.
      if (b % bpb == 0) {
        canvas.drawLine(
          Offset(x, midY - tileH * 0.9),
          Offset(x, midY + tileH * 0.9),
          Paint()
            ..color = colors.outlineVariant
            ..strokeWidth = 1,
        );
      }

      // How strongly this tile glows: full on its beat, fading over the beat.
      final since = cur - b;
      final glow = since >= 0 && since < 1 ? 1 - since : 0.0;
      _drawTile(canvas, rect, tile, glow);
    }

    _drawCountdownRing(canvas, cur, nowX, midY, tileH);

    // The now line.
    canvas.drawLine(
      Offset(nowX, midY - tileH),
      Offset(nowX, midY + tileH),
      Paint()
        ..color = colors.primary
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawTile(Canvas canvas, Rect rect, LaneTile tile, double glow) {
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));
    final Color base = switch (tile.kind) {
      TileKind.countIn => colors.outlineVariant,
      TileKind.open => colors.outline,
      TileKind.target => colors.tertiary,
      TileKind.rhyme => colors.secondary,
    };

    if (tile.isLanding) {
      canvas.drawRRect(rrect, Paint()..color = base.withValues(alpha: 0.25 + 0.5 * glow));
    } else if (glow > 0) {
      canvas.drawRRect(rrect, Paint()..color = base.withValues(alpha: 0.35 * glow));
    }
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = tile.isLanding ? 2.5 : 1.5
        ..color = base,
    );

    if (tile.kind == TileKind.countIn) {
      final n = (tile.beat % planner.config.beatsPerBar) + 1;
      _text(canvas, '$n', rect.center, colors.onSurfaceVariant, 18);
    }

    if (tile.isLanding) {
      // Syllable dots inside the tile.
      final n = tile.syllables;
      const r = 4.0;
      final totalW = n * r * 2 + (n - 1) * 6;
      var dx = rect.center.dx - totalW / 2 + r;
      for (var i = 0; i < n; i++) {
        canvas.drawCircle(Offset(dx, rect.center.dy), r, Paint()..color = colors.onSurface);
        dx += r * 2 + 6;
      }
      // Word (or the rhyme cue) above the tile.
      final label = tile.kind == TileKind.target ? tile.word! : 'rhyme it';
      _text(canvas, label, Offset(rect.center.dx, rect.top - 18), base, 16,
          bold: true);
    }
  }

  void _drawCountdownRing(
      Canvas canvas, double cur, double nowX, double midY, double tileH) {
    final next = planner.nextLanding(cur.floor() < 0 ? 0 : cur.floor());
    final beatsAway = next.beat - cur;
    final bpb = planner.config.beatsPerBar;
    if (beatsAway <= 0 || beatsAway > bpb) return;
    final x = nowX + (next.beat - cur) * beatWidth + beatWidth / 2;
    final minR = tileH * 0.62;
    final r = minR + (beatsAway / bpb) * tileH * 1.6;
    canvas.drawCircle(
      Offset(x, midY),
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = colors.primary.withValues(alpha: 1 - beatsAway / bpb * 0.7),
    );
  }

  void _text(Canvas canvas, String s, Offset center, Color color, double size,
      {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(BeatLanePainter old) =>
      old.planner.config != planner.config || old.colors != colors;
}
