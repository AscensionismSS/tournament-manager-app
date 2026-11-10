import 'package:flutter/material.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/theme/theme.dart';
import '../../models/tournament_dto.dart';
import '../../controllers/tournament_details_controller.dart';
import '../../models/tournament_standings_dto.dart';
import 'tournament_rules_button.dart';

/// Aba 3: Fase de Grupos Dinâmica (100% Dumb UI).
/// Renderiza automaticamente 1 ou 2 tabelas de grupo conforme `tournament.groupCount`.
/// Design minimalista, profissional e esportivo integrado ao padrão visual do sistema.
class TournamentGroupStageTab extends StatelessWidget {
  final TournamentDto tournament;
  final List<TournamentGroupTableData> groupTables;

  const TournamentGroupStageTab({
    super.key,
    required this.tournament,
    required this.groupTables,
  });

  @override
  Widget build(BuildContext context) {
    if (groupTables.isEmpty) {
      final availableHeight =
          (MediaQuery.sizeOf(context).height - 420).clamp(320.0, 720.0);
      return AppEmptyState(
        icon: Icons.table_chart_rounded,
        title: 'FASE DE GRUPOS NÃO INICIADA',
        message:
            'A tabela e a classificação serão calculadas assim que as partidas desta fase forem disputadas.',
        minHeight: availableHeight,
      );
    }

    final isMobile = MediaQuery.sizeOf(context).width < 550;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tabelas Dinâmicas por Grupo (Grupo Único ou Grupo A + Grupo B)
        ...groupTables.map((group) {
          final displayTitle = isMobile && group.title.contains('—')
              ? group.title.split('—').first.trim()
              : group.title;

          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSectionHeader(
                  title: displayTitle,
                  countLabel: 'Séries ${tournament.groupStageMdLabel}',
                  trailing: TournamentRulesButton(
                    tournament: tournament,
                    label: 'REGRAS & VAGAS',
                    tooltipMessage:
                        'Regras de Classificação & Vagas dos Playoffs',
                  ),
                ),
                const SizedBox(height: 12),
                _buildStandingsTable(context, group),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStandingsTable(
    BuildContext context,
    TournamentGroupTableData group,
  ) {
    final destinations = group.rows
        .map(
          (r) => GroupSeedDestination.resolveFromSlots(
            rankInGroup: r.rank,
            groupCount: tournament.groupCount,
            bracketSlots: tournament.bracketSlots,
          ),
        )
        .toList();

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Cabeçalho da Tabela
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceHighlight.withValues(alpha: 0.7),
              border: const Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: const Row(
              children: [
                SizedBox(width: 76, child: _HeaderCell('#')),
                Expanded(child: _HeaderCell('EQUIPE')),
                SizedBox(
                    width: 60, child: _HeaderCell('PTS', alignRight: true)),
                SizedBox(width: 48, child: _HeaderCell('J', alignRight: true)),
                SizedBox(
                    width: 74, child: _HeaderCell('V-E-D', alignRight: true)),
                SizedBox(
                    width: 72, child: _HeaderCell('MAPAS', alignRight: true)),
                SizedBox(
                    width: 62, child: _HeaderCell('SALDO', alignRight: true)),
              ],
            ),
          ),

          // Linhas da Tabela
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: group.rows.length,
            separatorBuilder: (_, __) => Divider(
                color: AppColors.border.withValues(alpha: 0.6), height: 1),
            itemBuilder: (context, index) {
              final row = group.rows[index];
              final destination = destinations[index];
              return _buildStandingRow(context, row, destination);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStandingRow(
    BuildContext context,
    TeamStandingDto row,
    GroupSeedDestination dest,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: dest.color, width: 3.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          // Posição (#) com tag da Chave integrada (ex: 1º UB, 5º LB, 6º PI) + Tooltip explicativo
          Tooltip(
            message: dest.detailHint,
            child: SizedBox(
              width: 76,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${row.rank}º',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: dest.color,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: dest.color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: dest.color.withValues(alpha: 0.5),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      dest.codeTag,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: dest.color,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Nome da Equipe (limpo, sem ícones/escudos intrusivos)
          Expanded(
            child: Text(
              row.teamName,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight:
                    row.isPlaceholder ? FontWeight.w600 : FontWeight.w800,
                color: row.isPlaceholder
                    ? AppColors.textSecondary
                    : Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Pontos
          SizedBox(
            width: 60,
            child: Text(
              '${row.points}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppColors.dotaGoldLight,
              ),
            ),
          ),

          // Jogos Disputados
          SizedBox(
            width: 48,
            child: Text(
              '${row.playedMatches}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12.5, color: Colors.white),
            ),
          ),

          // V-E-D
          SizedBox(
            width: 74,
            child: Text(
              row.recordSummary,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),

          // Mapas (W-L)
          SizedBox(
            width: 72,
            child: Text(
              row.mapsSummary,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ),

          // Saldo de Mapas
          SizedBox(
            width: 62,
            child: Text(
              row.mapDiffLabel,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: row.mapDifferential > 0
                    ? AppColors.feedbackSuccess
                    : (row.mapDifferential < 0
                        ? AppColors.feedbackError
                        : AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final bool alignRight;

  const _HeaderCell(this.text, {this.alignRight = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: const TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.7,
        color: AppColors.textSecondary,
      ),
    );
  }
}
