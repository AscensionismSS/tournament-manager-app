import 'package:flutter/material.dart';
import '../../../../../core/shared_widgets/app_card.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../draft/models/draft_team_dto.dart';
import '../../../models/match_game_dto.dart';
import '../../../models/match_series_dto.dart';
import 'game_stats_tables.dart';

/// Abas disponíveis na visualização detalhada do mapa
enum GameStatsTab {
  /// Estatísticas gerais de combate e farm (KDA, Net Worth, GPM, XPM)
  general,

  /// Objetivos do mapa (Dano a heróis, dano a estruturas, cura, wards colocadas e destruídas)
  objectives,

  /// Inventário completo (6 slots principais, 3 de mochila, sequência de tiers de jungle e buffs)
  items,
}

/// Modo de exibição do nome do jogador nas estatísticas
enum PlayerNameDisplayMode {
  /// Nick oficial registrado na plataforma Tsurus
  tsurus,

  /// Nick que o jogador estava usando na conta Steam durante a partida
  steam,
}

/// Orquestrador enxuto de estatísticas completas de jogadores e heróis de um mapa (SRP & Dumb UI).
/// Delega a barra de controle e as tabelas modulares para `GameStatsControlBar` e `GameTeamStatsSection`.
class GamePlayerStatsView extends StatefulWidget {
  final MatchSeriesDto series;
  final MatchGameDto game;
  final List<DraftTeamDto>? draftTeams;
  final VoidCallback? onClose;

  const GamePlayerStatsView({
    super.key,
    required this.series,
    required this.game,
    this.draftTeams,
    this.onClose,
  });

  @override
  State<GamePlayerStatsView> createState() => _GamePlayerStatsViewState();
}

class _GamePlayerStatsViewState extends State<GamePlayerStatsView> {
  GameStatsTab _currentTab = GameStatsTab.general;
  PlayerNameDisplayMode _nameMode = PlayerNameDisplayMode.tsurus;

  @override
  Widget build(BuildContext context) {
    final teamAPlayers = widget.game.playerStats
        .where((p) => p.teamId == widget.series.teamAId)
        .toList();
    final teamBPlayers = widget.game.playerStats
        .where((p) => p.teamId == widget.series.teamBId)
        .toList();

    final hasStats = widget.game.playerStats.isNotEmpty;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Barra de Controle Superior: Abas [ GERAL | OBJETIVOS | ITENS ] + Switch DISPLAY NAME (desabilitada quando sem dados)
          GameStatsControlBar(
            enabled: hasStats,
            currentTab: _currentTab,
            onTabChanged: (tab) => setState(() => _currentTab = tab),
            nameMode: _nameMode,
            onNameModeChanged: (mode) => setState(() => _nameMode = mode),
          ),

          const SizedBox(height: 8),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 8),

          // 2. Conteúdo das Tabelas de Estatísticas por Time (ou Card Explicativo neutro na mesma altura física)
          if (!hasStats)
            _EmptyPlayerStatsPlaceholder(isWalkover: widget.game.isWalkover)
          else ...[
            GameTeamStatsSection(
              teamName: widget.series.displayTeamA,
              teamId: widget.series.teamAId,
              players: teamAPlayers,
              draftTeams: widget.draftTeams,
              currentTab: _currentTab,
              nameMode: _nameMode,
              roshanKills: widget.game.teamARoshanKills,
              aegisStolen: widget.game.teamAAegisStolen,
            ),
            const SizedBox(height: 10),
            GameTeamStatsSection(
              teamName: widget.series.displayTeamB,
              teamId: widget.series.teamBId,
              players: teamBPlayers,
              draftTeams: widget.draftTeams,
              currentTab: _currentTab,
              nameMode: _nameMode,
              roshanKills: widget.game.teamBRoshanKills,
              aegisStolen: widget.game.teamBAegisStolen,
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyPlayerStatsPlaceholder extends StatelessWidget {
  final bool isWalkover;

  const _EmptyPlayerStatsPlaceholder({required this.isWalkover});

  @override
  Widget build(BuildContext context) {
    final IconData icon =
        isWalkover ? Icons.event_busy_rounded : Icons.edit_note_rounded;
    final String title = isWalkover
        ? 'Partida decidida por W.O.'
        : 'Resultado registrado manualmente';

    return SizedBox(
      height: 380,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        decoration: BoxDecoration(
          color: AppColors.canvasSurface.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.45),
            width: 0.8,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                  border: Border.all(
                    color: AppColors.borderHighlight.withValues(alpha: 0.7),
                    width: 1.0,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: AppColors.textSecondary.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sem dados de draft e estatísticas para exibir.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
