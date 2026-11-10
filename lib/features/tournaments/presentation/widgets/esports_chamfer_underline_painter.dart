import 'package:flutter/material.dart';

/// Pintor customizado que desenha o sublinhado luminoso com corte diagonal chanfrado (Esports Chamfer).
class EsportsChamferUnderlinePainter extends CustomPainter {
  final Color color;
  final Color glowColor;

  const EsportsChamferUnderlinePainter({
    required this.color,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double h = 3.5;
    const double slant = 6.0;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(slant, size.height - h)
      ..lineTo(size.width - slant, size.height - h)
      ..lineTo(size.width, size.height)
      ..close();

    // Brilho difuso neon na base
    final glowPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawPath(path, glowPaint);

    // Linha sólida iluminada chanfrada
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant EsportsChamferUnderlinePainter oldDelegate) =>
      color != oldDelegate.color || glowColor != oldDelegate.glowColor;
}
