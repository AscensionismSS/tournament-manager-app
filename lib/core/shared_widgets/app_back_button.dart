import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/theme.dart';

/// Componente padronizado e unificado de botão de retorno da plataforma (SRP & DRY).
/// Segue a identidade visual oficial em Vermelho Arena Neon com contorno translúcido,
/// cantos suaves (6px) e micro-hover tátil.
///
/// Modificar aqui altera a identidade de retorno em toda a aplicação.
class AppBackButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final String? fallbackRouteName;

  const AppBackButton({
    super.key,
    this.label = 'VOLTAR',
    this.onPressed,
    this.fallbackRouteName,
  });

  @override
  State<AppBackButton> createState() => _AppBackButtonState();
}

class _AppBackButtonState extends State<AppBackButton> {
  bool _isHovered = false;

  void _handleBack(BuildContext context) {
    if (widget.onPressed != null) {
      widget.onPressed!();
      return;
    }

    if (context.canPop()) {
      context.pop();
    } else if (widget.fallbackRouteName != null) {
      context.goNamed(widget.fallbackRouteName!);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleBack(context),
          borderRadius: BorderRadius.circular(6),
          splashColor: AppColors.primaryNeon.withValues(alpha: 0.20),
          highlightColor: AppColors.primaryNeon.withValues(alpha: 0.10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _isHovered
                  ? AppColors.primaryNeon.withValues(alpha: 0.14)
                  : AppColors.primaryNeon.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _isHovered
                    ? AppColors.primaryNeon.withValues(alpha: 0.65)
                    : AppColors.primaryNeon.withValues(alpha: 0.35),
                width: 0.85,
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: AppColors.primaryNeon.withValues(alpha: 0.18),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.arrow_back_rounded,
                  size: 15,
                  color: AppColors.primaryNeon,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
