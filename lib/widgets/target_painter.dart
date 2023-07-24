import 'package:flutter/material.dart';

class TargetPainter extends CustomPainter {
  List<Offset> targetPoints;

  TargetPainter(this.targetPoints);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (var point in targetPoints) {
      canvas.drawCircle(point, 20, paint); // Change the radius as needed
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}