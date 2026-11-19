import 'package:material_ui/material_ui.dart';
import 'package:flutter/scheduler.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../beat/beat_clock.dart';
import '../beat/bundled_beats.dart';
import '../lane/lane_plan.dart';
import '../lane/lane_view.dart';

const _offsetKey = 'visual_offset_ms';

/// Phase 1 prototype: the Setup and Land lane over a bundled beat, plus the
/// controls needed to check sync on a real phone.
class SetupAndLandScreen extends StatefulWidget {
  const SetupAndLandScreen({super.key, this.beat = practice90});

  final BundledBeat beat;

  @override
  State<SetupAndLandScreen> createState() => _SetupAndLandScreenState();
}

class _SetupAndLandScreenState extends State<SetupAndLandScreen>
    with SingleTickerProviderStateMixin {
  final _player = AudioPlayer();
  late final BeatClock _clock;
  late final Ticker _ticker;
  final _beat = ValueNotifier<double>(_restingBeat);

  LaneConfig _config = const LaneConfig();
  int _offsetMs = 0;
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _clock = BeatClock(
      grid: widget.beat.grid,
      positionSource: () => _player.position,
      loopLength: widget.beat.loopLength,
    );
    _ticker = createTicker((_) {
      if (_player.playing) _beat.value = _clock.beat;
    });
    _init();
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _offsetMs = prefs.getInt(_offsetKey) ?? 0;
      _clock.visualOffset = Duration(milliseconds: _offsetMs);
      await _player.setAsset(widget.beat.asset);
      await _player.setLoopMode(LoopMode.one);
      _beat.value = _restingBeat;
      if (mounted) setState(() => _ready = true);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  /// Before playback, park the lane so the first count-in tile sits just
  /// past the now line.
  static const double _restingBeat = -0.5;

  Future<void> _togglePlay() async {
    if (_player.playing) {
      await _player.stop();
      _ticker.stop();
      _clock.reset();
      await _player.seek(Duration.zero);
      _beat.value = _restingBeat;
    } else {
      _clock.reset();
      _ticker.start();
      _player.play();
    }
    setState(() {});
  }

  Future<void> _setOffset(int ms) async {
    setState(() => _offsetMs = ms);
    _clock.visualOffset = Duration(milliseconds: ms);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_offsetKey, ms);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _player.dispose();
    _beat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final planner = LanePlanner(_config);
    final playing = _player.playing;
    return Scaffold(
      appBar: AppBar(title: const Text('Setup and Land')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${widget.beat.title} · '
                '${_config.barsPerLine} bar${_config.barsPerLine == 1 ? '' : 's'} per line',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              _BeatPulse(beat: _beat, beatsPerBar: _config.beatsPerBar),
              Expanded(child: LaneView(beat: _beat, planner: planner)),
              const SizedBox(height: 16),
              if (_error != null)
                Text('Could not load the beat: $_error',
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
              _Settings(
                config: _config,
                enabled: !playing,
                onChanged: (c) => setState(() => _config = c),
              ),
              const SizedBox(height: 8),
              Text('Sync offset: $_offsetMs ms '
                  '(raise it if the tiles flash before you hear the beat)'),
              Slider(
                key: const Key('offset'),
                min: -250,
                max: 250,
                divisions: 50,
                value: _offsetMs.toDouble(),
                label: '$_offsetMs ms',
                onChanged: (v) => _setOffset(v.round()),
              ),
              FilledButton.icon(
                key: const Key('play'),
                onPressed: _ready ? _togglePlay : null,
                icon: Icon(playing ? Icons.stop : Icons.play_arrow),
                label: Text(playing ? 'Stop' : 'Start'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Four dots that light on each beat: the quickest way to eyeball sync
/// against the kick and snare.
class _BeatPulse extends StatelessWidget {
  const _BeatPulse({required this.beat, required this.beatsPerBar});

  final ValueNotifier<double> beat;
  final int beatsPerBar;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ValueListenableBuilder<double>(
      valueListenable: beat,
      builder: (context, b, _) {
        final idx = b.floor() % beatsPerBar;
        final fade = 1 - (b - b.floor());
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < beatsPerBar; i++)
              Container(
                margin: const EdgeInsets.all(6),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == idx && b >= 0
                      ? colors.primary.withValues(alpha: 0.3 + 0.7 * fade)
                      : colors.surfaceContainerHighest,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Settings extends StatelessWidget {
  const _Settings({
    required this.config,
    required this.enabled,
    required this.onChanged,
  });

  final LaneConfig config;
  final bool enabled;
  final ValueChanged<LaneConfig> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text('Bars per line'),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 1, label: Text('1')),
            ButtonSegment(value: 2, label: Text('2')),
            ButtonSegment(value: 4, label: Text('4')),
          ],
          selected: {config.barsPerLine},
          onSelectionChanged:
              enabled ? (s) => onChanged(config.copyWith(barsPerLine: s.first)) : null,
        ),
        const Text('Syllables'),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 1, label: Text('1')),
            ButtonSegment(value: 2, label: Text('2')),
            ButtonSegment(value: 3, label: Text('3')),
            ButtonSegment(value: 4, label: Text('4')),
          ],
          selected: {config.syllables},
          onSelectionChanged:
              enabled ? (s) => onChanged(config.copyWith(syllables: s.first)) : null,
        ),
        TextButton.icon(
          onPressed: enabled
              ? () => onChanged(config.copyWith(seed: config.seed + 1))
              : null,
          icon: const Icon(Icons.shuffle),
          label: const Text('New words'),
        ),
      ],
    );
  }
}
