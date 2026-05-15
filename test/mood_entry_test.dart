import 'package:flutter_test/flutter_test.dart';
import 'package:my_mood_tracker/models/mood_entry.dart';
import 'package:my_mood_tracker/models/mood_kind.dart';

void main() {
  test('MoodEntry round-trips through JSON for every MoodKind', () {
    for (final kind in MoodKind.values) {
      final entry = MoodEntry(
        id: 'test-${kind.name}',
        mood: kind,
        timestamp: DateTime(2026, 5, 15, 12, 0),
      );
      final decoded = MoodEntry.fromJson(entry.toJson());
      expect(decoded.id, entry.id);
      expect(decoded.mood, entry.mood);
      expect(decoded.timestamp, entry.timestamp);
    }
  });

  test('MoodEntry fromJson rejects unknown mood name', () {
    expect(
      () => MoodEntry.fromJson({
        'id': 'x',
        'mood': 'confused',
        'timestamp': '2026-05-15T12:00:00.000',
      }),
      throwsArgumentError,
    );
  });
}
