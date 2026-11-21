import 'package:flutter/material.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/theme/theme.dart';
import '../../controllers/pro_matches_controller.dart';

/// Barra canônica de busca, filtros e atualização do Cenário Pro (Modelo MembersFilterBar).
/// Linha 1: [AppSearchBar] em largura total (46px).
/// Linha 2: [AppSelectBox] de Nível + [AppSelectBox] de Campeonato + [AppFilterClearButton]
///          alinhados à esquerda, e horário + [AppButton] (46px com trava cooldown) à direita.
class ProMatchesFilterBar extends StatelessWidget {
  final ProMatchesController controller;
  final VoidCallback onRefresh;

  const ProMatchesFilterBar({
    super.key,
    required this.controller,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = controller.hasActiveFilters;
    final isLevelActive = controller.activeFilter != ProMatchFilter.all;
    final isTournamentActive = controller.selectedLeagueName != null;
    final overview = controller.overview;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 760;

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppSearchBar(
                      controller: controller.searchController,
                      labelText: 'Buscar no Cenário Pro',
                      hintText: 'Digite o time, campeonato ou liga...',
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
              AppSelectBox<ProMatchFilter>(
                value: controller.activeFilter,
                placeholder: 'Todos os Níveis',
                options: ProMatchFilter.selectOptions,
                onChanged: controller.setFilter,
                height: 46,
                width: double.infinity,
                accentColor: AppColors.dotaGold,
                showSelectedIcon: true,
                isFiltered: isLevelActive,
                isHighlighted: isLevelActive,
              ),
              const SizedBox(height: 10),
              AppSelectBox<String?>(
                value: controller.selectedLeagueName,
                placeholder: 'Todos os Campeonatos',
                options: controller.tournamentFilterOptions,
                onChanged: controller.setLeagueFilter,
                height: 46,
                width: double.infinity,
                accentColor: AppColors.primaryNeon,
                showSelectedIcon: true,
                showSearch: true,
                isFiltered: isTournamentActive,
                isHighlighted: isTournamentActive,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (overview != null && overview.fetchedAtUtc != null)
                    Expanded(
                      child: _buildLastUpdated(overview.formattedFetchedAt),
                    )
                  else
                    const Spacer(),
                  const SizedBox(width: 10),
                  _buildRefreshButton(),
                ],
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Linha 1: Busca dedicada em largura total (46px)
            AppSearchBar(
              controller: controller.searchController,
              labelText: 'Buscar no Cenário Pro',
              hintText: 'Digite o nome do time, liga ou campeonato...',
              onSearch: controller.onSearchSubmitted,
              isLoading: controller.isLoading,
            ),
            const SizedBox(height: 12),

            // Linha 2: Filtros à esquerda + Última atualização e Botão Atualizar (46px) à direita
            Row(
              children: [
                SizedBox(
                  width: 215,
                  child: AppSelectBox<ProMatchFilter>(
                    value: controller.activeFilter,
                    placeholder: 'Todos os Níveis',
                    options: ProMatchFilter.selectOptions,
                    onChanged: controller.setFilter,
                    height: 46,
                    accentColor: AppColors.dotaGold,
                    showSelectedIcon: true,
                    isFiltered: isLevelActive,
                    isHighlighted: isLevelActive,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 240,
                  child: AppSelectBox<String?>(
                    value: controller.selectedLeagueName,
                    placeholder: 'Todos os Campeonatos',
                    options: controller.tournamentFilterOptions,
                    onChanged: controller.setLeagueFilter,
                    height: 46,
                    accentColor: AppColors.primaryNeon,
                    showSelectedIcon: true,
                    showSearch: true,
                    isFiltered: isTournamentActive,
                    isHighlighted: isTournamentActive,
                  ),
                ),
                const SizedBox(width: 10),
                AppFilterClearButton(
                  hasActiveFilters: hasActiveFilters,
                  onClear: controller.clearFilters,
                ),
                const Spacer(),
                if (overview != null && overview.fetchedAtUtc != null) ...[
                  _buildLastUpdated(overview.formattedFetchedAt),
                  const SizedBox(width: 14),
                ],
                _buildRefreshButton(),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildLastUpdated(String formattedDate) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.update_rounded,
          size: 14,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            'Atualizado: $formattedDate',
            style: const TextStyle(
              fontSize: 12,
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

  Widget _buildRefreshButton() {
    return Tooltip(
      message: controller.isOnCooldown
          ? 'Aguarde o intervalo para evitar excesso de requisições'
          : 'Buscar atualizações de partidas ao vivo',
      child: AppButton.outline(
        text: controller.refreshButtonLabel,
        icon: controller.isOnCooldown
            ? Icons.hourglass_bottom_rounded
            : Icons.refresh_rounded,
        size: AppButtonSize.medium,
        isLoading: controller.isRefreshing,
        onPressed: controller.canRefresh ? onRefresh : null,
      ),
    );
  }
}
