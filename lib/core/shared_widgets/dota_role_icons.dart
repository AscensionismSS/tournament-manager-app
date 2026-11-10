import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Tipos de funções oficiais do Dota 2
enum DotaRoleType {
  safeLane('Safe Lane', 'safe_lane', 'Carregador (Pos 1)'),
  midLane('Mid Lane', 'mid_lane', 'Meio (Pos 2)'),
  offLane('Off Lane', 'off_lane', 'Trilha Longa (Pos 3)'),
  support('Support', 'support', 'Suporte Suave (Pos 4)'),
  hardSupport('Hard Support', 'hard_support', 'Suporte Total (Pos 5)'),
  flex('Todas as Funções', 'flex', 'Coringa / Flexível');

  final String label;
  final String keyName;
  final String description;

  const DotaRoleType(this.label, this.keyName, this.description);

  Color get officialColor {
    switch (this) {
      case DotaRoleType.safeLane:
        return AppColors.feedbackError;
      case DotaRoleType.midLane:
        return AppColors.dotaGold;
      case DotaRoleType.offLane:
        return AppColors.feedbackSuccess;
      case DotaRoleType.support:
        return AppColors.feedbackInfo;
      case DotaRoleType.hardSupport:
        return AppColors.dotaRoleHardSupport;
      case DotaRoleType.flex:
        return AppColors.dotaRoleFlex;
    }
  }

  static DotaRoleType? fromKey(String? key) {
    if (key == null) return null;
    final normalized = key.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
    for (final r in DotaRoleType.values) {
      if (r.keyName == normalized || r.name.toLowerCase() == normalized) {
        return r;
      }
    }
    // Fallbacks para nomes comuns
    if (normalized.contains('carry') || normalized.contains('safe') || normalized.contains('pos1') || normalized.contains('pos_1')) return safeLane;
    if (normalized.contains('mid') || normalized.contains('pos2') || normalized.contains('pos_2')) return midLane;
    if (normalized.contains('off') || normalized.contains('pos3') || normalized.contains('pos_3')) return offLane;
    if (normalized.contains('hard') || normalized.contains('pos5') || normalized.contains('pos_5') || normalized.contains('sup5') || normalized.contains('sup_5') || normalized.contains('sup2')) return hardSupport;
    if (normalized.contains('sup') || normalized.contains('pos4') || normalized.contains('pos_4') || normalized.contains('sup4') || normalized.contains('sup_4') || normalized.contains('soft')) return support;
    if (normalized.contains('flex') || normalized.contains('all')) return flex;
    return null;
  }
}

/// Widget padronizado do Design System para exibir as funções (roles) de um jogador
/// com alto contraste, hierarquia visual e espaçamento otimizado.
class DotaRolesDisplay extends StatelessWidget {
  final DotaRoleType? preferredRole;
  final List<DotaRoleType> secondaryRoles;
  final double iconSize;
  final double boxWidth;
  final double boxHeight;
  final double spacing;
  final bool showBoxes;
  final int maxSecondary;

  const DotaRolesDisplay({
    super.key,
    this.preferredRole,
    this.secondaryRoles = const [],
    this.iconSize = 15.0,
    this.boxWidth = 24.0,
    this.boxHeight = 24.0,
    this.spacing = 5.0,
    this.showBoxes = true,
    this.maxSecondary = 4,
  });

