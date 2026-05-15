import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_mood_tracker/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('MoodHomeScreen renders title, prompt, and empty state',
      (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('My Mood Tracker'), findsOneWidget);
    expect(find.text('How are you feeling?'), findsOneWidget);
    expect(find.text('No moods logged yet.'), findsOneWidget);
  });

  testWidgets('tapping a mood button logs an entry and renders a tile',
      (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Before tap: 'Happy' label appears only on the button.
    expect(find.text('Happy'), findsOneWidget);
    expect(find.text('No moods logged yet.'), findsOneWidget);

    await tester.tap(find.text('Happy'));
    await tester.pumpAndSettle();

    // After tap: 'Happy' appears twice (button + timeline tile) and the
    // empty-state placeholder is gone.
    expect(find.text('Happy'), findsNWidgets(2));
    expect(find.text('No moods logged yet.'), findsNothing);
  });
}
