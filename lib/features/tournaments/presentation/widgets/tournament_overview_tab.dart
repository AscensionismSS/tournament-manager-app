import 'package:flutter/material.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/theme/theme.dart';
import '../../models/tournament_dto.dart';

/// Aba 1: Visão Geral do Campeonato (Focada exclusivamente nos dados oficiais
/// de estrutura, chaveamento, formato das séries e status da competição).
class TournamentOverviewTab extends StatelessWidget {
  final TournamentDto tournament;

  const TournamentOverviewTab({
    super.key,
    required this.tournament,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 760;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppSectionHeader(
          title: 'INFORMAÇÕES GERAIS DO CAMPEONATO',
          countLabel: 'Configuração Oficial',
        ),
        const SizedBox(height: 14),
        if (isMobile)
          Column(
            children: [
              _buildFormatCard(),
              const SizedBox(height: 12),
              _buildSeriesCard(),
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildFormatCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildSeriesCard()),
            ],
          ),
      ],
    );
  }

  Widget _buildFormatCard() {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.alt_route_rounded,
                  size: 18, color: AppColors.primaryNeon),
              SizedBox(width: 8),
              Text(
                'ESTRUTURA & CHAVEAMENTO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                  color: AppColors.dotaGoldLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildInfoRow('Formato do Torneio', tournament.formatLabel),
          const Divider(color: AppColors.border, height: 18),
          _buildInfoRow('Modelo dos Playoffs', tournament.playoffFormatLabel),
          const Divider(color: AppColors.border, height: 18),
          _buildInfoRow(
            'Fase de Grupos',
            tournament.hasGroupStage
                ? '${tournament.groupCount} ${tournament.groupCount == 1 ? "Grupo Único" : "Grupos"} (${tournament.teamsPerGroup} times por grupo)'
                : 'Não possui (Mata-Mata Direto)',
          ),
          const Divider(color: AppColors.border, height: 18),
          _buildInfoRow('Modalidade de Entrada', tournament.entryModeLabel),
        ],
      ),
    );
  }

  Widget _buildSeriesCard() {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.sports_esports_rounded,
                  size: 18, color: AppColors.dotaGold),
              SizedBox(width: 8),
              Text(
                'FORMATO DAS SÉRIES & STATUS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                  color: AppColors.dotaGoldLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildInfoRow(
            'Séries na Fase de Grupos',
            tournament.hasGroupStage
                ? '${tournament.groupStageMdLabel} (${tournament.groupStageSeriesFormat})'
                : 'Não se aplica',
          ),
          const Divider(color: AppColors.border, height: 18),
          _buildInfoRow(
            'Séries nos Playoffs',
            '${tournament.playoffMdLabel} (${tournament.playoffSeriesFormat})',
          ),
          const Divider(color: AppColors.border, height: 18),
          _buildInfoRow(
            'Grande Final',
            '${tournament.grandFinalMdLabel} (${tournament.grandFinalSeriesFormat})',
          ),
          const Divider(color: AppColors.border, height: 18),
          _buildInfoRow(
            'Status das Inscrições',
            '${tournament.registrationStatusLabel} (${tournament.slotsSummaryLabel})',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
