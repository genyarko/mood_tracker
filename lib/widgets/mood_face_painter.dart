import 'package:flutter/material.dart';
import '../models/mood_kind.dart';

class MoodFacePainter extends CustomPainter {
  final MoodKind mood;

  const MoodFacePainter(this.mood);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.shortestSide / 2;

    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()..color = mood.color,
    );

    final whiteFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Eyes
    canvas.drawCircle(Offset(cx - r * 0.28, cy - r * 0.22), r * 0.1, whiteFill);
    canvas.drawCircle(Offset(cx + r * 0.28, cy - r * 0.22), r * 0.1, whiteFill);

    // Mouth: positive curveOffset = smile, negative = frown
    final curveOffset = switch (mood) {
      MoodKind.veryHappy => r * 0.28,
      MoodKind.happy => r * 0.16,
      MoodKind.neutral => 0.0,
      MoodKind.sad => -r * 0.16,
      MoodKind.verySad => -r * 0.28,
    };

    final mouthY = cy + r * 0.22;
    final halfW = r * 0.32;
    final mouthPath = Path()
      ..moveTo(cx - halfW, mouthY)
      ..quadraticBezierTo(cx, mouthY + curveOffset, cx + halfW, mouthY);

    canvas.drawPath(
      mouthPath,
      Paint()
        ..color = Colors.white
        ..strokeWidth = r * 0.08
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(MoodFacePainter oldDelegate) => oldDelegate.mood != mood;
}
