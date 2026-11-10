import 'package:flutter/material.dart';
import '../../../../../core/theme/theme.dart';
import '../../models/tournament_options_dto.dart';
import '../../models/tournament_wizard_state.dart';

/// Passo 3 do Wizard: Séries (MD1, MD2, MD3, MD5) e Modo Draft.
class WizardStepSeries extends StatelessWidget {
  final TournamentWizardState state;
  final TournamentConfigurationOptionsDto? options;
  final VoidCallback onChanged;

  const WizardStepSeries({
    super.key,
    required this.state,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasGroups = state.formatType != 'DirectPlayoffs';

    // UI Passiva: Formatos de séries fornecidos pelo backend
    final groupFormats = options?.seriesFormats.groupStageFormats ?? const ['Bo1', 'Bo2', 'Bo3'];
    final playoffFormats = options?.seriesFormats.playoffFormats ?? const ['Bo1', 'Bo3', 'Bo5'];
    final grandFinalFormats = options?.seriesFormats.grandFinalFormats ?? const ['Bo1', 'Bo3', 'Bo5'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Séries da Fase de Grupos (Sempre padronizado)
        const Text(
          'SÉRIES DA FASE DE GRUPOS',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),

        Row(
          children: groupFormats.map((format) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildSeriesChip(
                  label: _formatLabel(format),
                  isSelected: hasGroups && state.groupStageFormat == format,
                  isEnabled: hasGroups,
                  onTap: hasGroups
                      ? () {
                          state.groupStageFormat = format;
                          // Regra 1: se grupos for Bo2/Bo3, playoffs não podem ser Bo1
                          if ((format == 'Bo2' || format == 'Bo3') &&
                              state.playoffSeriesFormat == 'Bo1') {
                            state.playoffSeriesFormat = 'Bo3';
                          }
                          // Regra 2: Playoffs em Bo5 só são permitidos quando Grupos for Bo3
                          if ((format == 'Bo1' || format == 'Bo2') &&
                              state.playoffSeriesFormat == 'Bo5') {
                            state.playoffSeriesFormat = 'Bo3';
                          }
                          _adjustFinalSeriesRule();
                          onChanged();
                        }
                      : null,
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // 2. Séries dos Playoffs (Mata-Mata)
        const Text(
          'SÉRIES DOS PLAYOFFS (MATA-MATA)',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),

        Row(
          children: playoffFormats.map((format) {
            final isBlocked = _isPlayoffBlocked(format, hasGroups: hasGroups);

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildSeriesChip(
                  label: _formatLabel(format),
                  isSelected: state.playoffSeriesFormat == format,
                  isEnabled: !isBlocked,
                  onTap: () {
                    state.playoffSeriesFormat = format;
                    _adjustFinalSeriesRule();
                    onChanged();
                  },
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // 3. Séries da Grande Final
        const Text(
          'SÉRIE DA GRANDE FINAL',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),

        Row(
          children: grandFinalFormats.map((format) {
            final isBlocked = _isGrandFinalBlocked(format);

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildSeriesChip(
                  label: _formatLabel(format),
                  isSelected: state.grandFinalSeriesFormat == format,
                  isEnabled: !isBlocked,
                  onTap: () {
                    state.grandFinalSeriesFormat = format;
                    onChanged();
                  },
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 18),

        // 4. Configuração de Modo Draft (Obrigatório / Fixo)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: AppColors.primaryNeon.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.primaryNeon.withValues(alpha: 0.7),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.shuffle_rounded,
                  size: 17,
                  color: AppColors.primaryNeon,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Habilitar Sessão de Draft',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Cria automaticamente a sala de escolha de capitães e jogadores.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryNeon.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'MODO DRAFT ATIVO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryNeon,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _adjustFinalSeriesRule() {
    if (state.playoffSeriesFormat == 'Bo5') {
      state.grandFinalSeriesFormat = 'Bo5';
    } else if (state.playoffSeriesFormat == 'Bo3' &&
        state.grandFinalSeriesFormat == 'Bo1') {
      state.grandFinalSeriesFormat = 'Bo3';
    } else if (state.playoffSeriesFormat == 'Bo1' &&
        state.grandFinalSeriesFormat == 'Bo5') {
      state.grandFinalSeriesFormat = 'Bo3';
    }
  }

  bool _isPlayoffBlocked(String format, {required bool hasGroups}) {
    // 1. Se grupos for Bo2 ou Bo3, playoffs não podem ser Bo1
    if (hasGroups &&
        (state.groupStageFormat == 'Bo2' || state.groupStageFormat == 'Bo3') &&
        format == 'Bo1') {
      return true;
    }

    // 2. Playoffs em Bo5 (MD5) só são permitidos quando houver Fase de Grupos em Bo3 (MD3)
    if (format == 'Bo5') {
      if (!hasGroups) return true;
      if (state.groupStageFormat == 'Bo1' || state.groupStageFormat == 'Bo2') {
        return true;
      }
    }

    return false;
  }

  bool _isGrandFinalBlocked(String format) {
    // 1. Final nunca pode ser menor que playoffs
    final playoffVal = _numericBo(state.playoffSeriesFormat);
    final finalVal = _numericBo(format);
    if (finalVal < playoffVal) return true;

    // 2. Se playoffs for Bo1, final não pode saltar direto para Bo5 (máximo Bo3)
    if (state.playoffSeriesFormat == 'Bo1' && format == 'Bo5') return true;

    return false;
  }

  int _numericBo(String format) {
    switch (format) {
      case 'Bo1':
        return 1;
      case 'Bo2':
        return 2;
      case 'Bo3':
        return 3;
      case 'Bo5':
        return 5;
      default:
        return 1;
    }
  }

  String _formatLabel(String format) {
    switch (format) {
      case 'Bo1':
        return 'MD1';
      case 'Bo2':
        return 'MD2';
      case 'Bo3':
        return 'MD3';
      case 'Bo5':
        return 'MD5';
      default:
        return format;
    }
  }

  Widget _buildSeriesChip({
    required String label,
    required bool isSelected,
    bool isEnabled = true,
    required VoidCallback? onTap,
  }) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.35,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryNeon.withValues(alpha: 0.16)
                : AppColors.surfaceHighlight.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryNeon
                  : AppColors.border.withValues(alpha: 0.6),
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
