import 'package:flutter/material.dart';
import '../../../../../core/theme/theme.dart';

/// Seletor esportivo da quantidade de equipes do torneio (Passo 1 do Wizard).
class WizardTeamCountSelector extends StatelessWidget {
  final List<int> supportedCounts;
  final int selectedCount;
  final ValueChanged<int> onTeamCountChanged;

  const WizardTeamCountSelector({
    super.key,
    required this.supportedCounts,
    required this.selectedCount,
    required this.onTeamCountChanged,
  });

  static String _getTeamSubtitle(int count) {
    switch (count) {
      case 4:
        return 'Rápido';
      case 8:
        return 'Padrão';
      default:
        return 'Times';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QUANTIDADE DE EQUIPES',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),

        Row(
          children: supportedCounts.map((count) {
            final isSelected = selectedCount == count;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () => onTeamCountChanged(count),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    height: 76,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryNeon.withValues(alpha: 0.16)
                          : AppColors.surfaceHighlight.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryNeon
                            : AppColors.border.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getTeamSubtitle(count),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? AppColors.primaryNeon : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
