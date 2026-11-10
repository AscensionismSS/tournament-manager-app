import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../feedback/app_feedback.dart';
import '../theme/theme.dart';
import '../utils/safe_url_launcher.dart';
import 'dota_rank_medal.dart';
import 'dota_role_icons.dart';

/// Card unificado e oficial de exibição de Jogadores Competitivos / Membros.
/// Composto por sub-widgets modulares seguindo estritamente as diretrizes de SRP do AGENTS.md.
class AppPlayerCard extends StatelessWidget {
  final String nickname;
  final String? avatarUrl;
  final String? initials;
  final String rankDetail;
  final int rankStars;
  final int? leaderboardRank;
  final String? steamId;
  final String? openDotaUrl;
  final String? steamProfileUrl;
  final String? subtitle;
  final List<String> roles;
  final String? preferredRole;
  final bool isCaptain;
  final bool isMe;
  final bool isModerator;
  final List<String> permissions;
  final VoidCallback? onTap;
  final VoidCallback? onCopySteamId;
  final VoidCallback? onOpenOpenDota;
  final VoidCallback? onOpenSteamProfile;

  const AppPlayerCard({
    super.key,
    required this.nickname,
    this.subtitle,
    this.avatarUrl,
    this.initials,
    required this.rankDetail,
    this.rankStars = 0,
    this.leaderboardRank,
    this.steamId,
    this.openDotaUrl,
    this.steamProfileUrl,
    this.roles = const [],
    this.preferredRole,
    this.isCaptain = false,
    this.isMe = false,
    this.isModerator = false,
    this.permissions = const [],
    this.onTap,
    this.onCopySteamId,
    this.onOpenOpenDota,
    this.onOpenSteamProfile,
  });

