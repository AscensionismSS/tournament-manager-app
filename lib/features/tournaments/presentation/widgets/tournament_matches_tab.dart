import 'package:flutter/material.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/theme/theme.dart';
import '../../models/match_series_dto.dart';
import '../../models/tournament_dto.dart';
import '../../models/tournament_team_dto.dart';
import '../../../draft/models/draft_team_dto.dart';
import 'tournament_matches_filter_bar.dart';
import 'tournament_round_section.dart';
import 'tournament_rules_button.dart';

/// Aba dedicada de Partidas e Calendário de Rodadas do Campeonato (Dumb UI).
/// Organiza as séries cronologicamente por Rodada (Round-Robin ou Chaves),
/// com filtros integrados por Rodada, Time e Status ('A Definir', 'Em Andamento', 'Finalizado').
class TournamentMatchesTab extends StatefulWidget {
  final TournamentDto tournament;
  final List<MatchSeriesDto> matches;
  final void Function(MatchSeriesDto match)? onMatchTap;
  final bool isAdmin;
  final void Function(MatchSeriesDto match, int gameIndex)? onRecordResult;
  final void Function(MatchSeriesDto match, int gameIndex)? onEditResult;
  final void Function(MatchSeriesDto match)? onAdminManage;
  final List<DraftTeamDto>? draftTeams;

  const TournamentMatchesTab({
    super.key,
    required this.tournament,
    required this.matches,
    this.onMatchTap,
    this.isAdmin = false,
    this.onRecordResult,
    this.onEditResult,
    this.onAdminManage,
    this.draftTeams,
  });

  @override
  State<TournamentMatchesTab> createState() => _TournamentMatchesTabState();
}

class _TournamentMatchesTabState extends State<TournamentMatchesTab> {
  int? _selectedRound;
  String? _selectedTeamId;
  String? _selectedStatus;

  bool get _hasActiveFilters =>
      _selectedRound != null ||
      _selectedTeamId != null ||
      _selectedStatus != null;

