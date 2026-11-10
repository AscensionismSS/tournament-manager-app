import 'package:flutter/material.dart';
import '../../../../../core/theme/theme.dart';
import 'bracket_tree_models.dart';

/// Painter de alta performance (GPU) que desenha as linhas de chaveamento (Elbow Connectors).
/// Traça curvas suaves nos cantos e acende linhas de confronto finalizado com brilho temático.
class BracketTreePainter extends CustomPainter {
  final List<BracketConnection> connections;
  final Color defaultLineColor;
  final Color activeLineColor;

  const BracketTreePainter({
    required this.connections,
    this.defaultLineColor = AppColors.border,
    this.activeLineColor = AppColors.dotaGold,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (connections.isEmpty) return;

    final defaultPaint = Paint()
      ..color = defaultLineColor.withValues(alpha: 0.8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = activeLineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = activeLineColor.withValues(alpha: 0.3)
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    for (final conn in connections) {
      final path = _buildSmoothElbowPath(conn.from, conn.to);

      if (conn.isWinnerPath) {
        // Desenha brilho de vitória no fundo + linha principal
        canvas.drawPath(path, glowPaint);
        canvas.drawPath(path, activePaint);
      } else {
        canvas.drawPath(path, defaultPaint);
      }
    }
  }

  /// Constrói um caminho ortogonal com cantos suavemente curvados
  Path _buildSmoothElbowPath(Offset from, Offset to) {
    final path = Path();
    path.moveTo(from.dx, from.dy);

    // Se a partida estiver na mesma linha horizontal, traça direto
    if ((from.dy - to.dy).abs() < 1.0) {
      path.lineTo(to.dx, to.dy);
      return path;
    }

    // Se a conexão pular mais de uma coluna (ex: Upper Final indo para a Grande Final),
    // a virada vertical ocorre 22px antes do card de destino, mantendo a linha horizontal
    // no topo pelo espaço vazio!
    final double midX =
        (to.dx - from.dx > 60.0) ? (to.dx - 22.0) : ((from.dx + to.dx) / 2);

    const double radius = 8.0;
    final bool goingDown = to.dy > from.dy;
    final double actualRadius =
        radius.clamp(0.0, ((to.dy - from.dy).abs() / 2));

    // 1. Reta horizontal de saída
    path.lineTo(midX - actualRadius, from.dy);

    // 2. Curva para a direção vertical
    path.quadraticBezierTo(
      midX,
      from.dy,
      midX,
      from.dy + (goingDown ? actualRadius : -actualRadius),
    );

    // 3. Reta vertical conectora
    path.lineTo(midX, to.dy + (goingDown ? -actualRadius : actualRadius));

    // 4. Curva de entrada para a horizontal de destino
    path.quadraticBezierTo(
      midX,
      to.dy,
      midX + actualRadius,
      to.dy,
    );

    // 5. Reta horizontal de entrada no card de destino
    path.lineTo(to.dx, to.dy);

    return path;
  }

  @override
  bool shouldRepaint(covariant BracketTreePainter oldDelegate) {
    return oldDelegate.connections != connections ||
        oldDelegate.activeLineColor != activeLineColor ||
        oldDelegate.defaultLineColor != defaultLineColor;
  }
}
