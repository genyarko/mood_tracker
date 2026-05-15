import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/mood_entry.dart';

class MoodRepository {
  static const _key = 'mood_entries';

  Future<List<MoodEntry>> loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => MoodEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addEntry(MoodEntry entry) async {
    final entries = await loadEntries();
    entries.add(entry);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }
}
