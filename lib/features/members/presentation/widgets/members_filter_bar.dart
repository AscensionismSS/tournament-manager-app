import 'package:flutter/material.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/theme/theme.dart';
import '../../controllers/members_controller.dart';

/// Barra responsiva de busca textual e filtros de Função e Rank do Dota 2
class MembersFilterBar extends StatelessWidget {
  final MembersController controller;

  const MembersFilterBar({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasActiveFilters = controller.hasActiveFilters;
    final bool isRoleActive = controller.selectedRole != null;
    final bool isRankActive = controller.selectedRankTier != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        final bool isMobile = availableWidth < 540;

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: AppSearchBar(
                      controller: controller.searchController,
                      labelText: 'Buscar membros',
                      hintText: 'Digite o Nickname, Nome, SteamID ou Friend ID',
                      onSearch: controller.onSearchChanged,
                      isLoading: controller.isLoading,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildClearButton(hasActiveFilters),
                ],
              ),
              const SizedBox(height: 10),
              AppSelectBox<String?>(
                value: controller.selectedRole,
                placeholder: 'Todas as Funções',
                options: DotaFilterOptions.roleOptions,
                onChanged: controller.setRoleFilter,
                accentColor: AppColors.primaryNeon,
                showSelectedIcon: true,
                height: 46,
                width: double.infinity,
                isFiltered: isRoleActive,
                isHighlighted: isRoleActive,
              ),
              const SizedBox(height: 8),
              AppSelectBox<int?>(
                value: controller.selectedRankTier,
                placeholder: 'Todos os Ranks',
                options: DotaFilterOptions.rankOptions,
                onChanged: controller.setRankTierFilter,
                accentColor: AppColors.primaryNeon,
                showSelectedIcon: true,
                height: 46,
                width: double.infinity,
                isFiltered: isRankActive,
                isHighlighted: isRankActive,
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSearchBar(
              controller: controller.searchController,
              labelText: 'Buscar membros',
              hintText: 'Digite o Nickname, Nome, SteamID ou Friend ID',
              onSearch: controller.onSearchChanged,
              isLoading: controller.isLoading,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: 210,
                  child: AppSelectBox<String?>(
                    value: controller.selectedRole,
                    placeholder: 'Todas as Funções',
                    options: DotaFilterOptions.roleOptions,
                    onChanged: controller.setRoleFilter,
                    accentColor: AppColors.primaryNeon,
                    showSelectedIcon: true,
                    height: 46,
                    isFiltered: isRoleActive,
                    isHighlighted: isRoleActive,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 210,
                  child: AppSelectBox<int?>(
                    value: controller.selectedRankTier,
                    placeholder: 'Todos os Ranks',
                    options: DotaFilterOptions.rankOptions,
                    onChanged: controller.setRankTierFilter,
                    accentColor: AppColors.primaryNeon,
                    showSelectedIcon: true,
                    height: 46,
                    isFiltered: isRankActive,
                    isHighlighted: isRankActive,
                  ),
                ),
                const SizedBox(width: 10),
                _buildClearButton(hasActiveFilters),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildClearButton(bool hasActiveFilters) {
    return Tooltip(
      message: hasActiveFilters ? 'Limpar todos os filtros' : 'Nenhum filtro ativo',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: hasActiveFilters ? controller.clearFilters : null,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: hasActiveFilters
                  ? AppColors.primary.withValues(alpha: 0.16)
                  : AppColors.surfaceHighlight.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasActiveFilters
                    ? AppColors.primaryNeon
                    : AppColors.border.withValues(alpha: 0.4),
                width: hasActiveFilters ? 1.4 : 1.0,
              ),
              boxShadow: hasActiveFilters
                  ? [
                      BoxShadow(
                        color: AppColors.primaryNeon.withValues(alpha: 0.25),
                        blurRadius: 10,
                        spreadRadius: 0.5,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Icon(
                Icons.filter_alt_off_rounded,
                size: 20,
                color: hasActiveFilters
                    ? AppColors.primaryNeon
                    : AppColors.textSecondary.withValues(alpha: 0.35),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
