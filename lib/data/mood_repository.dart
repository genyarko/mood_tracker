import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/mood_entry.dart';

class MoodRepository {
  static const _key = 'mood_entries';

  Future<List<MoodEntry>> loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    return _decode(prefs.getString(_key));
  }

  Future<void> addEntry(MoodEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = _decode(prefs.getString(_key))..add(entry);
    await prefs.setString(
      _key,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }

  List<MoodEntry> _decode(String? raw) {
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    final entries = <MoodEntry>[];
    for (final item in list) {
      try {
        entries.add(MoodEntry.fromJson(item as Map<String, dynamic>));
      } catch (_) {
        // Skip corrupted/foreign entry rather than failing the whole load.
      }
    }
    return entries;
  }
}
