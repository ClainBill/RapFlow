import 'dart:math';

/// Phase 1 target words: common words with plenty of rhymes, by syllable
/// count. The real rhyme engine replaces this in phase 2.
const Map<int, List<String>> targetWords = {
  1: ['flow', 'day', 'night', 'time', 'mind', 'game', 'cold', 'real'],
  2: ['pressure', 'money', 'motion', 'danger', 'power', 'story', 'later', 'yellow'],
  3: ['elevate', 'celebrate', 'energy', 'history', 'radio', 'dominate', 'vacation', 'believer'],
  4: ['motivation', 'complicated', 'celebration', 'dedication', 'elevator', 'information', 'generation'],
};

/// Picks a target word for a couplet. The same seed and couplet always give
/// the same word, so the lane can be redrawn every frame without flicker.
String pickTargetWord({required int syllables, required int couplet, int seed = 0}) {
  final words = targetWords[syllables];
  if (words == null || words.isEmpty) {
    throw ArgumentError.value(syllables, 'syllables', 'no words for this count');
  }
  final rnd = Random(seed * 7919 + couplet);
  return words[rnd.nextInt(words.length)];
}
