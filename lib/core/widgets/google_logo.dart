import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Renders the official multi-colored Google "G" logo using vector canvas paths.
class GoogleLogo extends StatelessWidget {
  final double size;

  const GoogleLogo({super.key, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;
    final double strokeWidth = s * 0.22;
    final double center = s / 2;
    final double radius = (s - strokeWidth) / 2;
    final Rect arcRect = Rect.fromCircle(center: Offset(center, center), radius: radius);

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // 1. Red Top Arc (approx -140 deg to -45 deg)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(arcRect, -math.pi * 0.75, math.pi * 0.52, false, paint);

    // 2. Yellow Left Arc (approx 135 deg to 225 deg / -135 to -45)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(arcRect, -math.pi * 1.25, math.pi * 0.52, false, paint);

    // 3. Green Bottom Arc (approx 40 deg to 135 deg)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(arcRect, math.pi * 0.22, math.pi * 0.55, false, paint);

    // 4. Blue Arc (Right side)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(arcRect, -math.pi * 0.23, math.pi * 0.45, false, paint);

    // 5. Blue Horizontal Inset Bar
    final Paint fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF4285F4);

    final Rect barRect = Rect.fromLTWH(
      center - strokeWidth * 0.1,
      center - strokeWidth / 2,
      radius + strokeWidth / 2 + strokeWidth * 0.1,
      strokeWidth,
    );
    canvas.drawRect(barRect, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
