import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../utils/dota_rank_helper.dart';

/// Componente que renderiza a medalha oficial de rank do Dota 2.
class DotaRankMedal extends StatelessWidget {
  final String rankTier;
  final int rankStars;
  final int? leaderboardRank;
  final double size;
  final bool showBadgeNumber;

  const DotaRankMedal({
    super.key,
    required this.rankTier,
    this.rankStars = 0,
    this.leaderboardRank,
    this.size = 28,
    this.showBadgeNumber = true,
  });

  static const String _cdnBase = 'https://www.opendota.com/assets/images/dota2/rank_icons';

  /// Mapeia o nome ou código numérico do tier para o número correspondente da Valve (0 a 8)
  int get tierNumber => DotaRankHelper.parseTierNumber(rankTier);

  /// Estrelas efetivas (1 a 5)
  int get effectiveRankStars => DotaRankHelper.parseRankStars(rankTier, rankStars);

  /// Retorna o nome do arquivo PNG base da medalha
  String get baseMedalFileName => _resolveBaseMedalFileName(tierNumber);

  String _resolveBaseMedalFileName(int tier) {
    if (tier == 0) return 'rank_icon_0.png';

    if (tier == 8) {
      if (leaderboardRank != null && leaderboardRank! > 0) {
        if (leaderboardRank! <= 10) return 'rank_icon_8c.png';
        if (leaderboardRank! <= 100) return 'rank_icon_8b.png';
      }
      return 'rank_icon_8.png';
    }

    return 'rank_icon_$tier.png';
  }

  /// Retorna o nome do arquivo PNG da estrela sobreposta (1 a 5)
  String? get starOverlayFileName =>
      _resolveStarOverlayFileName(tierNumber, effectiveRankStars);

  String? _resolveStarOverlayFileName(int tier, int stars) {
    if (tier >= 1 && tier <= 7 && stars >= 1 && stars <= 5) {
      return 'rank_star_$stars.png';
    }
    return null;
  }

  /// Constrói a imagem carregando diretamente da CDN oficial da OpenDota
  /// com redimensionamento na decodificação GPU e fallback gracioso.
  Widget _buildLayerImage(String fileName, int tier, int targetCacheSize) {
    return Image.network(
      '$_cdnBase/$fileName',
      width: size,
      height: size,
      cacheWidth: targetCacheSize,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.military_tech_rounded,
        size: size * 0.75,
        color: tier == 8 ? AppColors.dotaGold : AppColors.textSecondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int tier = tierNumber;
    final int stars = effectiveRankStars;
    final int targetCacheSize = (size * 2).round().clamp(32, 128);
    final String baseFileName = _resolveBaseMedalFileName(tier);
    final String? starFileName = _resolveStarOverlayFileName(tier, stars);
    final bool isRankedImmortal =
        tier == 8 && leaderboardRank != null && leaderboardRank! > 0;

    return Tooltip(
      message: _buildTooltipMessage(tier),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // 1. Camada Base: Medalha do Tier
            _buildLayerImage(baseFileName, tier, targetCacheSize),

            // 2. Camada Superior: Estrelas sobrepostas (Divino 1 a 5, etc)
            if (starFileName != null)
              _buildLayerImage(starFileName, tier, targetCacheSize),

            // 3. Camada do Placar de Imortal (Plaqueta oficial na base da medalha)
            if (isRankedImmortal && showBadgeNumber)
              Positioned(
                bottom: (size * 0.03).clamp(1.0, 3.5),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: (size * 0.08).clamp(3.0, 5.0),
                    vertical: (size * 0.015).clamp(0.5, 1.2),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                  child: Text(
                    '$leaderboardRank',
                    style: TextStyle(
                      color: AppColors.dotaGoldLight,
                      fontSize: (size * 0.20).clamp(8.0, 11.0),
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _buildTooltipMessage(int tier) {
    if (tier == 0) return 'Dota 2: Sem Rank Calibrado';
    if (tier == 8) {
      if (leaderboardRank != null && leaderboardRank! > 0) {
        return 'Dota 2: Imortal (Posição #$leaderboardRank no Placar)';
      }
      return 'Dota 2: Imortal';
    }
    final starsText = rankStars > 0 ? ' [★ $rankStars]' : '';
    return 'Dota 2: $rankTier$starsText';
  }
}
