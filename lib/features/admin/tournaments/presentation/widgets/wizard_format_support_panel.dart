import 'package:flutter/material.dart';
import '../../../../../core/theme/theme.dart';

/// Painel informativo de compatibilidade dos formatos esportivos conforme a quantidade de equipes.
class WizardFormatSupportPanel extends StatelessWidget {
  final int teamCount;
  final bool isDirectPlayoffsAllowed;
  final bool isTwoGroupsAllowed;

  const WizardFormatSupportPanel({
    super.key,
    required this.teamCount,
    required this.isDirectPlayoffsAllowed,
    required this.isTwoGroupsAllowed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.8),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.rule_rounded,
                size: 14,
                color: AppColors.dotaGold,
              ),
              const SizedBox(width: 6),
              Text(
                'FORMATOS COMPATÍVEIS COM $teamCount EQUIPES:',
                style: const TextStyle(
                  fontSize: 11.0,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: AppColors.dotaGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          _buildFormatSupportRow(
            title: 'Mata-Mata Direto (Playoffs Puros)',
            isSupported: isDirectPlayoffsAllowed,
            reason: isDirectPlayoffsAllowed
                ? 'Chave simétrica perfeita sem BYE.'
                : 'Indisponível (requer 4 ou 8 equipes para chave balanceada).',
          ),
          const SizedBox(height: 3),
          _buildFormatSupportRow(
            title: 'Fase de Grupos (Grupo Único)',
            isSupported: true,
            reason: 'Disponível: todos contra todos ($teamCount equipes).',
          ),
          const SizedBox(height: 3),
          _buildFormatSupportRow(
            title: 'Fase de Grupos (2 Grupos de 4)',
            isSupported: isTwoGroupsAllowed,
            reason: isTwoGroupsAllowed
                ? 'Disponível: Grupo A e Grupo B equilibrados.'
                : 'Indisponível (requer exatamente 8 equipes para formar 2 grupos de 4).',
          ),
        ],
      ),
    );
  }

  Widget _buildFormatSupportRow({
    required String title,
    required bool isSupported,
    required String reason,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            isSupported ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 13.5,
            color: isSupported
                ? AppColors.primaryNeon
                : AppColors.textSecondary.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 11, height: 1.25),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isSupported ? Colors.white : AppColors.textSecondary,
                  ),
                ),
                TextSpan(
                  text: reason,
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: isSupported
                        ? AppColors.textSecondary
                        : AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
