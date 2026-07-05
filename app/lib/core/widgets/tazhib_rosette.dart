import 'dart:math';

import 'package:flutter/material.dart';

/// A stroke-based rosette (شمسه) inspired by manuscript illumination —
/// the "ornamental moments" element of the design language
/// (DESIGN_SYSTEM.md §6). Pure vector, tinted by [color], so it works on
/// any surface in either theme.
class TazhibRosette extends StatelessWidget {
  const TazhibRosette({
    required this.size,
    required this.color,
    this.petals = 8,
    this.strokeWidth = 1.5,
    super.key,
  });

  final double size;
  final Color color;
  final int petals;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _RosettePainter(
          color: color,
          petals: petals,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _RosettePainter extends CustomPainter {
  const _RosettePainter({
    required this.color,
    required this.petals,
    required this.strokeWidth,
  });

  final Color color;
  final int petals;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final s = size.shortestSide;

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color;

    Offset polar(double radius, double angle) =>
        center + Offset(cos(angle), sin(angle)) * radius;

    // Inner circle.
    final innerR = 0.14 * s;
    canvas.drawCircle(center, innerR, stroke);

    // Petal ring: pointed leaves from the inner circle to the petal tips.
    final tipR = 0.34 * s;
    final baseSpread = pi / petals * 0.7;
    for (var i = 0; i < petals; i++) {
      final a = 2 * pi * i / petals;
      final base1 = polar(innerR, a - baseSpread);
      final base2 = polar(innerR, a + baseSpread);
      final tip = polar(tipR, a);
      final ctrl1 = polar(tipR * 0.82, a - baseSpread * 0.9);
      final ctrl2 = polar(tipR * 0.82, a + baseSpread * 0.9);

      final path = Path()
        ..moveTo(base1.dx, base1.dy)
        ..quadraticBezierTo(ctrl1.dx, ctrl1.dy, tip.dx, tip.dy)
        ..quadraticBezierTo(ctrl2.dx, ctrl2.dy, base2.dx, base2.dy);
      canvas.drawPath(path, stroke);
    }

    // Halo ring with pearl dots between petal tips.
    final haloR = 0.42 * s;
    canvas.drawCircle(center, haloR, stroke);
    for (var i = 0; i < petals; i++) {
      final a = 2 * pi * (i + 0.5) / petals;
      canvas.drawCircle(polar(haloR + 0.045 * s, a), 0.018 * s, fill);
    }
  }

  @override
  bool shouldRepaint(_RosettePainter oldDelegate) =>
      color != oldDelegate.color ||
      petals != oldDelegate.petals ||
      strokeWidth != oldDelegate.strokeWidth;
}
