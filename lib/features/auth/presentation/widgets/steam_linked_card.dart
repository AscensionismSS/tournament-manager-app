import 'package:flutter/material.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/safe_url_launcher.dart';
import '../../models/login_response.dart';

/// Card para exibição de conta Steam já vinculada e protegida (Locked).
class SteamLinkedCard extends StatelessWidget {
  final LoginResponse profile;
  final String? previewRankTier;
  final int? previewLeaderboardRank;

  const SteamLinkedCard({
    super.key,
    required this.profile,
    this.previewRankTier,
    this.previewLeaderboardRank,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = profile.dotaAvatarUrl ?? '';
    final hasAvatar = avatarUrl.isNotEmpty;
    final personaName = profile.dotaPersonaName ?? profile.displayName;
    final steamId = profile.steamId ?? '--';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvasSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary,
          width: 1.2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Faixa Superior no Topo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceHighlight.withValues(alpha: 0.65),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.6),
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 13,
                  color: AppColors.primaryNeon,
                ),
                const SizedBox(width: 6),
                Text(
                  'CONTA VINCULADA',
                  style: AppText.caption.copyWith(
                    color: AppColors.onSurface.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),

          // 2. Linha Principal com Dados do Perfil
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary,
                      width: 1.8,
                    ),
                  ),
                  child: ClipOval(
                    child: hasAvatar
                        ? Image.network(
                            avatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.person_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          )
                        : const Icon(
                            Icons.person_rounded,
                            color: AppColors.primary,
                            size: 24,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        personaName,
                        style: AppText.h4.copyWith(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'ID: $steamId',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Builder(
                  builder: (context) {
                    final tier = (profile.dotaRankTier != null &&
                            profile.dotaRankTier!.isNotEmpty)
                        ? profile.dotaRankTier!
                        : (previewRankTier ?? '');
                    final rank =
                        profile.dotaLeaderboardRank ?? previewLeaderboardRank;

                    if (tier.isNotEmpty && tier != '0') {
                      return DotaRankMedal(
                        rankTier: tier,
                        leaderboardRank: rank,
                        size: 52,
                        showBadgeNumber: true,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),

          // 3. Faixa Inferior na Base: "Ir para a Steam"
          if (steamId != '--')
            InkWell(
              onTap: () {
                final text = steamId.trim();
                if (text.startsWith('http://') || text.startsWith('https://')) {
                  SafeUrlLauncher.launch(text, context: context);
                } else if (text.isNotEmpty &&
                    text != 'https://steamcommunity.com') {
                  SafeUrlLauncher.openSteamProfile(context, text);
                } else {
                  SafeUrlLauncher.launch('https://steamcommunity.com',
                      context: context);
                }
              },
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 7, horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  border: Border(
                    top: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      width: 1.0,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.sports_esports_rounded,
                      size: 14,
                      color: AppColors.primaryNeon,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Ir para a Steam',
                      style: AppText.caption.copyWith(
                        color: AppColors.onSurface.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                        fontSize: 11.5,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.open_in_new_rounded,
                      size: 12,
                      color: AppColors.primaryNeon,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
