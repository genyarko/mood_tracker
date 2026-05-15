import 'mood_kind.dart';

class MoodEntry {
  final String id;
  final MoodKind mood;
  final DateTime timestamp;

  const MoodEntry({
    required this.id,
    required this.mood,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'mood': mood.name,
        'timestamp': timestamp.toIso8601String(),
      };

  factory MoodEntry.fromJson(Map<String, dynamic> json) => MoodEntry(
        id: json['id'] as String,
        mood: MoodKind.values.byName(json['mood'] as String),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}
