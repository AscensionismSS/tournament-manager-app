import 'package:flutter/material.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/theme/theme.dart';
import '../../models/dota_role_def.dart';

/// Item de linha interativo para seleção de função e marcação de função favorita no Dota 2.
class RoleSelectionTile extends StatelessWidget {
  final DotaRoleDef def;
  final bool isSelected;
  final bool isPreferred;
  final VoidCallback onToggle;
  final VoidCallback onSetPreferred;

  const RoleSelectionTile({
    super.key,
    required this.def,
    required this.isSelected,
    required this.isPreferred,
    required this.onToggle,
    required this.onSetPreferred,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? (isPreferred
              ? AppColors.dotaGold.withValues(alpha: 0.08)
              : AppColors.surfaceHighlight.withValues(alpha: 0.45))
          : Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          child: Row(
            children: [
              // Checkbox Quadrado Estilo Dota 2
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isPreferred
                          ? AppColors.dotaGold
                          : AppColors.primaryNeon)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSelected
                        ? (isPreferred
                            ? AppColors.dotaGoldLight
                            : AppColors.primaryNeon)
                        : AppColors.border.withValues(alpha: 0.9),
                    width: 1.4,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: (isPreferred
                                    ? AppColors.dotaGold
                                    : AppColors.primaryNeon)
                                .withValues(alpha: 0.35),
                            blurRadius: 6,
                            spreadRadius: 0.5,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // Ícone Vetorial da Função
              DotaRoleIcon(
                role: def.roleType,
                size: 20,
                color: isSelected ? def.color : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),

              // Rótulo da Função
              Expanded(
                child: Text(
                  def.label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ),

              // Botão Interativo de Estrela (Função Favorita)
              Tooltip(
                message: isPreferred
                    ? 'Função Favorita Definida'
                    : 'Definir como Função Favorita',
                child: InkResponse(
                  onTap: onSetPreferred,
                  radius: 20,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: isPreferred
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.dotaGold
                                      .withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: AppColors.dotaGold
                                        .withValues(alpha: 0.6),
                                    width: 1,
                                  ),
                                ),
                                child: const Text(
                                  'FAVORITA',
                                  style: TextStyle(
                                    color: AppColors.dotaGold,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.star_rounded,
                                size: 22,
                                color: AppColors.dotaGold,
                              ),
                            ],
                          )
                        : Icon(
                            Icons.star_border_rounded,
                            size: 22,
                            color: isSelected
                                ? AppColors.textSecondary.withValues(alpha: 0.5)
                                : AppColors.textSecondary
                                    .withValues(alpha: 0.25),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
