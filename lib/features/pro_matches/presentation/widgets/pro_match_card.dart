import 'package:flutter/material.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/theme/theme.dart';
import '../../models/pro_matches_dto.dart';
import 'pro_stream_chip.dart';

/// Card de partida profissional no padrão visual de [AppPlayerCard]:
/// - Superfície escura com hover glow dourado (ou neon ao vivo), sombra e marca d'água Tsurus;
/// - Faixinha superior (28px) com status/horário à esquerda e formato (BO3/BO5) à direita;
/// - Corpo compacto de confronto (Time A vs Placar/VS vs Time B);
/// - Rodapé sutil com botões de transmissão externa.
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
                right: -10,
                top: -10,
                width: 110,
                height: 110,
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

                  // 2. Corpo do Confronto
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: _buildMatchupRow(match, isLive),
                  ),

                  // 3. Rodapé Sutil de Transmissões
                  _MatchStreamsFooter(match: match),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchupRow(ProMatchDto match, bool isLive) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _ProTeamBadgeColumn(team: match.teamA),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: _buildCenterVersus(match, isLive),
        ),
        Expanded(
          child: _ProTeamBadgeColumn(team: match.teamB),
        ),
      ],
    );
  }

  Widget _buildCenterVersus(ProMatchDto match, bool isLive) {
    if (isLive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: AppColors.onBackground,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.canvasSurface.withValues(alpha: 0.75),
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
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
          color: AppColors.dotaGold,
        ),
      ),
    );
  }
}

/// Faixinha superior do card (28px), espelhando o padrão visual de [AppPlayerCard].
class _MatchTopStrip extends StatelessWidget {
  final ProMatchDto match;

  const _MatchTopStrip({required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
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
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

/// Bloco de exibição de uma equipe (emblema circular em destaque + nome).
class _ProTeamBadgeColumn extends StatelessWidget {
  final ProTeamDto team;

  const _ProTeamBadgeColumn({required this.team});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          padding: const EdgeInsets.all(6),
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
        ),
        const SizedBox(height: 8),
        Tooltip(
          message: team.name,
          waitDuration: const Duration(milliseconds: 500),
          child: Text(
            team.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: AppColors.onBackground,
              height: 1.15,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildAcronymFallback() {
    return Center(
      child: Text(
        team.displayAcronym,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          color: AppColors.dotaGoldLight,
        ),
        maxLines: 1,
        overflow: TextOverflow.clip,
      ),
    );
  }
}

/// Rodapé compacto de streams no estilo sutil do [AppPlayerCard].
class _MatchStreamsFooter extends StatelessWidget {
  final ProMatchDto match;

  const _MatchStreamsFooter({required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
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
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: match.streams
                  .map((stream) => ProStreamChip(stream: stream))
                  .toList(growable: false),
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
