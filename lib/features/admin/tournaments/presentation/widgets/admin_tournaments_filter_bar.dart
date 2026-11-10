import 'package:flutter/material.dart';
import '../../../../../core/models/system_security_settings.dart';
import '../../../../../core/services/system_security_service.dart';
import '../../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../tournaments/models/tournament_status.dart';
import '../../controllers/admin_tournaments_controller.dart';

/// Barra canônica de busca e filtros para Gestão de Torneios (Modelo MembersFilterBar).
/// Linha 1: [AppSearchBar] em largura total com floating label ('Buscar torneios').
/// Linha 2: [AppSelectBox] de Inscrição + [AppSelectBox] de Status + [AppFilterClearButton] + Botão Primário.
class AdminTournamentsFilterBar extends StatelessWidget {
  final AdminTournamentsController controller;
  final VoidCallback onNewTournament;

  const AdminTournamentsFilterBar({
    super.key,
    required this.controller,
    required this.onNewTournament,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasActiveFilters = controller.hasActiveFilters;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 580;

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
                      labelText: 'Buscar torneios',
                      hintText: 'Digite o nome do campeonato...',
                      onSearch: (_) {},
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
              AppSelectBox<bool?>(
                value: controller.selectedRegistrationOpen,
                placeholder: 'Todas as Inscrições',
                options: TournamentStatus.registrationFilterOptions,
                onChanged: controller.setRegistrationFilter,
                accentColor: AppColors.primaryNeon,
                showSelectedIcon: true,
                height: 46,
                width: double.infinity,
                isFiltered: controller.selectedRegistrationOpen != null,
                isHighlighted: controller.selectedRegistrationOpen != null,
              ),
              const SizedBox(height: 8),
              AppSelectBox<TournamentStatus?>(
                value: controller.selectedStatus,
                placeholder: 'Todos os Status',
                options: TournamentStatus.adminStatusOptions,
                onChanged: controller.setStatusFilter,
                accentColor: AppColors.primaryNeon,
                showSelectedIcon: true,
                height: 46,
                width: double.infinity,
                isFiltered: controller.selectedStatus != null,
                isHighlighted: controller.selectedStatus != null,
              ),
              const SizedBox(height: 10),
              ValueListenableBuilder<SystemSecuritySettings>(
                valueListenable: SystemSecurityService.instance.settingsNotifier,
                builder: (context, security, _) {
                  final isLocked = security.isTournamentCreationLocked;
                  return AppButton(
                    text: isLocked ? 'CRIAÇÃO TRAVADA' : 'NOVO TORNEIO',
                    icon: isLocked ? Icons.lock_outline_rounded : Icons.add_rounded,
                    size: AppButtonSize.medium,
                    isFullWidth: true,
                    onPressed: isLocked ? null : onNewTournament,
                  );
                },
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSearchBar(
              controller: controller.searchController,
              labelText: 'Buscar torneios',
              hintText: 'Digite o nome do campeonato ou formato...',
              onSearch: (_) {},
              isLoading: controller.isLoading,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 215,
                  child: AppSelectBox<bool?>(
                    value: controller.selectedRegistrationOpen,
                    placeholder: 'Todas as Inscrições',
                    options: TournamentStatus.registrationFilterOptions,
                    onChanged: controller.setRegistrationFilter,
                    accentColor: AppColors.primaryNeon,
                    showSelectedIcon: true,
                    height: 46,
                    isFiltered: controller.selectedRegistrationOpen != null,
                    isHighlighted: controller.selectedRegistrationOpen != null,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 215,
                  child: AppSelectBox<TournamentStatus?>(
                    value: controller.selectedStatus,
                    placeholder: 'Todos os Status',
                    options: TournamentStatus.adminStatusOptions,
                    onChanged: controller.setStatusFilter,
                    accentColor: AppColors.primaryNeon,
                    showSelectedIcon: true,
                    height: 46,
                    isFiltered: controller.selectedStatus != null,
                    isHighlighted: controller.selectedStatus != null,
                  ),
                ),
                const SizedBox(width: 10),
                AppFilterClearButton(
                  hasActiveFilters: hasActiveFilters,
                  onClear: controller.clearFilters,
                ),
                const Spacer(),
                ValueListenableBuilder<SystemSecuritySettings>(
                  valueListenable: SystemSecurityService.instance.settingsNotifier,
                  builder: (context, security, _) {
                    final isLocked = security.isTournamentCreationLocked;
                    return AppButton(
                      text: isLocked ? 'CRIAÇÃO TRAVADA' : 'NOVO TORNEIO',
                      icon: isLocked ? Icons.lock_outline_rounded : Icons.add_rounded,
                      size: AppButtonSize.medium,
                      onPressed: isLocked ? null : onNewTournament,
                    );
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
