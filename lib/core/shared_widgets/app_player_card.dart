import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../feedback/app_feedback.dart';
import '../theme/theme.dart';
import '../utils/safe_url_launcher.dart';
import 'app_avatar.dart';
import 'dota_rank_medal.dart';
import 'dota_role_icons.dart';

/// Card unificado e oficial de exibição de Jogadores Competitivos / Membros.
/// Hierarquia limpa em 2 zonas:
/// - Zona Principal: Avatar (com fallback para o símbolo Tsurus sem "?" nem iniciais) + Nickname protagonista + Medalha & Funções.
/// - Rodapé Sutil: Dota ID discreto copiável à esquerda e links compactos (Steam / OpenDota) à direita.
class AppPlayerCard extends StatefulWidget {
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

  @override
  State<AppPlayerCard> createState() => _AppPlayerCardState();
}

class _AppPlayerCardState extends State<AppPlayerCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bool isUnranked =
        widget.rankDetail.toUpperCase() == 'SEM RANK' || widget.rankDetail.isEmpty;

    final Color borderColor = widget.isMe
        ? AppColors.primaryNeon.withValues(alpha: _isHovered ? 0.95 : 0.72)
        : widget.isCaptain
            ? AppColors.dotaGold.withValues(alpha: _isHovered ? 0.85 : 0.55)
            : _isHovered
                ? AppColors.dotaGold.withValues(alpha: 0.42)
                : AppColors.border.withValues(alpha: 0.80);

    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            splashColor: AppColors.dotaGold.withValues(alpha: 0.08),
            highlightColor: AppColors.dotaGold.withValues(alpha: 0.04),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              constraints: const BoxConstraints(minHeight: 140),
              decoration: BoxDecoration(
                color: _isHovered
                    ? AppColors.surfaceHighlight.withValues(alpha: 0.55)
                    : colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borderColor,
                  width: (widget.isMe || widget.isCaptain) ? 1.15 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: _isHovered ? 0.34 : 0.18),
                    blurRadius: _isHovered ? 14 : 6,
                    offset: Offset(0, _isHovered ? 4 : 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // Marca d'água oficial do símbolo da logo do site (Tsurus)
                  Positioned(
                    right: -10,
                    top: -10,
                    width: 115,
                    height: 115,
                    child: IgnorePointer(
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/company_logo.jpg',
                          cacheWidth: 256,
                          opacity: const AlwaysStoppedAnimation(0.04),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),

                  // Conteúdo estruturado em 3 zonas limpas: Faixinha no Topo, Identidade e Rodapé
                  Positioned.fill(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Faixinha no Topo (Rank na extrema esquerda e Funções Dota 2 no extremo direito)
                        _PlayerCardTopStrip(
                          rankDetail: widget.rankDetail,
                          rankStars: widget.rankStars,
                          leaderboardRank: widget.leaderboardRank,
                          isUnranked: isUnranked,
                          roles: widget.roles,
                          preferredRole: widget.preferredRole,
                          isCaptain: widget.isCaptain,
                        ),

                        // Zona 1: Identidade Principal (Avatar + Nickname Protagonista Ampliado)
                        Expanded(
                          child: _PlayerCardIdentityBody(
                            nickname: widget.nickname,
                            subtitle: widget.subtitle,
                            avatarUrl: widget.avatarUrl,
                            isCaptain: widget.isCaptain,
                            isMe: widget.isMe,
                          ),
                        ),

                        // Zona 2: Rodapé Sutil com Botões Contornados (ID à esquerda + Ações Steam/OpenDota à direita)
                        _PlayerCardCompactFooter(
                          steamId: widget.steamId,
                          steamProfileUrl: widget.steamProfileUrl,
                          openDotaUrl: widget.openDotaUrl,
                          onCopySteamId: widget.onCopySteamId,
                          onOpenSteamProfile: widget.onOpenSteamProfile,
                          onOpenOpenDota: widget.onOpenOpenDota,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Faixinha Superior: Rank na extrema esquerda e Funções Dota 2 no extremo direito
class _PlayerCardTopStrip extends StatelessWidget {
  final String rankDetail;
  final int rankStars;
  final int? leaderboardRank;
  final bool isUnranked;
  final List<String> roles;
  final String? preferredRole;
  final bool isCaptain;

  const _PlayerCardTopStrip({
    required this.rankDetail,
    required this.rankStars,
    this.leaderboardRank,
    required this.isUnranked,
    required this.roles,
    this.preferredRole,
    required this.isCaptain,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 14),
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
          // Extrema Esquerda: Badge de Capitão (se houver) + Medalha e Nome do Rank
          if (isCaptain) ...[
            _buildRolePill(
              label: 'CAPITÃO',
              icon: Icons.stars_rounded,
              color: AppColors.dotaGold,
            ),
            const SizedBox(width: 8),
          ],

          DotaRankMedal(
            rankTier: rankDetail,
            rankStars: rankStars,
            leaderboardRank: leaderboardRank,
            size: 20,
            showBadgeNumber: false,
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(
              rankDetail,
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w800,
                color: isUnranked
                    ? AppColors.textSecondary.withValues(alpha: 0.6)
                    : AppColors.dotaGoldLight,
                letterSpacing: 0.35,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const Spacer(),

          // Extremo Direito: Funções Dota 2 (empurradas pelo Spacer até a borda direita)
          if (roles.isNotEmpty)
            DotaRolesDisplay.fromStrings(
              rawRoles: roles,
              preferredRoleKey: preferredRole,
              boxWidth: 20.0,
              boxHeight: 20.0,
              iconSize: 12.5,
              spacing: 4.0,
              showBoxes: true,
            ),
        ],
      ),
    );
  }

  Widget _buildRolePill({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 10),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Zona 1: Identidade Principal do Jogador (Avatar + Nickname Protagonista Ampliado)
class _PlayerCardIdentityBody extends StatelessWidget {
  final String nickname;
  final String? subtitle;
  final String? avatarUrl;
  final bool isCaptain;
  final bool isMe;

  const _PlayerCardIdentityBody({
    required this.nickname,
    this.subtitle,
    this.avatarUrl,
    required this.isCaptain,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildAvatar(size: 54),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Nickname Protagonista Ampliado (21px, bold, com proteção contra nicknames longos)
                Tooltip(
                  message: nickname,
                  waitDuration: const Duration(milliseconds: 500),
                  child: Text(
                    nickname,
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: 21.0,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                      height: 1.15,
                      color: isMe
                          ? AppColors.primaryNeon
                          : Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                if (subtitle != null &&
                    subtitle!.trim().isNotEmpty &&
                    subtitle!.trim() != nickname.trim()) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 12.0,
                      color: colorScheme.onSurface.withValues(alpha: 0.58),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar({double size = 54}) {
    final trimmedUrl = avatarUrl?.trim();
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
          color: isMe
              ? AppColors.primaryNeon
              : isCaptain
                  ? AppColors.dotaGold
                  : AppColors.border.withValues(alpha: 0.9),
          width: (isMe || isCaptain) ? 1.4 : 1.0,
        ),
      ),
      child: ClipOval(child: imageWidget),
    );
  }
}

/// Zona 2: Rodapé Sóbrio e Enxuto (Dota ID copiável discreto + Ações compactas Steam/OpenDota)
class _PlayerCardCompactFooter extends StatelessWidget {
  final String? steamId;
  final String? steamProfileUrl;
  final String? openDotaUrl;
  final VoidCallback? onCopySteamId;
  final VoidCallback? onOpenSteamProfile;
  final VoidCallback? onOpenOpenDota;

  const _PlayerCardCompactFooter({
    this.steamId,
    this.steamProfileUrl,
    this.openDotaUrl,
    this.onCopySteamId,
    this.onOpenSteamProfile,
    this.onOpenOpenDota,
  });

  @override
  Widget build(BuildContext context) {
    final hasId = steamId != null && steamId!.trim().isNotEmpty;
    final hasSteam =
        (steamProfileUrl != null && steamProfileUrl!.trim().isNotEmpty) || hasId;
    final hasOpenDota = openDotaUrl != null && openDotaUrl!.trim().isNotEmpty;

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.canvasSurface.withValues(alpha: 0.42),
        border: Border(
          top: BorderSide(
            color: AppColors.border.withValues(alpha: 0.50),
            width: 0.85,
          ),
        ),
      ),
      child: Row(
        children: [
          if (hasId)
            _DiscreteIdCopyButton(
              id: steamId!.trim(),
              onCopySteamId: onCopySteamId,
            )
          else
            Text(
              'Sem ID vinculado',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary.withValues(alpha: 0.45),
              ),
            ),
          const Spacer(),
          _CompactExternalLink(
            icon: Icons.sports_esports_rounded,
            label: 'Steam',
            onTap: onOpenSteamProfile ??
                (hasSteam
                    ? () {
                        if (steamProfileUrl != null &&
                            steamProfileUrl!.trim().isNotEmpty) {
                          SafeUrlLauncher.open(
                            context,
                            steamProfileUrl!,
                            platformName: 'Steam',
                          );
                        } else if (hasId) {
                          SafeUrlLauncher.openSteamProfile(context, steamId!);
                        }
                      }
                    : null),
          ),
          const SizedBox(width: 6),
          _CompactExternalLink(
            icon: Icons.bar_chart_rounded,
            label: 'OpenDota',
            onTap: onOpenOpenDota ??
                (hasOpenDota
                    ? () => SafeUrlLauncher.open(
                          context,
                          openDotaUrl!,
                          platformName: 'OpenDota',
                        )
                    : null),
          ),
        ],
      ),
    );
  }
}

class _DiscreteIdCopyButton extends StatefulWidget {
  final String id;
  final VoidCallback? onCopySteamId;

  const _DiscreteIdCopyButton({
    required this.id,
    this.onCopySteamId,
  });

  @override
  State<_DiscreteIdCopyButton> createState() => _DiscreteIdCopyButtonState();
}

class _DiscreteIdCopyButtonState extends State<_DiscreteIdCopyButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final fgColor = _hovered
        ? AppColors.dotaGoldLight
        : AppColors.textSecondary.withValues(alpha: 0.85);

    return Tooltip(
      message: 'Copiar Dota ID (${widget.id})',
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: InkWell(
          onTap: widget.onCopySteamId ??
              () {
                Clipboard.setData(ClipboardData(text: widget.id));
                AppFeedback.showSuccess(
                  context,
                  title: 'DOTA ID COPIADO',
                  message: 'Dota ID (${widget.id}) copiado! Cole no jogo para adicionar.',
                );
              },
          borderRadius: BorderRadius.circular(5),
          child: Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: _hovered
                  ? AppColors.dotaGold.withValues(alpha: 0.12)
                  : AppColors.canvasSurface.withValues(alpha: 0.50),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: _hovered
                    ? AppColors.dotaGold.withValues(alpha: 0.55)
                    : AppColors.border.withValues(alpha: 0.75),
                width: 0.85,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ID ${widget.id}',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: fgColor,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.content_copy_rounded,
                  size: 11,
                  color: fgColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactExternalLink extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _CompactExternalLink({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  State<_CompactExternalLink> createState() => _CompactExternalLinkState();
}

class _CompactExternalLinkState extends State<_CompactExternalLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final fgColor = !enabled
        ? AppColors.textSecondary.withValues(alpha: 0.30)
        : _hovered
            ? AppColors.dotaGoldLight
            : AppColors.textSecondary.withValues(alpha: 0.85);

    return MouseRegion(
      onEnter: enabled ? (_) => setState(() => _hovered = true) : null,
      onExit: enabled ? (_) => setState(() => _hovered = false) : null,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(5),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(5),
          child: Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: _hovered
                  ? AppColors.dotaGold.withValues(alpha: 0.12)
                  : AppColors.canvasSurface.withValues(alpha: 0.50),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: _hovered
                    ? AppColors.dotaGold.withValues(alpha: 0.55)
                    : AppColors.border.withValues(alpha: 0.75),
                width: 0.85,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 12, color: fgColor),
                const SizedBox(width: 4),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: fgColor,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.open_in_new_rounded, size: 10, color: fgColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
