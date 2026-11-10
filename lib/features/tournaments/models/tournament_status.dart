import 'package:flutter/material.dart';
import '../../../core/shared_widgets/app_select_box.dart';
import '../../../core/theme/theme.dart';

/// Status do ciclo de vida de um torneio (Domain/Enums/TournamentStatus) e opções compartilhadas de filtro.
enum TournamentStatus {
  draft(1, 'Draft', 'Rascunho', Icons.edit_note_rounded),
  registrationOpen(2, 'RegistrationOpen', 'Inscrições Abertas', Icons.how_to_reg_rounded),
  drafting(3, 'Drafting', 'Draft de Times', Icons.shuffle_rounded),
  groupStage(4, 'GroupStage', 'Fase de Grupos', Icons.grid_view_rounded),
  playoffs(5, 'Playoffs', 'Playoffs & Finais', Icons.emoji_events_rounded),
  completed(6, 'Completed', 'Concluído', Icons.check_circle_rounded),
  canceled(7, 'Canceled', 'Cancelado', Icons.cancel_rounded);

  final int value;
  final String code;
  final String label;
  final IconData icon;

  const TournamentStatus(this.value, this.code, this.label, this.icon);

  Color get color {
    switch (this) {
      case TournamentStatus.draft:
        return AppColors.textSecondary;
      case TournamentStatus.registrationOpen:
        return AppColors.dotaGold;
      case TournamentStatus.drafting:
        return AppColors.primaryNeon;
      case TournamentStatus.groupStage:
        return AppColors.dotaGoldLight;
      case TournamentStatus.playoffs:
        return AppColors.primaryNeon;
      case TournamentStatus.completed:
        return AppColors.success;
      case TournamentStatus.canceled:
        return AppColors.error;
    }
  }

  static TournamentStatus fromValue(dynamic val) {
    if (val == null) return TournamentStatus.draft;
    if (val is int) {
      return TournamentStatus.values.firstWhere(
        (s) => s.value == val,
        orElse: () => TournamentStatus.draft,
      );
    }
    final str = val.toString().trim().toLowerCase();
    return TournamentStatus.values.firstWhere(
      (s) => s.code.toLowerCase() == str || s.name.toLowerCase() == str,
      orElse: () => TournamentStatus.draft,
    );
  }

  /// Opções padronizadas de Filtro de Inscrição (Aberta vs Fechada)
  static const List<AppSelectOption<bool?>> registrationFilterOptions = [
    AppSelectOption(
      value: null,
      label: 'Todas as Inscrições',
      iconWidget: Icon(Icons.tune_rounded, size: 17, color: AppColors.primaryNeon),
    ),
    AppSelectOption(
      value: true,
      label: 'Inscrições Abertas',
      iconWidget: Icon(Icons.how_to_reg_rounded, size: 17, color: AppColors.dotaGold),
    ),
    AppSelectOption(
      value: false,
      label: 'Inscrições Fechadas',
      iconWidget: Icon(Icons.lock_outline_rounded, size: 17, color: AppColors.textSecondary),
    ),
  ];

  /// Opções padronizadas de Filtro de Fase para o Modo Jogador
  static const List<AppSelectOption<TournamentStatus?>> playerPhaseOptions = [
    AppSelectOption(
      value: null,
      label: 'Todas as Fases',
      iconWidget: Icon(Icons.tune_rounded, size: 17, color: AppColors.primaryNeon),
    ),
    AppSelectOption(
      value: TournamentStatus.registrationOpen,
      label: 'Fase de Inscrição',
      iconWidget: Icon(Icons.how_to_reg_rounded, size: 17, color: AppColors.dotaGold),
    ),
    AppSelectOption(
      value: TournamentStatus.drafting,
      label: 'Draft de Times',
      iconWidget: Icon(Icons.shuffle_rounded, size: 17, color: AppColors.primaryNeon),
    ),
    AppSelectOption(
      value: TournamentStatus.groupStage,
      label: 'Fase de Grupos',
      iconWidget: Icon(Icons.grid_view_rounded, size: 17, color: AppColors.dotaGoldLight),
    ),
    AppSelectOption(
      value: TournamentStatus.playoffs,
      label: 'Playoffs & Finais',
      iconWidget: Icon(Icons.emoji_events_rounded, size: 17, color: AppColors.primaryNeon),
    ),
    AppSelectOption(
      value: TournamentStatus.completed,
      label: 'Concluídos',
      iconWidget: Icon(Icons.check_circle_rounded, size: 17, color: AppColors.success),
    ),
  ];

  /// Opções padronizadas de Filtro de Status para o Painel Admin
  static const List<AppSelectOption<TournamentStatus?>> adminStatusOptions = [
    ...playerPhaseOptions,
    AppSelectOption(
      value: TournamentStatus.draft,
      label: 'Rascunhos',
      iconWidget: Icon(Icons.edit_note_rounded, size: 17, color: AppColors.textSecondary),
    ),
  ];
}
