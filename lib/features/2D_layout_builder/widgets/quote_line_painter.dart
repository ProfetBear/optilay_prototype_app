import 'package:flutter/material.dart';

class QuotePainter extends CustomPainter {
  final double length;
  final String? label;
  final double halfStrokeWidth = 0.5;

  QuotePainter(this.length, {this.label});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.red
          ..strokeWidth = halfStrokeWidth * 2;

    final double centerY = size.height / 2;
    const double arrowSize = 5.0;
    const double tickHeight = 6.0;

    // Main horizontal line
    canvas.drawLine(Offset(0, centerY), Offset(length, centerY), paint);

    // Start arrowhead
    canvas.drawLine(
      Offset(halfStrokeWidth * 2, centerY),
      Offset(arrowSize, centerY - arrowSize),
      paint,
    );
    canvas.drawLine(
      Offset(halfStrokeWidth * 2, centerY),
      Offset(arrowSize, centerY + arrowSize),
      paint,
    );

    // End arrowhead
    canvas.drawLine(
      Offset(length - halfStrokeWidth * 2, centerY),
      Offset(length - arrowSize, centerY - arrowSize),
      paint,
    );
    canvas.drawLine(
      Offset(length - halfStrokeWidth * 2, centerY),
      Offset(length - arrowSize, centerY + arrowSize),
      paint,
    );

    // Start vertical tick
    canvas.drawLine(
      Offset(0 + halfStrokeWidth, centerY - tickHeight),
      Offset(0 + halfStrokeWidth, centerY + tickHeight),
      paint,
    );

    // End vertical tick
    canvas.drawLine(
      Offset(length - halfStrokeWidth, centerY - tickHeight),
      Offset(length - halfStrokeWidth, centerY + tickHeight),
      paint,
    );

    if (label != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(color: Colors.red, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset((length - textPainter.width) / 2, -20));
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
