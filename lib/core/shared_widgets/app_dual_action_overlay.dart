import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Overlay canônico dividido ao meio (50% / 50%) com micro-interações táteis no hover.
/// Utilizado em cards e linhas interativas (ex: [SUBSTITUIR | REMOVER] no Draft,
/// ou [VER PARTIDA | EDITAR RESULTADO] nos jogos de campeonatos).
class AppDualActionOverlay extends StatelessWidget {
  final String leftLabel;
  final IconData leftIcon;
  final VoidCallback? onLeftTap;
  final Color leftColor;
  final Color? leftHoverColor;

  final String rightLabel;
  final IconData rightIcon;
  final VoidCallback? onRightTap;
  final Color rightColor;
  final Color? rightHoverColor;

  final BorderRadius? borderRadius;
  final Color? borderColor;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;
  final double dividerHeight;

  const AppDualActionOverlay({
    super.key,
    required this.leftLabel,
    required this.leftIcon,
    this.onLeftTap,
    this.leftColor = AppColors.dotaGoldLight,
    this.leftHoverColor,
    required this.rightLabel,
    required this.rightIcon,
    this.onRightTap,
    this.rightColor = AppColors.primaryNeon,
    this.rightHoverColor,
    this.borderRadius,
    this.borderColor,
    this.backgroundColor,
    this.boxShadow,
    this.dividerHeight = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(8);
    final effectiveBorderColor =
        borderColor ?? AppColors.dotaGold.withValues(alpha: 0.55);
    final effectiveBgColor =
        backgroundColor ?? AppColors.canvasSurface.withValues(alpha: 0.94);
    final effectiveLeftHover =
        leftHoverColor ?? leftColor.withValues(alpha: 0.12);
    final effectiveRightHover =
        rightHoverColor ?? rightColor.withValues(alpha: 0.12);

    return Container(
      decoration: BoxDecoration(
        color: effectiveBgColor,
        borderRadius: effectiveRadius,
        border: Border.all(
          color: effectiveBorderColor,
          width: 1.2,
        ),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.40),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: Row(
          children: [
            // Metade Esquerda: Ação 1 (50%)
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onLeftTap,
                  hoverColor: effectiveLeftHover,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          leftIcon,
                          size: 15,
                          color: leftColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          leftLabel,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            color: leftColor,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Divisor vertical central
            Container(
              width: 1.0,
              height: dividerHeight,
              color: AppColors.border.withValues(alpha: 0.75),
            ),

            // Metade Direita: Ação 2 (50%)
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onRightTap,
                  hoverColor: effectiveRightHover,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          rightIcon,
                          size: 16,
                          color: rightColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          rightLabel,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            color: rightColor,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

