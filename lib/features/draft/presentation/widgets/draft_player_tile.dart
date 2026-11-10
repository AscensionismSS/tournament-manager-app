import 'package:flutter/material.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/theme/theme.dart';
import '../../models/draft_player_dto.dart';

/// Item visual de jogador dentro do Bucket do Draft (SRP & Dumb UI).
/// Segue a identidade visual dos cards do sistema com marca d'água,
/// contraste elevado, medalhas de patente e ícones oficiais de função.
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCaptain
              ? AppColors.dotaGold.withValues(alpha: 0.6)
              : AppColors.border.withValues(alpha: 0.8),
          width: 0.85,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 1. Marca d'água oficial translúcida (Fidelidade com os cards maiores)
          Positioned(
            right: -10,
            bottom: -10,
            width: 75,
            height: 75,
            child: Opacity(
              opacity: 0.06,
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),

          // 2. Gradiente suave de superfície
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppColors.surface.withValues(alpha: 0.96),
                    AppColors.surface.withValues(alpha: 0.90),
                    AppColors.surface.withValues(alpha: 0.97),
                  ],
                ),
              ),
            ),
          ),

          // 3. Estrutura Modular idêntica aos cards maiores: Faixa Superior + Perfil
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bloco 1: Mini Faixa Superior (Rank + Patente + Divisória + Símbolos das Roles)
              _buildMiniHeaderStrip(effectiveRoles, isUnranked),

              // Bloco 2: Linha de Perfil (Avatar com contorno + Nickname + Ação [+] / [-])
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                child: Row(
                  children: [
                    // Avatar com contorno dourado ou sutil
                    AppAvatar(
                      radius: 17,
                      name: player.name,
                      imageUrl: player.avatarUrl,
                      borderWidth: 1.2,
                      borderColor:
                          isCaptain ? AppColors.dotaGold : AppColors.border,
                    ),
                    const SizedBox(width: 10),

                    // Nickname do Jogador
                    Expanded(
                      child: Text(
                        player.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                          color: Colors.white,
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

  /// Mini Faixa Superior idêntica à do AppPlayerCard e DraftTeamCaptainCard
  Widget _buildMiniHeaderStrip(List<String> effectiveRoles, bool isUnranked) {
    return Container(
      height: 27,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.dotaGold.withValues(alpha: isUnranked ? 0.05 : 0.11),
        border: Border(
          bottom: BorderSide(
            color: isUnranked
                ? AppColors.border.withValues(alpha: 0.5)
                : AppColors.dotaGold.withValues(alpha: 0.35),
            width: 0.85,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Lado Esquerdo: Medalha do Dota + Patente + Divisória + Símbolos das Roles
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                DotaRankMedal(
                  rankTier: player.rankTier?.toString() ?? '',
                  size: 16,
                  showBadgeNumber: false,
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    player.rankDetail.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.0,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                      color: isUnranked
                          ? AppColors.textSecondary
                          : AppColors.dotaGoldLight,
                    ),
                  ),
                ),
                if (effectiveRoles.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 1.0,
                    height: 12,
                    color: AppColors.dotaGold.withValues(alpha: 0.35),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: DotaRolesDisplay.fromStrings(
                        rawRoles: effectiveRoles,
                        preferredRoleKey: player.preferredRole,
                        boxWidth: 16.0,
                        boxHeight: 16.0,
                        iconSize: 11.0,
                        spacing: 3.0,
                        showBoxes: true,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Lado Direito: Badge da Equipe ou Badge de Capitão
          if (teamBadge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
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
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.stars_rounded, color: AppColors.dotaGold, size: 11),
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
          ],
        ],
      ),
    );
  }
}
