import 'package:flutter/material.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/theme/theme.dart';
import '../../models/draft_player_dto.dart';

/// Item visual de jogador dentro do Bucket do Draft (SRP & Dumb UI).
/// Segue a identidade visual dos cards do sistema com marca d'água oficial Tsurus,
/// contraste elevado, medalhas de patente e ícones oficiais de função no extremo direito.
class DraftPlayerTile extends StatelessWidget {
  final DraftPlayerDto player;
  final bool isProcessing;
  final String? teamBadge;
  final bool isCaptain;
  final Widget? trailing;

  const DraftPlayerTile({
    super.key,
    required this.player,
    required this.isProcessing,
    this.teamBadge,
    this.isCaptain = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> effectiveRoles = player.roles.isNotEmpty
        ? player.roles
        : (player.preferredRole != null ? [player.preferredRole!] : const []);
    final bool isUnranked = player.rankTier == null || player.rankTier! <= 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCaptain
              ? AppColors.dotaGold.withValues(alpha: 0.70)
              : AppColors.border.withValues(alpha: 0.80),
          width: isCaptain ? 1.15 : 0.85,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 1. Marca d'água oficial do símbolo da logo do site (Tsurus)
          Positioned(
            right: -10,
            bottom: -10,
            width: 80,
            height: 80,
            child: IgnorePointer(
              child: ClipOval(
                child: Image.asset(
                  'assets/images/company_logo.jpg',
                  cacheWidth: 160,
                  opacity: const AlwaysStoppedAnimation(0.04),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),

          // 2. Estrutura Modular: Faixa Superior + Perfil
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bloco 1: Mini Faixa Superior (Rank na extrema esquerda e Roles na extrema direita)
              _buildMiniHeaderStrip(effectiveRoles, isUnranked),

              // Bloco 2: Linha de Perfil (Avatar com fallback oficial + Nickname + Ação [+] / [-])
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    _buildAvatar(size: 36),
                    const SizedBox(width: 10),

                    // Nickname do Jogador ampliado com proteção de overflow
                    Expanded(
                      child: Tooltip(
                        message: player.name,
                        waitDuration: const Duration(milliseconds: 500),
                        child: Text(
                          player.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.25,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    // Ação [+] ou [-] ou Spinner
                    if (isProcessing) ...[
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: Padding(
                          padding: EdgeInsets.all(6),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.dotaGold),
                          ),
                        ),
                      ),
                    ] else if (trailing != null) ...[
                      const SizedBox(width: 8),
                      trailing!,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Mini Faixa Superior: Rank na extrema esquerda e Funções Dota 2 na extrema direita (via Spacer)
  Widget _buildMiniHeaderStrip(List<String> effectiveRoles, bool isUnranked) {
    return Container(
      height: 28,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.canvasSurface.withValues(alpha: 0.52),
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: 0.40),
            width: 0.85,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Extrema Esquerda: Badge de Capitão ou Time (se houver)
          if (teamBadge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: AppColors.dotaGold.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppColors.dotaGold.withValues(alpha: 0.45),
                  width: 0.7,
                ),
              ),
              child: Text(
                teamBadge!,
                style: const TextStyle(
                  fontSize: 9.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                  color: AppColors.dotaGoldLight,
                ),
              ),
            ),
          ] else if (isCaptain) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: AppColors.dotaGold.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppColors.dotaGold.withValues(alpha: 0.55),
                  width: 0.7,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.stars_rounded, color: AppColors.dotaGold, size: 10),
                  SizedBox(width: 3),
                  Text(
                    'CAPITÃO',
                    style: TextStyle(
                      color: AppColors.dotaGold,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Medalha e Nome do Rank
          DotaRankMedal(
            rankTier: player.rankTier?.toString() ?? '',
            rankStars: player.rankStars,
            leaderboardRank: player.leaderboardRank,
            size: 18,
            showBadgeNumber: false,
          ),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              player.rankDetail.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.35,
                color: isUnranked
                    ? AppColors.textSecondary.withValues(alpha: 0.6)
                    : AppColors.dotaGoldLight,
              ),
            ),
          ),

          const Spacer(),

          // Extrema Direita: Ícones de Funções Dota 2
          if (effectiveRoles.isNotEmpty)
            DotaRolesDisplay.fromStrings(
              rawRoles: effectiveRoles,
              preferredRoleKey: player.preferredRole,
              boxWidth: 18.0,
              boxHeight: 18.0,
              iconSize: 11.5,
              spacing: 3.5,
              showBoxes: true,
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar({double size = 36}) {
    final trimmedUrl = player.avatarUrl?.trim();
    final hasRealAvatar = trimmedUrl != null &&
        trimmedUrl.isNotEmpty &&
        !AppAvatar.isGenericSteamPlaceholder(trimmedUrl) &&
        (trimmedUrl.startsWith('http://') || trimmedUrl.startsWith('https://'));

    final Widget imageWidget = hasRealAvatar
        ? Image.network(
            trimmedUrl,
            cacheWidth: (size * 2).round().clamp(64, 256),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                AppAvatar.buildTsurusSymbolFallback(size: size),
          )
        : AppAvatar.buildTsurusSymbolFallback(size: size);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.canvasSurface,
        border: Border.all(
          color: isCaptain
              ? AppColors.dotaGold
              : AppColors.border.withValues(alpha: 0.85),
          width: isCaptain ? 1.3 : 1.0,
        ),
      ),
      child: ClipOval(child: imageWidget),
    );
  }
}
