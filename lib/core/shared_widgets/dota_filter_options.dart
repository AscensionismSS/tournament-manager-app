import 'package:flutter/material.dart';
import '../theme/theme.dart';
import 'app_select_box.dart';
import 'dota_rank_medal.dart';
import 'dota_role_icons.dart';

/// Centralizador oficial de opções e helpers de filtro para Dota 2 (DRY - Shared).
///
/// Reutilizável em qualquer tela da arena (Membros, Torneios, Draft, Partidas).
/// Padroniza os ícones de 3 riscos (tune/filter) no estado geral e os vetores
/// oficiais do Dota 2 quando uma opção específica for selecionada.
class DotaFilterOptions {
  DotaFilterOptions._();

  /// Opções padronizadas de Função / Posição Dota 2
  static final List<AppSelectOption<String?>> roleOptions = [
    const AppSelectOption(
      value: null,
      label: 'Todas as Funções',
      iconWidget: Icon(
        Icons.tune_rounded,
        size: 17,
        color: AppColors.primaryNeon,
      ),
    ),
    const AppSelectOption(
      value: 'Pos 1',
      label: 'Pos 1 - Hard Carry',
      iconWidget: DotaRoleIcon(
        role: DotaRoleType.safeLane,
        size: 18,
        color: AppColors.feedbackError,
      ),
    ),
    const AppSelectOption(
      value: 'Pos 2',
      label: 'Pos 2 - Mid Laner',
      iconWidget: DotaRoleIcon(
        role: DotaRoleType.midLane,
        size: 18,
        color: AppColors.dotaGold,
      ),
    ),
    const AppSelectOption(
      value: 'Pos 3',
      label: 'Pos 3 - Offlaner',
      iconWidget: DotaRoleIcon(
        role: DotaRoleType.offLane,
        size: 18,
        color: AppColors.feedbackSuccess,
      ),
    ),
    const AppSelectOption(
      value: 'Pos 4',
      label: 'Pos 4 - Soft Support',
      iconWidget: DotaRoleIcon(
        role: DotaRoleType.support,
        size: 18,
        color: AppColors.feedbackInfo,
      ),
    ),
    const AppSelectOption(
      value: 'Pos 5',
      label: 'Pos 5 - Hard Support',
      iconWidget: DotaRoleIcon(
        role: DotaRoleType.hardSupport,
        size: 18,
        color: AppColors.dotaRoleHardSupport,
      ),
    ),
  ];

  /// Opções padronizadas de Rank / Patente Dota 2
  static final List<AppSelectOption<int?>> rankOptions = [
    const AppSelectOption(
      value: null,
      label: 'Todos os Ranks',
      iconWidget: Icon(
        Icons.tune_rounded,
        size: 17,
        color: AppColors.primaryNeon,
      ),
    ),
    const AppSelectOption(
      value: 8,
      label: 'Imortal',
      iconWidget: DotaRankMedal(
        rankTier: '8',
        size: 22,
        showBadgeNumber: false,
      ),
    ),
    const AppSelectOption(
      value: 7,
      label: 'Divino',
      iconWidget: DotaRankMedal(
        rankTier: '7',
        size: 22,
        showBadgeNumber: false,
      ),
    ),
    const AppSelectOption(
      value: 6,
      label: 'Ancestral',
      iconWidget: DotaRankMedal(
        rankTier: '6',
        size: 22,
        showBadgeNumber: false,
      ),
    ),
    const AppSelectOption(
      value: 5,
      label: 'Lenda',
      iconWidget: DotaRankMedal(
        rankTier: '5',
        size: 22,
        showBadgeNumber: false,
      ),
    ),
    const AppSelectOption(
      value: 4,
      label: 'Arconte',
      iconWidget: DotaRankMedal(
        rankTier: '4',
        size: 22,
        showBadgeNumber: false,
      ),
    ),
    const AppSelectOption(
      value: 3,
      label: 'Cruzado',
      iconWidget: DotaRankMedal(
        rankTier: '3',
        size: 22,
        showBadgeNumber: false,
      ),
    ),
    const AppSelectOption(
      value: 2,
      label: 'Guardião',
      iconWidget: DotaRankMedal(
        rankTier: '2',
        size: 22,
        showBadgeNumber: false,
      ),
    ),
    const AppSelectOption(
      value: 1,
      label: 'Heraldo',
      iconWidget: DotaRankMedal(
        rankTier: '1',
        size: 22,
        showBadgeNumber: false,
      ),
    ),
    const AppSelectOption(
      value: 0,
      label: 'Sem Rank',
      iconWidget: DotaRankMedal(
        rankTier: '0',
        size: 22,
        showBadgeNumber: false,
      ),
    ),
  ];
}
