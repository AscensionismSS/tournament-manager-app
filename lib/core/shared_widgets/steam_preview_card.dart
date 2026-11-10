import 'package:flutter/material.dart';
import '../../features/auth/models/steam_preview_dto.dart';
import '../theme/theme.dart';
import '../utils/safe_url_launcher.dart';
import 'dota_rank_medal.dart';

/// Card unificado e reutilizável de pré-visualização de perfil Steam / Dota 2 (SRP).
/// Mantém rigorosamente as mesmas dimensões e estrutura visual (Anti-Layout Shift):
/// - Faixa Superior (Status: PRÉVIA / VERIFICADO / NÃO ENCONTRADO / EM USO)
/// - Linha Central (Avatar 48px + Nickname/SteamID + Medalha Dota 2)
/// - Faixa Inferior ("Ir para a Steam")
class SteamPreviewCard extends StatelessWidget {
  final SteamPreviewDto? preview;
  final bool isVerifying;
  final String? errorText;
  final VoidCallback? onClear;
  final String? currentIdentifier;
  final String? customHeaderLabel;

  const SteamPreviewCard({
    super.key,
    this.preview,
    this.isVerifying = false,
    this.errorText,
    this.onClear,
    this.currentIdentifier,
    this.customHeaderLabel,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Estado de Carregamento
    if (isVerifying) {
      return Container(
        height: 106,
        decoration: BoxDecoration(
          color: AppColors.canvasSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryNeon.withValues(alpha: 0.35),
            width: 1.0,
          ),
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  color: AppColors.primaryNeon,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Buscando dados na Steam e OpenDota...',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Determinação de Estados
    final bool hasError = errorText != null && errorText!.isNotEmpty;
    final bool hasData = preview != null &&
        preview!.steamId.toString().trim().isNotEmpty &&
        preview!.steamId.toString().trim() != '0';
    final p = preview;
    final bool isInUse = p?.isAlreadyInUse == true;
    final bool hasAvatar = p != null && p.avatarUrl != null && p.avatarUrl!.isNotEmpty;

    final Color borderColor;
    final Color headerBgColor;
    final Color headerTextColor;
    final IconData headerIcon;
    final String headerLabel;

    final bool isBlocked = isInUse || (hasData && hasError);

    if (customHeaderLabel != null) {
      headerLabel = customHeaderLabel!;
      headerIcon = isBlocked || hasError
          ? Icons.error_outline_rounded
          : Icons.check_circle_outline_rounded;
      headerTextColor = isBlocked || hasError ? AppColors.feedbackError : AppColors.dotaGold;
      headerBgColor = isBlocked || hasError
          ? AppColors.feedbackError.withValues(alpha: 0.18)
          : AppColors.surfaceHighlight.withValues(alpha: 0.75);
      borderColor = isBlocked || hasError
          ? AppColors.feedbackError
          : AppColors.dotaGold.withValues(alpha: 0.6);
    } else if (hasError && !hasData) {
      borderColor = AppColors.feedbackError.withValues(alpha: 0.7);
      headerBgColor = AppColors.feedbackError.withValues(alpha: 0.15);
      headerTextColor = AppColors.feedbackError;
      headerIcon = Icons.error_outline_rounded;
      headerLabel = 'PERFIL NÃO ENCONTRADO';
    } else if (isInUse) {
      borderColor = AppColors.feedbackError;
      headerBgColor = AppColors.feedbackError.withValues(alpha: 0.18);
      headerTextColor = AppColors.feedbackError;
      headerIcon = Icons.error_outline_rounded;
      headerLabel = 'CONTA JÁ EM USO';
    } else if (hasData && hasError) {
      borderColor = AppColors.feedbackError;
      headerBgColor = AppColors.feedbackError.withValues(alpha: 0.18);
      headerTextColor = AppColors.feedbackError;
      headerIcon = Icons.error_outline_rounded;
      headerLabel = 'INELEGÍVEL';
    } else if (hasData) {
      borderColor = AppColors.dotaGold.withValues(alpha: 0.6);
      headerBgColor = AppColors.surfaceHighlight.withValues(alpha: 0.75);
      headerTextColor = AppColors.dotaGold;
      headerIcon = Icons.check_circle_outline_rounded;
      headerLabel = 'DADOS VERIFICADOS';
    } else {
      borderColor = AppColors.borderHighlight.withValues(alpha: 0.6);
      headerBgColor = AppColors.surfaceHighlight.withValues(alpha: 0.5);
      headerTextColor = AppColors.textSecondary;
      headerIcon = Icons.visibility_outlined;
      headerLabel = 'PRÉVIA DO PERFIL STEAM';
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvasSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (hasError || isInUse ? AppColors.feedbackError : AppColors.dotaGold)
                .withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Faixa Superior no Topo (Header Strip)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
            decoration: BoxDecoration(
              color: headerBgColor,
              border: Border(
                bottom: BorderSide(
                  color: hasError || isInUse
                      ? AppColors.feedbackError.withValues(alpha: 0.4)
                      : AppColors.border.withValues(alpha: 0.5),
                  width: 0.9,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  headerIcon,
                  size: 13,
                  color: headerTextColor,
                ),
                const SizedBox(width: 6),
                Text(
                  headerLabel,
                  style: TextStyle(
                    fontFamily: 'Oswald',
                    color: headerTextColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                if (hasData && onClear != null)
                  InkWell(
                    onTap: onClear,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Text(
                        'REMOVER',
                        style: TextStyle(
                          fontFamily: 'Oswald',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 2. Linha Principal de Dados (Avatar + Nickname/SteamID + Medalha)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar da Steam 48px
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: hasError || isInUse
                          ? AppColors.feedbackError
                          : (hasData ? AppColors.dotaGold : AppColors.border.withValues(alpha: 0.35)),
                      width: 1.5,
                    ),
                  ),
                  child: ClipOval(
                    child: hasAvatar
                        ? Image.network(
                            p.avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person_rounded,
                              color: AppColors.dotaGold,
                              size: 24,
                            ),
                          )
                        : Icon(
                            hasError
                                ? Icons.error_outline_rounded
                                : (hasData ? Icons.person_rounded : Icons.sports_esports_outlined),
                            color: hasError
                                ? AppColors.feedbackError
                                : (hasData
                                    ? AppColors.dotaGold
                                    : AppColors.textSecondary.withValues(alpha: 0.35)),
                            size: 24,
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // Nickname da Steam + SteamID (ou mensagem de espera limpa)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hasData
                            ? p!.personaName
                            : (hasError ? 'Perfil Não Encontrado' : 'Aguardando verificação'),
                        style: TextStyle(
                          fontSize: hasData ? 15 : 13.5,
                          fontWeight: hasData ? FontWeight.w800 : FontWeight.w600,
                          color: (hasError && !hasData)
                              ? AppColors.feedbackError
                              : (hasData
                                  ? Colors.white
                                  : AppColors.textSecondary.withValues(alpha: 0.75)),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        hasData
                            ? 'SteamID: ${p!.effectiveSteamId}'
                            : (hasError
                                ? 'Verifique o link ou SteamID informado'
                                : 'Informe seu perfil e clique em VERIFICAR'),
                        style: TextStyle(
                          fontFamily: hasData ? 'monospace' : 'Inter',
                          fontSize: 11.5,
                          fontWeight: hasData ? FontWeight.w600 : FontWeight.w400,
                          color: AppColors.textSecondary.withValues(alpha: hasData ? 0.9 : 0.5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (hasData && hasError && errorText != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          errorText!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.feedbackError,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Medalha Oficial Dota 2 (48px - visível apenas com dados verificados)
                if (hasData && (p!.rankTier ?? 0) > 0)
                  DotaRankMedal(
                    rankTier: p.rankName,
                    rankStars: (p.rankTier ?? 0) % 10,
                    leaderboardRank: p.leaderboardRank,
                    size: 48,
                    showBadgeNumber: false,
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),

          // 3. Faixa Inferior na Base: "Ir para a Steam" (Bloqueado estritamente até verificar)
          _buildBottomStrip(
            context,
            profileUrl: hasData
                ? (p!.profileUrl ?? 'https://steamcommunity.com/profiles/${p.steamId}')
                : null,
            personaName: hasData ? p!.personaName : null,
            isEnabled: hasData && !isInUse,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomStrip(
    BuildContext context, {
    String? profileUrl,
    String? personaName,
    required bool isEnabled,
  }) {
    // 1. Estado Bloqueado: Nenhuma conta Steam verificada ainda
    if (!isEnabled || profileUrl == null || profileUrl.trim().isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.canvasSurface.withValues(alpha: 0.5),
          border: Border(
            top: BorderSide(
              color: AppColors.border.withValues(alpha: 0.3),
              width: 1.0,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_esports_rounded,
              size: 14,
              color: AppColors.textSecondary.withValues(alpha: 0.35),
            ),
            const SizedBox(width: 6),
            Text(
              'Ir para a Steam',
              style: TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textSecondary.withValues(alpha: 0.35),
                fontWeight: FontWeight.w500,
                fontSize: 11.5,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.lock_outline_rounded,
              size: 12,
              color: AppColors.textSecondary.withValues(alpha: 0.30),
            ),
          ],
        ),
      );
    }

    // 2. Estado Habilitado: Perfil validado com redirecionamento dinâmico
    return Tooltip(
      message: 'Abrir perfil de ${personaName ?? 'jogador'} na Steam Community',
      child: InkWell(
        onTap: () => SafeUrlLauncher.launch(profileUrl.trim(), context: context),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            border: Border(
              top: BorderSide(
                color: AppColors.primaryNeon.withValues(alpha: 0.35),
                width: 1.0,
              ),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sports_esports_rounded,
                size: 14,
                color: AppColors.primaryNeon,
              ),
              SizedBox(width: 6),
              Text(
                'Ir para a Steam',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 11.5,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(width: 6),
              Icon(
                Icons.open_in_new_rounded,
                size: 12,
                color: AppColors.primaryNeon,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
