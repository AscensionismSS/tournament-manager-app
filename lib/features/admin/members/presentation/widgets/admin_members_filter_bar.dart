import 'package:flutter/material.dart';
import '../../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../../core/theme/theme.dart';
import '../../controllers/admin_members_controller.dart';

/// Barra de filtros oficial para Gestão de Membros (Modelo canônico MembersFilterBar).
/// Linha 1: [AppSearchBar] de ponta a ponta com floating label.
/// Linha 2: Controles [AppSelectBox] (210px) alinhados com altura padronizada de 46px
/// e botão quadrado de 46x46 de limpar filtros sem layout shift.
class AdminMembersFilterBar extends StatelessWidget {
  final AdminMembersController controller;

  const AdminMembersFilterBar({
    super.key,
    required this.controller,
  });

  static const List<AppSelectOption<String?>> roleOptions = [
    AppSelectOption(
      value: null,
      label: 'Todos os Cargos',
      iconWidget: Icon(
        Icons.tune_rounded,
        size: 17,
        color: AppColors.primaryNeon,
      ),
    ),
    AppSelectOption(
      value: 'SuperAdmin',
      label: 'SuperAdmin',
      iconWidget: Icon(
        Icons.shield_rounded,
        size: 17,
        color: AppColors.dotaGold,
      ),
    ),
    AppSelectOption(
      value: 'Admin',
      label: 'Admin',
      iconWidget: Icon(
        Icons.admin_panel_settings_rounded,
        size: 17,
        color: AppColors.dotaGoldLight,
      ),
    ),
    AppSelectOption(
      value: 'User',
      label: 'Jogador / User',
      iconWidget: Icon(
        Icons.person_rounded,
        size: 17,
        color: AppColors.textSecondary,
      ),
    ),
  ];

  static const List<AppSelectOption<bool?>> steamOptions = [
    AppSelectOption(
      value: null,
      label: 'Todas as Contas Steam',
      iconWidget: Icon(
        Icons.tune_rounded,
        size: 17,
        color: AppColors.primaryNeon,
      ),
    ),
    AppSelectOption(
      value: true,
      label: 'Com Steam Vinculada',
      iconWidget: Icon(
        Icons.link_rounded,
        size: 17,
        color: AppColors.dotaGoldLight,
      ),
    ),
    AppSelectOption(
      value: false,
      label: 'Sem Steam Vinculada',
      iconWidget: Icon(
        Icons.link_off_rounded,
        size: 17,
        color: AppColors.textSecondary,
      ),
    ),
  ];

  static const List<AppSelectOption<bool?>> activeOptions = [
    AppSelectOption(
      value: null,
      label: 'Todos os Status de Login',
      iconWidget: Icon(
        Icons.tune_rounded,
        size: 17,
        color: AppColors.primaryNeon,
      ),
    ),
    AppSelectOption(
      value: true,
      label: 'Ativos (Liberados)',
      iconWidget: Icon(
        Icons.check_circle_outline_rounded,
        size: 17,
        color: AppColors.feedbackSuccess,
      ),
    ),
    AppSelectOption(
      value: false,
      label: 'Desativados (Bloqueados)',
      iconWidget: Icon(
        Icons.block_rounded,
        size: 17,
        color: AppColors.feedbackError,
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bool hasActive = controller.hasActiveMemberFilters;
    final bool isRoleActive = controller.selectedRole != null;
    final bool isSteamActive = controller.selectedHasSteam != null;
    final bool isActiveFilterActive = controller.selectedIsActive != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final bool isMobile = width < 720;

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Linha 1 Mobile: Busca dedicada + Botão de Limpeza canônico 46x46
              Row(
                children: [
                  Expanded(
                    child: AppSearchBar(
                      controller: controller.searchController,
                      labelText: 'Buscar membros',
                      hintText: 'Digite o nickname, e-mail ou SteamID...',
                      onSearch: controller.onSearchChanged,
                      isLoading: controller.isLoadingMembers,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildClearButton(hasActive),
                ],
              ),
              const SizedBox(height: 10),
              // Linha 2 Mobile: Seletores de filtro empilhados
              AppSelectBox<String?>(
                value: controller.selectedRole,
                placeholder: 'Todos os Cargos',
                options: roleOptions,
                onChanged: controller.setRoleFilter,
                height: 46,
                width: double.infinity,
                accentColor: AppColors.primaryNeon,
                showSelectedIcon: true,
                isFiltered: isRoleActive,
                isHighlighted: isRoleActive,
              ),
              const SizedBox(height: 8),
              AppSelectBox<bool?>(
                value: controller.selectedHasSteam,
                placeholder: 'Todas as Contas Steam',
                options: steamOptions,
                onChanged: controller.setHasSteamFilter,
                height: 46,
                width: double.infinity,
                accentColor: AppColors.primaryNeon,
                showSelectedIcon: true,
                isFiltered: isSteamActive,
                isHighlighted: isSteamActive,
              ),
              const SizedBox(height: 8),
              AppSelectBox<bool?>(
                value: controller.selectedIsActive,
                placeholder: 'Todos os Status de Login',
                options: activeOptions,
                onChanged: controller.setIsActiveFilter,
                height: 46,
                width: double.infinity,
                accentColor: AppColors.primaryNeon,
                showSelectedIcon: true,
                isFiltered: isActiveFilterActive,
                isHighlighted: isActiveFilterActive,
              ),
            ],
          );
        }

        // Layout Desktop / Tablet (Modelo Canônico MembersFilterBar)
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Linha 1: Busca Dedicada com Floating Label em largura total
            AppSearchBar(
              controller: controller.searchController,
              labelText: 'Buscar membros',
              hintText: 'Digite o nickname, e-mail ou SteamID...',
              onSearch: controller.onSearchChanged,
              isLoading: controller.isLoadingMembers,
            ),
            const SizedBox(height: 12),
            // Linha 2: Filtros padronizados a 210px + Botão de Limpeza em 46px + Contador à direita
            Row(
              children: [
                SizedBox(
                  width: 210,
                  child: AppSelectBox<String?>(
                    value: controller.selectedRole,
                    placeholder: 'Todos os Cargos',
                    options: roleOptions,
                    onChanged: controller.setRoleFilter,
                    height: 46,
                    accentColor: AppColors.primaryNeon,
                    showSelectedIcon: true,
                    isFiltered: isRoleActive,
                    isHighlighted: isRoleActive,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 210,
                  child: AppSelectBox<bool?>(
                    value: controller.selectedHasSteam,
                    placeholder: 'Todas as Contas Steam',
                    options: steamOptions,
                    onChanged: controller.setHasSteamFilter,
                    height: 46,
                    accentColor: AppColors.primaryNeon,
                    showSelectedIcon: true,
                    isFiltered: isSteamActive,
                    isHighlighted: isSteamActive,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 210,
                  child: AppSelectBox<bool?>(
                    value: controller.selectedIsActive,
                    placeholder: 'Todos os Status de Login',
                    options: activeOptions,
                    onChanged: controller.setIsActiveFilter,
                    height: 46,
                    accentColor: AppColors.primaryNeon,
                    showSelectedIcon: true,
                    isFiltered: isActiveFilterActive,
                    isHighlighted: isActiveFilterActive,
                  ),
                ),
                const SizedBox(width: 10),
                _buildClearButton(hasActive),
                const Spacer(),
                // Indicador de contagem rápida
                Text(
                  '${controller.members.length} ${controller.members.length == 1 ? "membro" : "membros"}',
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

  /// Botão quadrado oficial de 46x46 com animação neon e zero layout shift
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
