import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Widget centralizado de identidade visual para a marca TSURUS PLUS+ (SRP & DRY).
/// Renderiza a tipografia estilizada da plataforma:
/// - 'TSURUS ' em Branco puro
/// - 'PLUS+' em Vermelho Arena oficial (AppColors.primaryNeon)
/// - Suporte a prefixo empilhado (`stackPrefix: true`) para títulos de destaque com ênfase visual
class TsurusBrandTitle extends StatelessWidget {
  final String? prefix;
  final double fontSize;
  final double letterSpacing;
  final TextAlign textAlign;
  final FontWeight fontWeight;
  final bool stackPrefix;

  const TsurusBrandTitle({
    super.key,
    this.prefix,
    this.fontSize = 16.5,
    this.letterSpacing = 1.1,
    this.textAlign = TextAlign.start,
    this.fontWeight = FontWeight.w800,
    this.stackPrefix = false,
  });

  @override
  Widget build(BuildContext context) {
    final brandSpan = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'TSURUS ',
            style: TextStyle(
              fontFamily: 'Oswald',
              fontSize: fontSize,
              fontWeight: fontWeight,
              letterSpacing: letterSpacing,
              color: Colors.white,
            ),
          ),
          TextSpan(
            text: 'PLUS+',
            style: TextStyle(
              fontFamily: 'Oswald',
              fontSize: fontSize,
              fontWeight: fontWeight,
              letterSpacing: letterSpacing,
              color: AppColors.primaryNeon,
            ),
          ),
        ],
      ),
      textAlign: textAlign,
    );

    // Modo empilhado: prefixo em tracking largo no topo e marca com máxima ênfase abaixo
    if (prefix != null && prefix!.trim().isNotEmpty && stackPrefix) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: textAlign == TextAlign.center
            ? CrossAxisAlignment.center
            : (textAlign == TextAlign.end ? CrossAxisAlignment.end : CrossAxisAlignment.start),
        children: [
          Text(
            prefix!.trim().toUpperCase(),
            style: TextStyle(
              fontFamily: 'Oswald',
              fontSize: (fontSize * 0.52).clamp(11.0, 14.0),
              fontWeight: FontWeight.w700,
              letterSpacing: 2.4,
              color: AppColors.textSecondary.withValues(alpha: 0.9),
            ),
            textAlign: textAlign,
          ),
          const SizedBox(height: 3),
          brandSpan,
        ],
      );
    }

    if (prefix != null && prefix!.trim().isNotEmpty) {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '${prefix!.trim()} TSURUS ',
              style: TextStyle(
                fontFamily: 'Oswald',
                fontSize: fontSize,
                fontWeight: fontWeight,
                letterSpacing: letterSpacing,
                color: Colors.white,
              ),
            ),
            TextSpan(
              text: 'PLUS+',
              style: TextStyle(
                fontFamily: 'Oswald',
                fontSize: fontSize,
                fontWeight: fontWeight,
                letterSpacing: letterSpacing,
                color: AppColors.primaryNeon,
              ),
            ),
          ],
        ),
        textAlign: textAlign,
      );
    }

    return brandSpan;
  }
}
