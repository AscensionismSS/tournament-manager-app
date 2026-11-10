import 'package:flutter/material.dart';
import '../../features/tournaments/models/tournament_dto.dart';
import '../theme/theme.dart';
import 'app_card.dart';
import 'tournament_card_sections.dart';

/// Card unificado e oficial de exibição de Campeonatos na Arena Competitiva (Shared Widget - SRP).
/// Orquestra de forma enxuta os sub-blocos de [TournamentCardBannerHeader], [TournamentCardSpecsRow]
/// e [TournamentCardFooter], seguindo o Design System Dark e Dumb UI.
class AppTournamentCard extends StatefulWidget {
  final TournamentDto tournament;
  final VoidCallback? onTap;

  const AppTournamentCard({
    super.key,
    required this.tournament,
    this.onTap,
  });

  @override
  State<AppTournamentCard> createState() => _AppTournamentCardState();
}

class _AppTournamentCardState extends State<AppTournamentCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.tournament;
    final isOpen = t.isRegistrationOpen;
    final accentColor = isOpen ? AppColors.dotaGold : AppColors.primaryNeon;

    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _isHovered
                  ? accentColor.withValues(alpha: 0.85)
                  : (isOpen
                      ? AppColors.dotaGold.withValues(alpha: 0.45)
                      : AppColors.border.withValues(alpha: 0.85)),
              width: _isHovered ? 1.6 : 1.2,
            ),
            boxShadow: [
              if (_isHovered)
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.22),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(18),
              splashColor: accentColor.withValues(alpha: 0.12),
              highlightColor: accentColor.withValues(alpha: 0.06),
              child: AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Capa / Banner Superior com Badges de Inscrição e Fase
                    TournamentCardBannerHeader(tournament: t),

                    // 2. Corpo Principal com Informações Básicas do Campeonato
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            _buildSubtitleRow(t),
                            const SizedBox(height: 12),
                            TournamentCardSpecsRow(tournament: t),
                            const Spacer(),
                            _buildSlotsProgress(t, isOpen, accentColor),
                          ],
                        ),
                      ),
                    ),

                    // 3. Divisória Estética
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.border.withValues(alpha: 0.15),
                            accentColor.withValues(alpha: 0.45),
                            AppColors.border.withValues(alpha: 0.15),
                          ],
                        ),
                      ),
                    ),

                    // 4. Rodapé de Ação
                    TournamentCardFooter(
                      tournament: t,
                      isHovered: _isHovered,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitleRow(TournamentDto t) {
    if (t.hasChampion) {
      return Row(
        children: [
          const Icon(Icons.workspace_premium_rounded, size: 14, color: AppColors.dotaGold),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              'Campeão: ${t.championName}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.dotaGoldLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textSecondary),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            'Início: ${t.startDateLabel} • Fim: ${t.endDateLabel}',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSlotsProgress(TournamentDto t, bool isOpen, Color barColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.groups_rounded, size: 15, color: barColor),
                const SizedBox(width: 6),
                Text(
                  t.teamsProgressLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Text(
              t.slotsSummaryLabel,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: t.isFull
                    ? AppColors.textSecondary
                    : (isOpen ? AppColors.dotaGoldLight : AppColors.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: t.occupancyProgress,
            minHeight: 5,
            backgroundColor: AppColors.surfaceHighlight,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}
