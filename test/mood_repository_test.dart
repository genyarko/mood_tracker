import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_mood_tracker/data/mood_repository.dart';
import 'package:my_mood_tracker/models/mood_entry.dart';
import 'package:my_mood_tracker/models/mood_kind.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('loadEntries returns empty when no data has been written', () async {
    final repo = MoodRepository();
    expect(await repo.loadEntries(), isEmpty);
  });

  test('addEntry persists across new repository instances', () async {
    final entry = MoodEntry(
      id: 'a',
      mood: MoodKind.happy,
      timestamp: DateTime(2026, 5, 15, 9, 30),
    );
    await MoodRepository().addEntry(entry);

    final loaded = await MoodRepository().loadEntries();
    expect(loaded, hasLength(1));
    expect(loaded.first.id, 'a');
    expect(loaded.first.mood, MoodKind.happy);
    expect(loaded.first.timestamp, DateTime(2026, 5, 15, 9, 30));
  });

  test('addEntry appends without dropping existing entries', () async {
    final repo = MoodRepository();
    await repo.addEntry(MoodEntry(
      id: '1',
      mood: MoodKind.sad,
      timestamp: DateTime(2026, 5, 14),
    ));
    await repo.addEntry(MoodEntry(
      id: '2',
      mood: MoodKind.veryHappy,
      timestamp: DateTime(2026, 5, 15),
    ));

    final loaded = await repo.loadEntries();
    expect(loaded.map((e) => e.id), ['1', '2']);
  });

  test('loadEntries skips corrupted entries instead of throwing', () async {
    SharedPreferences.setMockInitialValues({
      'mood_entries': jsonEncode([
        {
          'id': 'good',
          'mood': 'neutral',
          'timestamp': '2026-05-15T12:00:00.000',
        },
        {
          'id': 'bad',
          'mood': 'confused', // not a MoodKind value
          'timestamp': '2026-05-15T12:00:00.000',
        },
      ]),
    });

    final loaded = await MoodRepository().loadEntries();
    expect(loaded, hasLength(1));
    expect(loaded.first.id, 'good');
  });
}