  /// Construtor de conveniência para instanciar a partir de strings brutas vindas da API
  factory DotaRolesDisplay.fromStrings({
    Key? key,
    List<String> rawRoles = const [],
    String? preferredRoleKey,
    double iconSize = 15.0,
    double boxWidth = 24.0,
    double boxHeight = 24.0,
    double spacing = 5.0,
    bool showBoxes = true,
    int maxSecondary = 4,
  }) {
    DotaRoleType? pref;
    if (preferredRoleKey != null && preferredRoleKey.isNotEmpty) {
      pref = DotaRoleType.fromKey(preferredRoleKey);
    }

    final secondary = <DotaRoleType>[];
    for (int i = 0; i < rawRoles.length; i++) {
      final parsed = DotaRoleType.fromKey(rawRoles[i]);
      if (parsed != null) {
        if (pref == null && i == 0) {
          pref = parsed;
        } else if (parsed != pref && !secondary.contains(parsed)) {
          secondary.add(parsed);
        }
      }
    }

    pref ??= DotaRoleType.flex;

    return DotaRolesDisplay(
      key: key,
      preferredRole: pref,
      secondaryRoles: secondary,
      iconSize: iconSize,
      boxWidth: boxWidth,
      boxHeight: boxHeight,
      spacing: spacing,
      showBoxes: showBoxes,
      maxSecondary: maxSecondary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pref = preferredRole;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (pref != null)
          _buildRoleBadge(
            role: pref,
            isHighlighted: true,
          ),
        if (secondaryRoles.isNotEmpty) ...[
          if (pref != null) SizedBox(width: spacing),
          for (int i = 0; i < secondaryRoles.take(maxSecondary).length; i++) ...[
            if (i > 0) SizedBox(width: spacing),
            _buildRoleBadge(
              role: secondaryRoles[i],
              isHighlighted: false,
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildRoleBadge({
    required DotaRoleType role,
    required bool isHighlighted,
  }) {
    final color = role.officialColor;

    final badgeWidget = showBoxes
        ? Container(
            width: boxWidth,
            height: boxHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isHighlighted
                  ? color.withValues(alpha: 0.22)
                  : color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isHighlighted
                    ? color.withValues(alpha: 0.90)
                    : color.withValues(alpha: 0.55),
                width: 1.0,
              ),
            ),
            child: DotaRoleIcon(
              role: role,
              size: iconSize,
              color: color,
            ),
          )
        : DotaRoleIcon(
            role: role,
            size: iconSize,
            color: isHighlighted
                ? color
                : color.withValues(alpha: 0.80),
          );

    return Tooltip(
      message: isHighlighted
          ? '${role.label} ★ (Preferida) • ${role.description}'
          : '${role.label} (Secundária) • ${role.description}',
      child: badgeWidget,
    );
  }
}

/// Widget vetorial que renderiza com máxima fidelidade os ícones de Role do Dota 2.
class DotaRoleIcon extends StatelessWidget {
  final DotaRoleType role;
  final double size;
  final Color color;

  const DotaRoleIcon({
    super.key,
    required this.role,
    this.size = 18.0,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DotaRolePainter(role: role, color: color),
      ),
    );
  }
}

class _DotaRolePainter extends CustomPainter {
  final DotaRoleType role;
  final Color color;

  _DotaRolePainter({required this.role, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paintFill = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final paintStroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.3, size.width * 0.09)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    switch (role) {
      case DotaRoleType.safeLane:
        _drawSafeLaneSword(canvas, size, paintFill, paintStroke);
        break;
      case DotaRoleType.midLane:
        _drawMidLaneCross(canvas, size, paintStroke, paintFill);
        break;
      case DotaRoleType.offLane:
        _drawOffLaneShield(canvas, size, paintFill, paintStroke);
        break;
      case DotaRoleType.support:
        _drawSupportHand(canvas, size, paintFill, isHard: false);
        break;
      case DotaRoleType.hardSupport:
        _drawSupportHand(canvas, size, paintFill, isHard: true);
        break;
      case DotaRoleType.flex:
        _drawFlexVortex(canvas, size, paintStroke, paintFill);
        break;
    }
  }

  /// Safe Lane: Espada clássica apontando 45° nordeste com guarda e lâmina precisa
  void _drawSafeLaneSword(Canvas canvas, Size size, Paint fill, Paint stroke) {
    final w = size.width;
    final h = size.height;

    final path = Path();
    path.moveTo(w * 0.40, h * 0.54);
    path.lineTo(w * 0.76, h * 0.18);
    path.lineTo(w * 0.82, h * 0.18); // ponta
    path.lineTo(w * 0.82, h * 0.24);
    path.lineTo(w * 0.46, h * 0.60);
    path.close();
    canvas.drawPath(path, fill);

    // Guarda cruzada
    final guard = Path();
    guard.moveTo(w * 0.32, h * 0.46);
    guard.lineTo(w * 0.54, h * 0.68);
    guard.lineTo(w * 0.48, h * 0.74);
    guard.lineTo(w * 0.26, h * 0.52);
    guard.close();
    canvas.drawPath(guard, fill);

    // Cabo e Pomo
    final hilt = Path();
    hilt.moveTo(w * 0.37, h * 0.63);
    hilt.lineTo(w * 0.22, h * 0.78);
    hilt.lineTo(w * 0.18, h * 0.82);
    hilt.lineTo(w * 0.16, h * 0.80);
    hilt.lineTo(w * 0.20, h * 0.76);
    hilt.lineTo(w * 0.31, h * 0.57);
    hilt.close();
    canvas.drawPath(hilt, fill);

    // Pomo arredondado
    canvas.drawCircle(Offset(w * 0.18, h * 0.82), w * 0.065, fill);
  }

  /// Mid Lane: Círculo retículo com diagonal indicando a rota central
  void _drawMidLaneCross(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.5);
    final radius = w * 0.38;

    // Círculo externo
    canvas.drawCircle(center, radius, stroke);

    // Linha diagonal cortando o centro (caminho do mid)
    canvas.drawLine(
      Offset(w * 0.18, h * 0.82),
      Offset(w * 0.82, h * 0.18),
      stroke..strokeWidth = w * 0.10,
    );

    // Triângulos das pontas externas opostas
    final topArrow = Path();
    topArrow.moveTo(w * 0.74, h * 0.12);
    topArrow.lineTo(w * 0.90, h * 0.10);
    topArrow.lineTo(w * 0.88, h * 0.26);
    topArrow.close();
    canvas.drawPath(topArrow, fill);

    final botArrow = Path();
    botArrow.moveTo(w * 0.26, h * 0.88);
    botArrow.lineTo(w * 0.10, h * 0.90);
    botArrow.lineTo(w * 0.12, h * 0.74);
    botArrow.close();
    canvas.drawPath(botArrow, fill);
  }

  /// Off Lane: Escudo heráldico com contorno amplo e raio contrastante
  void _drawOffLaneShield(Canvas canvas, Size size, Paint fill, Paint stroke) {
    final w = size.width;
    final h = size.height;

    // Contorno do Escudo ocupando 80% do canvas
    final shield = Path();
    shield.moveTo(w * 0.10, h * 0.12);
    shield.lineTo(w * 0.90, h * 0.12);
    shield.lineTo(w * 0.90, h * 0.52);
    shield.quadraticBezierTo(w * 0.90, h * 0.82, w * 0.50, h * 0.94);
    shield.quadraticBezierTo(w * 0.10, h * 0.82, w * 0.10, h * 0.52);
    shield.close();
    canvas.drawPath(shield, fill);

    // Raio recortado no meio com contraste escuro universal
    final bolt = Path();
    bolt.moveTo(w * 0.57, h * 0.20);
    bolt.lineTo(w * 0.36, h * 0.50);
    bolt.lineTo(w * 0.52, h * 0.50);
    bolt.lineTo(w * 0.43, h * 0.82);
    bolt.lineTo(w * 0.66, h * 0.46);
    bolt.lineTo(w * 0.50, h * 0.46);
    bolt.close();

    final darkCut = Paint()
      ..color = Colors.black.withValues(alpha: 0.65)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawPath(bolt, darkCut);
  }

  /// Suportes (Pos 4 / 5): Mão aberta embaixo segurando Fogo (Pos 4) ou Estrelas/Sparkles (Pos 5)
  void _drawSupportHand(Canvas canvas, Size size, Paint fill, {required bool isHard}) {
    final w = size.width;
    final h = size.height;

    // 1. Mão estendida encorpada (base sólida)
    final hand = Path();
    hand.moveTo(w * 0.08, h * 0.66);
    hand.lineTo(w * 0.28, h * 0.66);
    hand.quadraticBezierTo(w * 0.48, h * 0.76, w * 0.72, h * 0.76);
    hand.quadraticBezierTo(w * 0.92, h * 0.76, w * 0.94, h * 0.64);
    hand.lineTo(w * 0.90, h * 0.58);
    hand.quadraticBezierTo(w * 0.78, h * 0.68, w * 0.62, h * 0.66);
    hand.lineTo(w * 0.35, h * 0.60);
    hand.lineTo(w * 0.22, h * 0.54);
    hand.quadraticBezierTo(w * 0.28, h * 0.46, w * 0.36, h * 0.48);
    hand.lineTo(w * 0.34, h * 0.44);
    hand.quadraticBezierTo(w * 0.18, h * 0.44, w * 0.12, h * 0.54);
    hand.lineTo(w * 0.08, h * 0.56);
    hand.close();
    canvas.drawPath(hand, fill);

    if (isHard) {
      // Hard Support: 3 estrelas brilhantes grandes e nítidas
      _drawSparkle(canvas, Offset(w * 0.52, h * 0.26), w * 0.22, fill);
      _drawSparkle(canvas, Offset(w * 0.26, h * 0.18), w * 0.15, fill);
      _drawSparkle(canvas, Offset(w * 0.76, h * 0.20), w * 0.14, fill);
    } else {
      // Support: Chama de fogo encorpada e nítida
      final flame = Path();
      flame.moveTo(w * 0.52, h * 0.10);
      flame.quadraticBezierTo(w * 0.74, h * 0.22, w * 0.74, h * 0.42);
      flame.quadraticBezierTo(w * 0.72, h * 0.56, w * 0.52, h * 0.56);
      flame.quadraticBezierTo(w * 0.30, h * 0.56, w * 0.30, h * 0.42);
      flame.quadraticBezierTo(w * 0.30, h * 0.28, w * 0.44, h * 0.20);
      flame.quadraticBezierTo(w * 0.42, h * 0.32, w * 0.50, h * 0.30);
      flame.quadraticBezierTo(w * 0.44, h * 0.18, w * 0.52, h * 0.10);
      flame.close();
      canvas.drawPath(flame, fill);
    }
  }

  /// Estrela de 4 pontas (sparkle) nítida e ampla
  void _drawSparkle(Canvas canvas, Offset center, double r, Paint fill) {
    final p = Path();
    p.moveTo(center.dx, center.dy - r);
    p.quadraticBezierTo(center.dx, center.dy, center.dx + r, center.dy);
    p.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + r);
    p.quadraticBezierTo(center.dx, center.dy, center.dx - r, center.dy);
    p.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - r);
    p.close();
    canvas.drawPath(p, fill);
  }

  /// Flex / Coringa: Vortex orbital encorpado e equilibrado
  void _drawFlexVortex(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.5);
    final radius = w * 0.39;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final boldStroke = Paint()
      ..color = stroke.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, w * 0.10)
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawArc(rect, 0.2, math.pi * 0.78, false, boldStroke);
    canvas.drawArc(rect, math.pi * 1.2, math.pi * 0.78, false, boldStroke);

    // Setas encorpadas nas pontas
    final arrow1 = Path();
    arrow1.moveTo(w * 0.86, h * 0.68);
    arrow1.lineTo(w * 0.96, h * 0.54);
    arrow1.lineTo(w * 0.78, h * 0.50);
    arrow1.close();
    canvas.drawPath(arrow1, fill);

    final arrow2 = Path();
    arrow2.moveTo(w * 0.14, h * 0.32);
    arrow2.lineTo(w * 0.04, h * 0.46);
    arrow2.lineTo(w * 0.22, h * 0.50);
    arrow2.close();
    canvas.drawPath(arrow2, fill);
  }

  @override
  bool shouldRepaint(covariant _DotaRolePainter oldDelegate) {
    return oldDelegate.role != role || oldDelegate.color != color;
  }
}
