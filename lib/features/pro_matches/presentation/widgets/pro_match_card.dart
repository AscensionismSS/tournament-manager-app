import 'package:flutter/material.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/theme/theme.dart';
import '../../models/pro_matches_dto.dart';
import 'pro_stream_chip.dart';

/// Card em lista de partida profissional com a estética do [AppPlayerCard]:
/// - Superfície escura com hover glow dourado (ou neon ao vivo), sombra e marca d'água Tsurus;
/// - Faixinha superior (30px) com status/horário à esquerda e formato (BO3/BO5) à direita;
/// - Confronto horizontal largo (Time A vs Placar/VS vs Time B) no desktop e empilhado no mobile;
/// - Rodapé sutil com espaço amplo para múltiplas transmissões (Twitch, YouTube, Kick) sem quebrar layout.
class ProMatchCard extends StatefulWidget {
  final ProMatchDto match;

  const ProMatchCard({
    super.key,
    required this.match,
  });

  @override
  State<ProMatchCard> createState() => _ProMatchCardState();
}

class _ProMatchCardState extends State<ProMatchCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final isLive = match.isLive;

    final Color borderColor = isLive
        ? AppColors.primaryNeon.withValues(alpha: _isHovered ? 0.95 : 0.65)
        : _isHovered
            ? AppColors.dotaGold.withValues(alpha: 0.45)
            : AppColors.border.withValues(alpha: 0.80);

    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: _isHovered
                ? AppColors.surfaceHighlight.withValues(alpha: 0.55)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: isLive ? 1.15 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isHovered ? 0.34 : 0.18),
                blurRadius: _isHovered ? 14 : 6,
                offset: Offset(0, _isHovered ? 4 : 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Marca d'água oficial do símbolo da logo do site (Tsurus)
              Positioned(
                right: -12,
                top: -12,
                width: 118,
                height: 118,
                child: IgnorePointer(
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/company_logo.jpg',
                      cacheWidth: 256,
                      opacity: const AlwaysStoppedAnimation(0.04),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Faixinha no Topo (Status/Horário à esquerda + Formato BO3/BO5 à direita)
                  _MatchTopStrip(match: match),

                  // 2. Corpo do Confronto (largo no desktop, compacto no mobile)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 520;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: isCompact
                            ? _buildCompactMatchup(match, isLive)
                            : _buildWideMatchup(match, isLive),
                      );
                    },
                  ),

                  // 3. Rodapé Sutil de Transmissões (comporta várias plataformas lado a lado)
                  _MatchStreamsFooter(match: match),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWideMatchup(ProMatchDto match, bool isLive) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _ProTeamRow(
            team: match.teamA,
            alignRight: true,
          ),
        ),
        const SizedBox(width: 18),
        _buildCenterBadge(match, isLive),
        const SizedBox(width: 18),
        Expanded(
          child: _ProTeamRow(
            team: match.teamB,
            alignRight: false,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactMatchup(ProMatchDto match, bool isLive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _ProTeamRow(
                team: match.teamA,
                alignRight: false,
              ),
            ),
            if (isLive)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  '${match.scoreTeamA}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.onBackground,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ProTeamRow(
                team: match.teamB,
                alignRight: false,
              ),
            ),
            if (isLive)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  '${match.scoreTeamB}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.onBackground,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCenterBadge(ProMatchDto match, bool isLive) {
    if (isLive) {
      return Container(
        constraints: const BoxConstraints(minWidth: 74),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primaryNeon.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.primaryNeon.withValues(alpha: 0.45),
            width: 1.0,
          ),
        ),
        child: Text(
          match.scoreLabel,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
            color: AppColors.onBackground,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.canvasSurface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.65),
          width: 0.9,
        ),
      ),
      child: const Text(
        'VS',
        style: TextStyle(
          fontFamily: 'Oswald',
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
          color: AppColors.dotaGold,
        ),
      ),
    );
  }
}

/// Faixinha superior do card (30px), espelhando o padrão visual de [AppPlayerCard].
class _MatchTopStrip extends StatelessWidget {
  final ProMatchDto match;

  const _MatchTopStrip({required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.canvasSurface.withValues(alpha: 0.58),
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: 0.42),
            width: 0.85,
          ),
        ),
      ),
      child: Row(
        children: [
          if (match.isLive)
            const AppBadge.dot(
              label: 'AO VIVO',
              customColor: AppColors.primaryNeon,
              height: 20,
              fontSize: 9.5,
            )
          else
            Expanded(
              child: Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 13,
                    color: AppColors.dotaGold,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      '${match.formattedScheduledTime} • ${match.formattedScheduledDate}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dotaGoldLight,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          if (match.isLive) const Spacer(),
          if (match.hasFormat)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceHighlight.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppColors.borderHighlight.withValues(alpha: 0.7),
                  width: 0.8,
                ),
              ),
              child: Text(
                match.formatLabel,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Exibição horizontal de uma equipe (nome + emblema circular).
class _ProTeamRow extends StatelessWidget {
  final ProTeamDto team;
  final bool alignRight;

  const _ProTeamRow({
    required this.team,
    required this.alignRight,
  });

  @override
  Widget build(BuildContext context) {
    final logo = _buildTeamLogo();
    final text = Flexible(
      child: Tooltip(
        message: team.name,
        waitDuration: const Duration(milliseconds: 500),
        child: Text(
          team.name,
          textAlign: alignRight ? TextAlign.right : TextAlign.left,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.onBackground,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );

    return Row(
      mainAxisAlignment:
          alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: alignRight
          ? [text, const SizedBox(width: 12), logo]
          : [logo, const SizedBox(width: 12), text],
    );
  }

  Widget _buildTeamLogo() {
    return Container(
      width: 38,
      height: 38,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.secondary.withValues(alpha: 0.16),
        border: Border.all(
          color: AppColors.borderHighlight.withValues(alpha: 0.85),
          width: 1.2,
        ),
      ),
      child: team.hasLogo
          ? ClipOval(
              child: Image.network(
                team.logoUrl!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => _buildAcronymFallback(),
              ),
            )
          : _buildAcronymFallback(),
    );
  }

  Widget _buildAcronymFallback() {
    return Center(
      child: Text(
        team.displayAcronym,
        style: const TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          color: AppColors.dotaGoldLight,
        ),
        maxLines: 1,
        overflow: TextOverflow.clip,
      ),
    );
  }
}

/// Rodapé sutil de streams no estilo do [AppPlayerCard].
class _MatchStreamsFooter extends StatelessWidget {
  final ProMatchDto match;

  const _MatchStreamsFooter({required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.canvasSurface.withValues(alpha: 0.35),
        border: Border(
          top: BorderSide(
            color: AppColors.border.withValues(alpha: 0.35),
            width: 0.85,
          ),
        ),
      ),
      child: match.hasStreams
          ? Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.podcasts_rounded,
                      size: 13.5,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'ASSISTIR:',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                ...match.streams.map((stream) => ProStreamChip(stream: stream)),
              ],
            )
          : Row(
              children: [
                Icon(
                  Icons.tv_off_rounded,
                  size: 13,
                  color: AppColors.textSecondary.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    match.isUpcoming
                        ? 'Transmissão a definir'
                        : 'Sem transmissão disponível',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary.withValues(alpha: 0.75),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
    );
  }
}
