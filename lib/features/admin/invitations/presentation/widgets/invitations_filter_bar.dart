import 'package:flutter/material.dart';
import '../../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../../core/theme/theme.dart';
import '../../controllers/invitations_controller.dart';

/// Barra de busca e filtros oficial da gestão de convites (SRP).
/// Segue fielmente a mesma arquitetura e padrão canônico de [MembersFilterBar]:
/// - Linha 1: [AppSearchBar] em largura total com floating label ('Buscar convites') e debounce integrado.
/// - Linha 2: [AppSelectBox] de 210px com ícone [Icons.tune_rounded] neon, botão de limpar filtros
///   SEMPRE presente (com estado desabilitado/ativo sem layout shift) e botão de ação primária à direita.
class InvitationsFilterBar extends StatelessWidget {
  final InvitationsController controller;
  final VoidCallback onNewInvite;

  const InvitationsFilterBar({
    super.key,
    required this.controller,
    required this.onNewInvite,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasActiveFilters = controller.hasActiveFilters;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final bool isMobile = width < 540;

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
                      labelText: 'Buscar convites',
                      hintText: 'Digite o e-mail, código ou papel...',
                      onSearch: (_) {},
                      isLoading: controller.isLoading,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildClearButton(hasActiveFilters),
                ],
              ),
              const SizedBox(height: 10),
              AppSelectBox<InvitationFilterTab>(
                value: controller.currentTab,
                placeholder: 'Todos os Status',
                options: _buildOptions(controller),
                onChanged: (tab) => controller.setFilterTab(tab ?? InvitationFilterTab.all),
                accentColor: AppColors.primaryNeon,
                showSelectedIcon: true,
                height: 46,
                width: double.infinity,
                isFiltered: controller.currentTab != InvitationFilterTab.all,
                isHighlighted: controller.currentTab != InvitationFilterTab.all,
              ),
              const SizedBox(height: 10),
              AppButton(
                text: 'NOVO CONVITE',
                size: AppButtonSize.medium,
                isFullWidth: true,
                onPressed: onNewInvite,
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Linha 1: Barra de busca completa com floating label
            AppSearchBar(
              controller: controller.searchController,
              labelText: 'Buscar convites',
              hintText: 'Digite o e-mail, código ou papel...',
              onSearch: (_) {},
              isLoading: controller.isLoading,
            ),
            const SizedBox(height: 12),

            // Linha 2: Seletor de Status (210px) + Botão de Limpar SEMPRE presente | Botão de Ação à direita
            Row(
              children: [
                SizedBox(
                  width: 210,
                  child: AppSelectBox<InvitationFilterTab>(
                    value: controller.currentTab,
                    placeholder: 'Todos os Status',
                    options: _buildOptions(controller),
                    onChanged: (tab) => controller.setFilterTab(tab ?? InvitationFilterTab.all),
                    accentColor: AppColors.primaryNeon,
                    showSelectedIcon: true,
                    height: 46,
                    isFiltered: controller.currentTab != InvitationFilterTab.all,
                    isHighlighted: controller.currentTab != InvitationFilterTab.all,
                  ),
                ),
                const SizedBox(width: 10),
                _buildClearButton(hasActiveFilters),
                const Spacer(),
                AppButton(
                  text: 'NOVO CONVITE',
                  size: AppButtonSize.medium,
                  onPressed: onNewInvite,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  List<AppSelectOption<InvitationFilterTab>> _buildOptions(InvitationsController controller) {
    return [
      AppSelectOption<InvitationFilterTab>(
        value: InvitationFilterTab.all,
        label: 'Todos os Status (${controller.totalCount})',
        iconWidget: const Icon(
          Icons.tune_rounded,
          size: 17,
          color: AppColors.primaryNeon,
        ),
      ),
      AppSelectOption<InvitationFilterTab>(
        value: InvitationFilterTab.active,
        label: 'Pendentes (${controller.activeCount})',
        iconWidget: const Icon(
          Icons.hourglass_top_rounded,
          size: 17,
          color: AppColors.dotaGold,
        ),
      ),
      AppSelectOption<InvitationFilterTab>(
        value: InvitationFilterTab.used,
        label: 'Usados (${controller.usedCount})',
        iconWidget: const Icon(
          Icons.done_all_rounded,
          size: 17,
          color: AppColors.steamBlue,
        ),
      ),
      AppSelectOption<InvitationFilterTab>(
        value: InvitationFilterTab.revoked,
        label: 'Revogados (${controller.revokedCount})',
        iconWidget: const Icon(
          Icons.cancel_outlined,
          size: 17,
          color: AppColors.feedbackError,
        ),
      ),
      AppSelectOption<InvitationFilterTab>(
        value: InvitationFilterTab.expired,
        label: 'Expirados (${controller.expiredCount})',
        iconWidget: const Icon(
          Icons.schedule_rounded,
          size: 17,
          color: AppColors.dotaGold,
        ),
      ),
    ];
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
