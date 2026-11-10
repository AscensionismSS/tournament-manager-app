import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Botão quadrado canônico (46x46) para limpeza rápida de filtros em barras de busca (Modelo MembersFilterBar).
/// Centralizado no Shared para eliminar repetição de código nas FilterBars e garantir zero layout shift.
class AppFilterClearButton extends StatelessWidget {
  final bool hasActiveFilters;
  final VoidCallback onClear;

  const AppFilterClearButton({
    super.key,
    required this.hasActiveFilters,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: hasActiveFilters ? 'Limpar todos os filtros' : 'Nenhum filtro ativo',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: hasActiveFilters ? onClear : null,
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

