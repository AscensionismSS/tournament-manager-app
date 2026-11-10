import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/theme.dart';

/// Componente padronizado de botão de retorno (AppBackButton).
/// Utiliza formato de cápsula com fundo translúcido escuro, borda sutil e ícone em destaque.
/// Pode ser reutilizado em qualquer página ou detalhe da aplicação.
class AppBackButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final String? fallbackRouteName;

  const AppBackButton({
    super.key,
    this.label = 'VOLTAR',
    this.onPressed,
    this.fallbackRouteName,
  });

  void _handleBack(BuildContext context) {
    if (onPressed != null) {
      onPressed!();
      return;
    }

    if (context.canPop()) {
      context.pop();
    } else if (fallbackRouteName != null) {
      context.goNamed(fallbackRouteName!);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleBack(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.cardSurface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.8),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_back_rounded,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