  void _clearFilters() {
    setState(() {
      _selectedRound = null;
      _selectedTeamId = null;
      _selectedStatus = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupOnlyMatches =
        widget.matches.where((m) => m.isGroupStageMatch).toList();

    if (groupOnlyMatches.isEmpty) {
      return _buildEmptyState();
    }

    // 1. Extração dinâmica de rodadas disponíveis (somente Fase de Grupos)
    final availableRounds = groupOnlyMatches.map((m) => m.round).toSet().toList()
      ..sort();

    // 2. Extração dinâmica de equipes a partir do torneio e das séries de grupos
    final teamsMap = <String, TournamentTeamDto>{};
    for (final t in widget.tournament.teams) {
      if (t.id.isNotEmpty) teamsMap[t.id] = t;
    }
    for (final m in groupOnlyMatches) {
      if (m.teamAId != null && !teamsMap.containsKey(m.teamAId)) {
        teamsMap[m.teamAId!] = TournamentTeamDto(
          id: m.teamAId!,
          name: m.displayTeamA,
        );
      }
      if (m.teamBId != null && !teamsMap.containsKey(m.teamBId)) {
        teamsMap[m.teamBId!] = TournamentTeamDto(
          id: m.teamBId!,
          name: m.displayTeamB,
        );
      }
    }
    final availableTeams = teamsMap.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    // 3. Aplicação reativa dos filtros nas partidas da Fase de Grupos
    final filteredMatches = groupOnlyMatches.where((m) {
      // Filtro por Rodada
      if (_selectedRound != null && m.round != _selectedRound) {
        return false;
      }

      // Filtro por Time
      if (_selectedTeamId != null) {
        final matchesTeamA = m.teamAId == _selectedTeamId;
        final matchesTeamB = m.teamBId == _selectedTeamId;
        if (!matchesTeamA && !matchesTeamB) {
          return false;
        }
      }

      // Filtro por Status
      if (_selectedStatus != null) {
        switch (_selectedStatus) {
          case 'pending':
            if (m.isCompleted || m.isOngoing || m.games.isNotEmpty) {
              return false;
            }
            break;
          case 'ongoing':
            if (!m.isOngoing && (m.isCompleted || m.games.isEmpty)) {
              return false;
            }
            break;
          case 'completed':
            if (!m.isCompleted) return false;
            break;
        }
      }

      return true;
    }).toList();

    // 4. Construtor dos dados de exibição de rodadas (Partidas de Grupos filtradas + Folgas REAIS filtradas)
    List<_RoundDisplayData> buildRoundSections(
        List<MatchSeriesDto> allStageMatches) {
      final rounds = allStageMatches.map((m) => m.round).toSet().toList()
        ..sort();
      final result = <_RoundDisplayData>[];

      for (final r in rounds) {
        if (_selectedRound != null && r != _selectedRound) continue;

        final allMatchesInRound =
            allStageMatches.where((m) => m.round == r).toList();

        final roundMatches =
            filteredMatches.where((m) => m.round == r).toList();

        List<TournamentTeamDto> roundByes = const [];
        if (widget.tournament.teamsPerGroup.isOdd) {
          final playingTeamIds = <String>{};
          for (final m in allMatchesInRound) {
            if (m.teamAId != null) playingTeamIds.add(m.teamAId!);
            if (m.teamBId != null) playingTeamIds.add(m.teamBId!);
          }
          final trueByes = widget.tournament.teams
              .where((t) => t.id.isNotEmpty && !playingTeamIds.contains(t.id))
              .toList();

          roundByes = trueByes.where((t) {
            if (_selectedTeamId != null && t.id != _selectedTeamId) {
              return false;
            }
            if (_selectedStatus != null && _selectedStatus != 'pending') {
              return false;
            }
            return true;
          }).toList();
        }

        final sectionData = _RoundDisplayData(
          round: r,
          isGroupStage: true,
          matches: roundMatches,
          byeTeams: roundByes,
        );

        if (sectionData.hasContent) {
          result.add(sectionData);
        }
      }

      return result;
    }

    final groupSections = buildRoundSections(groupOnlyMatches);
    final bool hasAnyContent = groupSections.isNotEmpty;

    final totalMatchesCount = filteredMatches.length;
    final totalByesCount =
        groupSections.fold<int>(0, (acc, s) => acc + s.byeTeams.length);

    final String totalCountLabel;
    if (_hasActiveFilters) {
      if (totalMatchesCount > 0 && totalByesCount > 0) {
        final sLabel =
            totalMatchesCount == 1 ? '1 SÉRIE' : '$totalMatchesCount SÉRIES';
        final bLabel =
            totalByesCount == 1 ? '1 FOLGA' : '$totalByesCount FOLGAS';
        totalCountLabel = '$sLabel • $bLabel';
      } else if (totalMatchesCount > 0) {
        totalCountLabel =
            '$totalMatchesCount de ${groupOnlyMatches.length} ${groupOnlyMatches.length == 1 ? "SÉRIE" : "SÉRIES"}';
      } else if (totalByesCount > 0) {
        totalCountLabel =
            '$totalByesCount ${totalByesCount == 1 ? "FOLGA ENCONTRADA" : "FOLGAS ENCONTRADAS"}';
      } else {
        totalCountLabel = '0 SÉRIES';
      }
    } else {
      totalCountLabel =
          '${groupOnlyMatches.length} ${groupOnlyMatches.length == 1 ? "SÉRIE" : "SÉRIES"}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cabeçalho da Seção com Botões de Ação
        AppSectionHeader(
          title: 'PARTIDAS DA FASE DE GRUPOS',
          countLabel: totalCountLabel,
          trailing: TournamentRulesButton(
            tournament: widget.tournament,
            label: 'REGRAS & FORMATO',
            tooltipMessage:
                'Regras de Formato, Folga (BYE) & Classificação',
          ),
        ),
        const SizedBox(height: 14),

        // Barra de Filtros Canônica: Rodada, Time, Status ('A Definir', 'Em Andamento', 'Finalizado')
        TournamentMatchesFilterBar(
          selectedRound: _selectedRound,
          availableRounds: availableRounds,
          onRoundChanged: (r) => setState(() => _selectedRound = r),
          selectedTeamId: _selectedTeamId,
          availableTeams: availableTeams,
          onTeamChanged: (t) => setState(() => _selectedTeamId = t),
          selectedStatus: _selectedStatus,
          onStatusChanged: (s) => setState(() => _selectedStatus = s),
          onClearFilters: _clearFilters,
          hasActiveFilters: _hasActiveFilters,
        ),
        const SizedBox(height: 18),

        // Estado Vazio caso a filtragem não encontre resultados (partidas nem folgas)
        if (!hasAnyContent) ...[
          _buildEmptyFilterState(),
        ] else ...[
          for (final section in groupSections) ...[
            TournamentRoundSection(
              tournament: widget.tournament,
              round: section.round,
              roundMatches: section.matches,
              byeTeams: section.byeTeams,
              onMatchTap: widget.onMatchTap,
              isAdmin: widget.isAdmin,
              onRecordResult: widget.onRecordResult,
              onEditResult: widget.onEditResult,
              onAdminManage: widget.onAdminManage,
              draftTeams: widget.draftTeams,
            ),
            const SizedBox(height: 24),
          ],
        ],
      ],
    );
  }

  Widget _buildEmptyFilterState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryNeon.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryNeon.withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
              child: const Icon(
                Icons.filter_list_off_rounded,
                size: 32,
                color: AppColors.primaryNeon,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'NENHUMA PARTIDA ENCONTRADA',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Não há confrontos que correspondam aos filtros selecionados.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              text: 'Limpar Filtros',
              icon: Icons.clear_all_rounded,
              variant: AppButtonVariant.outline,
              size: AppButtonSize.small,
              onPressed: _clearFilters,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final availableHeight =
        (MediaQuery.sizeOf(context).height - 420).clamp(320.0, 720.0);

    return AppEmptyState(
      icon: Icons.sports_esports_outlined,
      title: 'NENHUMA PARTIDA AGENDADA',
      message:
          'As rodadas e confrontos serão gerados automaticamente assim que as inscrições forem encerradas e o campeonato for iniciado.',
      minHeight: availableHeight,
    );
  }
}

/// Modelo de dados imutável para agregação de confrontos e folgas (BYEs) de uma rodada
class _RoundDisplayData {
  final int round;
  final bool isGroupStage;
  final List<MatchSeriesDto> matches;
  final List<TournamentTeamDto> byeTeams;

  const _RoundDisplayData({
    required this.round,
    required this.isGroupStage,
    required this.matches,
    required this.byeTeams,
  });

  bool get hasContent => matches.isNotEmpty || byeTeams.isNotEmpty;
}
