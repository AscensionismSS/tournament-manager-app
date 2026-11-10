import 'package:flutter/material.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/theme/theme.dart';
import '../../models/tournament_team_dto.dart';

/// Barra de filtros oficial para o Calendário de Partidas e Séries.
/// Linha única com controles para:
/// 1. Rodada ([selectedRound])
/// 2. Equipe / Time ([selectedTeamId])
/// 3. Status da Série ([selectedStatus] - 'pending', 'ongoing', 'completed')
/// 4. Botão de limpeza de filtros ([AppFilterClearButton])
class TournamentMatchesFilterBar extends StatelessWidget {
  final int? selectedRound;
  final List<int> availableRounds;
  final ValueChanged<int?> onRoundChanged;

  final String? selectedTeamId;
  final List<TournamentTeamDto> availableTeams;
  final ValueChanged<String?> onTeamChanged;

  final String? selectedStatus;
  final ValueChanged<String?> onStatusChanged;

  final VoidCallback onClearFilters;
  final bool hasActiveFilters;

  const TournamentMatchesFilterBar({
    super.key,
    required this.selectedRound,
    required this.availableRounds,
    required this.onRoundChanged,
    required this.selectedTeamId,
    required this.availableTeams,
    required this.onTeamChanged,
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.onClearFilters,
    required this.hasActiveFilters,
  });

  @override
  Widget build(BuildContext context) {
    // Opções de Rodadas
    final roundOptions = [
      const AppSelectOption<int?>(
        value: null,
        label: 'Todas as Rodadas',
        iconWidget:
            Icon(Icons.tune_rounded, size: 17, color: AppColors.primaryNeon),
      ),
      ...availableRounds.map(
        (r) => AppSelectOption<int?>(
          value: r,
          label: 'Rodada $r',
          iconWidget: const Icon(Icons.calendar_month_rounded,
              size: 17, color: AppColors.dotaGold),
        ),
      ),
    ];

    // Opções de Times
    final teamOptions = [
      const AppSelectOption<String?>(
        value: null,
        label: 'Todos os Times',
        iconWidget:
            Icon(Icons.tune_rounded, size: 17, color: AppColors.primaryNeon),
      ),
      ...availableTeams.map(
        (t) => AppSelectOption<String?>(
          value: t.id,
          label: t.name,
          iconWidget: const Icon(Icons.shield_rounded,
              size: 17, color: AppColors.dotaGold),
        ),
      ),
    ];

    // Opções dos 3 Status
    const statusOptions = [
      AppSelectOption<String?>(
        value: null,
        label: 'Todos os Status',
        iconWidget:
            Icon(Icons.tune_rounded, size: 17, color: AppColors.primaryNeon),
      ),
      AppSelectOption<String?>(
        value: 'pending',
        label: 'A Definir',
        iconWidget:
            Icon(Icons.schedule_rounded, size: 17, color: AppColors.dotaGold),
      ),
      AppSelectOption<String?>(
        value: 'ongoing',
        label: 'Em Andamento',
        iconWidget: Icon(Icons.play_circle_fill_rounded,
            size: 17, color: AppColors.primaryNeon),
      ),
      AppSelectOption<String?>(
        value: 'completed',
        label: 'Finalizado',
        iconWidget: Icon(Icons.check_circle_rounded,
            size: 17, color: AppColors.feedbackSuccess),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 780;

        final roundBox = AppSelectBox<int?>(
          value: selectedRound,
          placeholder: 'Todas as Rodadas',
          options: roundOptions,
          onChanged: onRoundChanged,
          height: 46,
          accentColor: AppColors.primaryNeon,
          isFiltered: selectedRound != null,
          isHighlighted: selectedRound != null,
          showSelectedIcon: true,
        );

        final teamBox = AppSelectBox<String?>(
          value: selectedTeamId,
          placeholder: 'Todos os Times',
          options: teamOptions,
          onChanged: onTeamChanged,
          height: 46,
          accentColor: AppColors.primaryNeon,
          isFiltered: selectedTeamId != null,
          isHighlighted: selectedTeamId != null,
          showSearch: availableTeams.length > 4,
          showSelectedIcon: true,
        );

        final statusBox = AppSelectBox<String?>(
          value: selectedStatus,
          placeholder: 'Todos os Status',
          options: statusOptions,
          onChanged: onStatusChanged,
          height: 46,
          accentColor: AppColors.primaryNeon,
          isFiltered: selectedStatus != null,
          isHighlighted: selectedStatus != null,
          showSelectedIcon: true,
        );

        final clearButton = AppFilterClearButton(
          hasActiveFilters: hasActiveFilters,
          onClear: onClearFilters,
        );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: roundBox),
                  const SizedBox(width: 8),
                  Expanded(child: statusBox),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: teamBox),
                  const SizedBox(width: 8),
                  clearButton,
                ],
              ),
            ],
          );
        }

        // Layout Desktop: Linha única harmônica de 46px com 220px de largura para não cortar textos
        return Row(
          children: [
            SizedBox(width: 220, child: roundBox),
            const SizedBox(width: 10),
            SizedBox(width: 230, child: teamBox),
            const SizedBox(width: 10),
            SizedBox(width: 220, child: statusBox),
            const SizedBox(width: 10),
            clearButton,
          ],
        );
      },
    );
  }
}
