import 'package:flutter/material.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/theme/theme.dart';
import '../../models/tournament_status.dart';
import '../../controllers/tournaments_controller.dart';

/// Barra de busca e filtros oficial para a tela de Torneios do Modo Jogador (Modelo Canônico MembersFilterBar).
/// Linha 1: [AppSearchBar] em largura total com floating label ('Buscar torneios').
/// Linha 2: [AppSelectBox] de Fase do Torneio + [AppFilterClearButton].
class TournamentsFilterBar extends StatelessWidget {
  final TournamentsController controller;

  const TournamentsFilterBar({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasActiveFilters = controller.hasActiveFilters;
    final bool isPhaseActive = controller.selectedStatus != null;
    final int totalCount = controller.filteredTournaments.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 620;

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppSearchBar(
                      controller: controller.searchController,
                      labelText: 'Buscar torneios',
                      hintText:
                          'Digite o nome do campeonato, formato ou campeão...',
                      onSearch: controller.onSearchSubmitted,
                      isLoading: controller.isLoading,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppFilterClearButton(
                    hasActiveFilters: hasActiveFilters,
                    onClear: controller.clearFilters,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              AppSelectBox<TournamentStatus?>(
                value: controller.selectedStatus,
                placeholder: 'Todas as Fases',
                options: TournamentStatus.playerPhaseOptions,
                onChanged: controller.setStatusFilter,
                height: 46,
                width: double.infinity,
                accentColor: AppColors.primaryNeon,
                showSelectedIcon: true,
                isFiltered: isPhaseActive,
                isHighlighted: isPhaseActive,
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSearchBar(
              controller: controller.searchController,
              labelText: 'Buscar torneios',
              hintText: 'Digite o nome do campeonato, formato ou campeão...',
              onSearch: controller.onSearchSubmitted,
              isLoading: controller.isLoading,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 220,
                  child: AppSelectBox<TournamentStatus?>(
                    value: controller.selectedStatus,
                    placeholder: 'Todas as Fases',
                    options: TournamentStatus.playerPhaseOptions,
                    onChanged: controller.setStatusFilter,
                    height: 46,
                    accentColor: AppColors.primaryNeon,
                    showSelectedIcon: true,
                    isFiltered: isPhaseActive,
                    isHighlighted: isPhaseActive,
                  ),
                ),
                const SizedBox(width: 10),
                AppFilterClearButton(
                  hasActiveFilters: hasActiveFilters,
                  onClear: controller.clearFilters,
                ),
                const Spacer(),
                Text(
                  '$totalCount ${totalCount == 1 ? "campeonato" : "campeonatos"}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
