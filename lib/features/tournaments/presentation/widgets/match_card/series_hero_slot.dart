import 'package:flutter/material.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../core/utils/dota_hero_helper.dart';

/// Slot individual de herói no card da partida (SRP).
/// Renderiza o avatar do herói 100% aceso e visível (picks, bans, vencedor e perdedor).
/// Destaque do vencedor: borda verde neon vibrante com brilho luminoso.
/// Bans: borda vermelha nítida.
class SeriesHeroSlot extends StatelessWidget {
  final int? heroId;
  final String? heroName;
  final bool isWinner;
  final bool isPlaceholder;
  final bool isBan;
  final double size;

  const SeriesHeroSlot({
    super.key,
    this.heroId,
    this.heroName,
    this.isWinner = false,
    this.isPlaceholder = false,
    this.isBan = false,
    this.size = 25.5,
  });

  /// Construtor de conveniência para slot de pick vazio (placeholder neutro)
  const SeriesHeroSlot.placeholder({
    super.key,
    this.size = 25.5,
  })  : heroId = null,
        heroName = null,
        isWinner = false,
        isPlaceholder = true,
        isBan = false;

  /// Construtor de conveniência para slot de ban (placeholder neutro com borda vermelha sutil)
  const SeriesHeroSlot.banPlaceholder({
    super.key,
    this.size = 21.5,
  })  : heroId = null,
        heroName = null,
        isWinner = false,
        isPlaceholder = true,
        isBan = true;

  @override
  Widget build(BuildContext context) {
    if (isPlaceholder ||
        (heroId == null && (heroName == null || heroName!.isEmpty))) {
      return isBan ? _buildBanPlaceholderSlot() : _buildPlaceholderSlot();
    }

    final assetPath =
        DotaHeroHelper.resolveHeroAsset(heroId: heroId, rawName: heroName);

    if (assetPath == null) {
      return isBan ? _buildBanPlaceholderSlot() : _buildPlaceholderSlot();
    }

    // Todos os heróis são exibidos 100% acesos e com máxima nitidez
    final Widget imageWidget = Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          isBan ? _buildBanPlaceholderSlot() : _buildPlaceholderSlot(),
    );

    // O destaque do vencedor é aprimorado com borda verde neon e glow sutil,
    // enquanto o perdedor e os bans permanecem totalmente visíveis e nítidos.
    final Color borderColor;
    final double borderWidth;
    final List<BoxShadow>? boxShadow;

    if (isBan) {
      borderColor = AppColors.feedbackError.withValues(alpha: 0.90);
      borderWidth = 1.0;
      boxShadow = null;
    } else if (isWinner) {
      // Vencedor: verde mais aceso com brilho
      borderColor = AppColors.feedbackSuccess;
      borderWidth = 1.25;
      boxShadow = [
        BoxShadow(
          color: AppColors.feedbackSuccess.withValues(alpha: 0.40),
          blurRadius: 4,
          spreadRadius: 0.5,
        ),
      ];
    } else {
      // Perdedor: mesmo verde, porém mais discreto e sem brilho
      borderColor = AppColors.feedbackSuccess.withValues(alpha: 0.55);
      borderWidth = 1.0;
      boxShadow = null;
    }
    final displayName =
        DotaHeroHelper.getDisplayName(heroId: heroId, rawName: heroName);

    return Tooltip(
      message: '${isBan ? "Ban: " : ""}$displayName',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3.5),
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
          color: AppColors.canvasSurface,
          boxShadow: boxShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: imageWidget,
      ),
    );
  }

  /// Constrói o slot de pick vazado: caixa escura neutra com ponto central sutil
  Widget _buildPlaceholderSlot() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.canvasSurface,
        borderRadius: BorderRadius.circular(3.5),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.40),
          width: 0.85,
        ),
      ),
      child: Center(
        child: Container(
          width: 2.2,
          height: 2.2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.textSecondary.withValues(alpha: 0.15),
          ),
        ),
      ),
    );
  }

  /// Constrói o slot de ban vazado: caixa escura neutra com borda vermelha limpa (sem risco sobreposto)
  Widget _buildBanPlaceholderSlot() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.canvasSurface,
        borderRadius: BorderRadius.circular(3.5),
        border: Border.all(
          color: AppColors.feedbackError.withValues(alpha: 0.45),
          width: 0.85,
        ),
      ),
    );
  }
}
