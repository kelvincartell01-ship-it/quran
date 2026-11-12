import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class IslamicPatternPainter extends CustomPainter {
  const IslamicPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    const spacing = 42.0;
    final path = Path();

    for (var x = -spacing; x < size.width + spacing; x += spacing) {
      for (var y = -spacing; y < size.height + spacing; y += spacing) {
        path
          ..moveTo(x, y - spacing / 2)
          ..lineTo(x + spacing / 2, y)
          ..lineTo(x, y + spacing / 2)
          ..lineTo(x - spacing / 2, y)
          ..close();
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant IslamicPatternPainter oldDelegate) => false;
}