  String get effectiveInitials {
    if (initials != null && initials!.isNotEmpty) return initials!;
    final clean = nickname.trim();
    if (clean.isEmpty) return '?';
    final parts = clean.split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return clean.substring(0, clean.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final accentColor = isMe
        ? AppColors.primaryNeon
        : (isCaptain ? AppColors.dotaGold : AppColors.dotaGold);

    final isUnranked = rankDetail.toUpperCase() == 'SEM RANK' || rankDetail.isEmpty;

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: accentColor.withValues(alpha: 0.1),
          highlightColor: accentColor.withValues(alpha: 0.05),
          child: Container(
            constraints: const BoxConstraints(minHeight: 156),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isMe
                    ? AppColors.primaryNeon.withValues(alpha: 0.75)
                    : (isCaptain
                        ? AppColors.dotaGold.withValues(alpha: 0.6)
                        : AppColors.border),
                width: 0.85,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // 1. Marca d'água translúcida
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/logo.png',
                    cacheWidth: 320,
                    opacity: const AlwaysStoppedAnimation(0.08),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),

                // 2. Gradiente suave de profundidade
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          colorScheme.surface.withValues(alpha: 0.95),
                          colorScheme.surface.withValues(alpha: 0.90),
                          colorScheme.surface.withValues(alpha: 0.96),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Estrutura Principal dos 3 Blocos Modulares
                Positioned.fill(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Bloco 1: Faixa Superior de Rank + Funções + Dota ID
                      _PlayerCardHeaderStrip(
                        rankDetail: rankDetail,
                        rankStars: rankStars,
                        leaderboardRank: leaderboardRank,
                        roles: roles,
                        preferredRole: preferredRole,
                        steamId: steamId,
                        isUnranked: isUnranked,
                        onCopySteamId: onCopySteamId,
                      ),

                      // Bloco 2: Perfil do Jogador (Avatar + Nickname + Badge Capitão)
                      Expanded(
                        child: _PlayerCardProfileSection(
                          nickname: nickname,
                          subtitle: subtitle,
                          avatarUrl: avatarUrl,
                          effectiveInitials: effectiveInitials,
                          isCaptain: isCaptain,
                          isMe: isMe,
                          accentColor: accentColor,
                        ),
                      ),

                      // Divisória estética horizontal
                      _buildDivider(colorScheme, isCaptain, isMe),

                      // Bloco 3: Botões Externos (Steam e OpenDota)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 9, 16, 11),
                        child: _PlayerCardExternalButtons(
                          steamProfileUrl: steamProfileUrl,
                          openDotaUrl: openDotaUrl,
                          steamId: steamId,
                          onOpenSteamProfile: onOpenSteamProfile,
                          onOpenOpenDota: onOpenOpenDota,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(ColorScheme colorScheme, bool isCaptain, bool isMe) {
    return Container(
      height: 1.0,
      width: double.infinity,
      color: AppColors.border.withValues(alpha: 0.65),
    );
  }
}

/// Bloco 1: Faixa superior (Rank, Medalha, Funções e Dota ID)
class _PlayerCardHeaderStrip extends StatelessWidget {
  final String rankDetail;
  final int rankStars;
  final int? leaderboardRank;
  final List<String> roles;
  final String? preferredRole;
  final String? steamId;
  final bool isUnranked;
  final VoidCallback? onCopySteamId;

  const _PlayerCardHeaderStrip({
    required this.rankDetail,
    required this.rankStars,
    this.leaderboardRank,
    required this.roles,
    this.preferredRole,
    this.steamId,
    required this.isUnranked,
    this.onCopySteamId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final hasId = steamId != null && steamId!.trim().isNotEmpty;
    final displayId = hasId ? steamId! : null;

    return Container(
      height: 38,
      width: double.infinity,
      padding: const EdgeInsets.only(left: 12, right: 8),
      decoration: BoxDecoration(
        color: AppColors.dotaGold.withValues(alpha: isUnranked ? 0.06 : 0.12),
        border: Border(
          bottom: BorderSide(
            color: isUnranked
                ? colorScheme.outline.withValues(alpha: 0.22)
                : AppColors.dotaGold.withValues(alpha: 0.38),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Grupo Esquerdo: Medalha + Nome do Rank + Símbolos das Funções
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                DotaRankMedal(
                  rankTier: rankDetail,
                  rankStars: rankStars,
                  leaderboardRank: leaderboardRank,
                  size: 22,
                  showBadgeNumber: false,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    rankDetail,
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w900,
                      color: isUnranked
                          ? colorScheme.onSurface.withValues(alpha: 0.6)
                          : AppColors.dotaGoldLight,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (roles.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Container(
                    width: 1.0,
                    height: 16,
                    color: AppColors.dotaGold.withValues(alpha: 0.35),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: DotaRolesDisplay.fromStrings(
                        rawRoles: roles,
                        preferredRoleKey: preferredRole,
                        boxWidth: 22.0,
                        boxHeight: 22.0,
                        iconSize: 14.0,
                        spacing: 5.0,
                        showBoxes: true,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Grupo Direito: Dota ID discreto com cópia
          if (displayId != null) ...[
            const SizedBox(width: 8),
            _buildDotaIdChip(context, displayId),
          ],
        ],
      ),
    );
  }

  Widget _buildDotaIdChip(BuildContext context, String id) {
    return Tooltip(
      message: 'Copiar Dota ID ($id) para o jogo',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onCopySteamId ??
              () {
                Clipboard.setData(ClipboardData(text: id));
                AppFeedback.showSuccess(
                  context,
                  title: 'DOTA ID COPIADO',
                  message: 'Dota ID ($id) copiado! Cole no jogo para adicionar.',
                );
              },
          borderRadius: BorderRadius.circular(5),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.canvasSurface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: AppColors.border,
                width: 0.85,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'ID: ',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  id,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(
                  Icons.content_copy_rounded,
                  size: 11.5,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bloco 2: Perfil do Jogador (Avatar + Nickname + Badge Capitão)
class _PlayerCardProfileSection extends StatelessWidget {
  final String nickname;
  final String? subtitle;
  final String? avatarUrl;
  final String effectiveInitials;
  final bool isCaptain;
  final bool isMe;
  final Color accentColor;

  const _PlayerCardProfileSection({
    required this.nickname,
    this.subtitle,
    this.avatarUrl,
    required this.effectiveInitials,
    required this.isCaptain,
    required this.isMe,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar mais leve e proporcional (52px)
          _buildAvatar(colorScheme, size: 52),
          const SizedBox(width: 13),
          // Informações do Jogador
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  nickname,
                  style: textTheme.titleMedium?.copyWith(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: isMe
                        ? AppColors.primaryNeon
                        : (isCaptain ? AppColors.dotaGold : Colors.white),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null &&
                    subtitle!.trim().isNotEmpty &&
                    subtitle!.trim() != nickname.trim()) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 12.0,
                      color: colorScheme.onSurface.withValues(alpha: 0.60),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (isCaptain) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.dotaGold.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.dotaGold, width: 0.8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.stars_rounded, color: AppColors.dotaGold, size: 11),
                        SizedBox(width: 4),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(ColorScheme colorScheme, {double size = 52}) {
    final hasValidAvatar = avatarUrl != null &&
        avatarUrl!.trim().isNotEmpty &&
        (avatarUrl!.startsWith('http://') || avatarUrl!.startsWith('https://'));

    Widget imageWidget;
    if (hasValidAvatar) {
      imageWidget = Image.network(
        avatarUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildInitialsFallback(colorScheme, size: size),
      );
    } else {
      imageWidget = _buildInitialsFallback(colorScheme, size: size);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isMe
              ? AppColors.primaryNeon
              : (isCaptain
                  ? AppColors.dotaGold
                  : AppColors.border),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipOval(child: imageWidget),
    );
  }

  Widget _buildInitialsFallback(ColorScheme colorScheme, {double size = 52}) {
    return Container(
      color: AppColors.canvasSurface,
      alignment: Alignment.center,
      child: Text(
        effectiveInitials,
        style: TextStyle(
          fontSize: size * 0.35,
          fontWeight: FontWeight.w800,
          color: isCaptain ? AppColors.dotaGold : AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// Bloco 3: Botões externos Steam e OpenDota
class _PlayerCardExternalButtons extends StatelessWidget {
  final String? steamProfileUrl;
  final String? openDotaUrl;
  final String? steamId;
  final VoidCallback? onOpenSteamProfile;
  final VoidCallback? onOpenOpenDota;

  const _PlayerCardExternalButtons({
    this.steamProfileUrl,
    this.openDotaUrl,
    this.steamId,
    this.onOpenSteamProfile,
    this.onOpenOpenDota,
  });

  @override
  Widget build(BuildContext context) {
    final hasSteam = steamProfileUrl != null && steamProfileUrl!.trim().isNotEmpty;
    final hasOpenDota = openDotaUrl != null && openDotaUrl!.trim().isNotEmpty;

    return Row(
      children: [
        // Botão Steam sóbrio e leve
        Expanded(
          child: SizedBox(
            height: 30,
            child: Material(
              color: AppColors.canvasSurface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(6),
              child: InkWell(
                onTap: onOpenSteamProfile ??
                    (hasSteam
                        ? () => SafeUrlLauncher.open(context, steamProfileUrl!, platformName: 'Steam')
                        : (steamId != null
                            ? () => SafeUrlLauncher.openSteamProfile(context, steamId!)
                            : null)),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.border,
                      width: 0.85,
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sports_esports_rounded, size: 12.5, color: AppColors.textSecondary),
                      SizedBox(width: 5),
                      Text(
                        'Steam',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.open_in_new_rounded, size: 10.5, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Botão OpenDota sóbrio e leve
        Expanded(
          child: SizedBox(
            height: 30,
            child: Material(
              color: AppColors.canvasSurface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(6),
              child: InkWell(
                onTap: onOpenOpenDota ??
                    (hasOpenDota
                        ? () => SafeUrlLauncher.open(context, openDotaUrl!, platformName: 'OpenDota')
                        : null),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.border,
                      width: 0.85,
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bar_chart_rounded, size: 12.5, color: AppColors.textSecondary),
                      SizedBox(width: 5),
                      Text(
                        'OpenDota',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.open_in_new_rounded, size: 10.5, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
