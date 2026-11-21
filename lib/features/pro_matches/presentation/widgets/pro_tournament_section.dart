import 'package:flutter/material.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/theme/theme.dart';
import '../../controllers/pro_matches_controller.dart';
import '../../models/pro_matches_dto.dart';
import 'pro_match_card.dart';

/// Seção visual agrupada por campeonato profissional (cabeçalho com logo/tier/premiação,
/// divisores com [AppSectionHeader] e grid responsivo de [ProMatchCard] no padrão [AppPlayerCard]).
class ProTournamentSection extends StatelessWidget {
  final ProTournamentGroupDto tournament;
  final ProMatchFilter activeFilter;
  final String searchQuery;

  const ProTournamentSection({
    super.key,
    required this.tournament,
    required this.activeFilter,
    this.searchQuery = '',
  });

  List<ProMatchDto> _filterMatches(List<ProMatchDto> matches) {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return matches;

    // Se o termo de busca bate no próprio nome/liga do campeonato, mostra todas as partidas dele
    final matchesTournamentName =
        tournament.name.toLowerCase().contains(query) ||
            tournament.leagueName.toLowerCase().contains(query);
    if (matchesTournamentName) return matches;

    return matches.where((m) {
      return m.teamA.name.toLowerCase().contains(query) ||
          m.teamA.acronym.toLowerCase().contains(query) ||
          m.teamB.name.toLowerCase().contains(query) ||
          m.teamB.acronym.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final showUpcoming = activeFilter != ProMatchFilter.live;

    final liveMatches = _filterMatches(tournament.liveMatches);
    final upcomingMatches =
        showUpcoming ? _filterMatches(tournament.upcomingMatches) : const <ProMatchDto>[];

    return AppCard(
      padding: EdgeInsets.zero,
      backgroundOpacity: 0.96,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Faixa superior de destaque imediato (Dourado para MAJOR S, Ciano sutil para Tier A)
          Container(
            height: tournament.isMajor ? 3.5 : 2.0,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  tournament.tierColor,
                  tournament.tierColor.withValues(alpha: tournament.isMajor ? 0.45 : 0.25),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // 1. Cabeçalho em destaque do Campeonato
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            decoration: BoxDecoration(
              color: AppColors.canvasSurface.withValues(alpha: 0.65),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.8),
                  width: 1.0,
                ),
              ),
            ),
            child: _buildTournamentHeader(),
          ),

          // 2. Corpo com Grid Responsivo de Partidas (Ao Vivo e Próximas)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (liveMatches.isNotEmpty) ...[
                  AppSectionHeader(
                    title: 'AO VIVO AGORA',
                    countLabel:
                        '${liveMatches.length} ${liveMatches.length == 1 ? "partida" : "partidas"}',
                  ),
                  const SizedBox(height: 12),
                  _buildMatchesList(liveMatches),
                ],

                if (liveMatches.isNotEmpty && upcomingMatches.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const AppDivider.neon(),
                  const SizedBox(height: 16),
                ],

                if (upcomingMatches.isNotEmpty) ...[
                  AppSectionHeader(
                    title: 'PRÓXIMAS PARTIDAS',
                    countLabel:
                        '${upcomingMatches.length} ${upcomingMatches.length == 1 ? "partida" : "partidas"}',
                  ),
                  const SizedBox(height: 12),
                  _buildMatchesList(upcomingMatches),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchesList(List<ProMatchDto> matches) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: matches
          .asMap()
          .entries
          .map(
            (entry) => Padding(
              padding: EdgeInsets.only(
                bottom: entry.key == matches.length - 1 ? 0 : 12,
              ),
              child: ProMatchCard(match: entry.value),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildTournamentHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo da Liga em destaque (com anel temático e fundo neutro para logos claros/escuros)
        Container(
          width: 56,
          height: 56,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: tournament.tierColor.withValues(alpha: 0.55),
              width: 1.2,
            ),
          ),
          child: tournament.hasLogo
              ? Image.network(
                  tournament.leagueLogoUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => _buildFallbackLogo(),
                )
              : _buildFallbackLogo(),
        ),
        const SizedBox(width: 16),

        // Nome protagonista do Campeonato + Metadados + Badge Ao Vivo à direita
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      tournament.name,
                      style: AppText.h2.copyWith(
                        fontSize: 20.0,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.25,
                        height: 1.2,
                        color: AppColors.onBackground,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (tournament.hasLiveMatches) ...[
                    const SizedBox(width: 12),
                    const AppBadge.dot(
                      label: 'AO VIVO',
                      customColor: AppColors.primaryNeon,
                      height: 24,
                      fontSize: 10.5,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (tournament.hasTier)
                    AppBadge.pill(
                      label: tournament.tierBadgeText,
                      icon: tournament.tierIcon,
                      customColor: tournament.tierColor,
                      height: 24,
                      fontSize: 10.5,
                    ),
                  if (tournament.hasPrizePool)
                    _buildMetaPill(
                      icon: Icons.emoji_events_rounded,
                      iconColor: AppColors.dotaGold,
                      text: tournament.prizePool!,
                      highlight: true,
                    ),
                  if (tournament.hasPeriod)
                    _buildMetaPill(
                      icon: Icons.calendar_today_rounded,
                      iconColor: AppColors.textSecondary,
                      text: tournament.periodLabel,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackLogo() {
    return Icon(
      tournament.tierIcon,
      size: 26,
      color: tournament.tierColor,
    );
  }

  Widget _buildMetaPill({
    required IconData icon,
    required Color iconColor,
    required String text,
    bool highlight = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: iconColor),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
            color: highlight ? AppColors.dotaGoldLight : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
