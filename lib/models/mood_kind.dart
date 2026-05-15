import 'package:flutter/material.dart';

enum MoodKind {
  veryHappy,
  happy,
  neutral,
  sad,
  verySad;
}

extension MoodKindProps on MoodKind {
  String get label {
    switch (this) {
      case MoodKind.veryHappy:
        return 'Very Happy';
      case MoodKind.happy:
        return 'Happy';
      case MoodKind.neutral:
        return 'Neutral';
      case MoodKind.sad:
        return 'Sad';
      case MoodKind.verySad:
        return 'Very Sad';
    }
  }

  Color get color {
    switch (this) {
      case MoodKind.veryHappy:
        return const Color(0xFF43A047); // green
      case MoodKind.happy:
        return const Color(0xFF8BC34A); // light green
      case MoodKind.neutral:
        return const Color(0xFFFFC107); // amber
      case MoodKind.sad:
        return const Color(0xFF42A5F5); // blue
      case MoodKind.verySad:
        return const Color(0xFF7E57C2); // deep purple
    }
  }
}
