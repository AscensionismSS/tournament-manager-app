import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'app_dialog_action_button.dart';

/// Modal padronizado de confirmação (Sim / Não) para ações de confirmação e alerta.
/// Respeita a restrição de largura máxima de 440px, altura padrão de 44px para os botões
/// e a tipografia de negócio (GoogleFonts.oswald via AppText).
class AppConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final IconData? icon;
  final Color? iconColor;
  final bool isDestructive;

  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'SIM',
    this.cancelLabel = 'NÃO',
    this.icon,
    this.iconColor,
    this.isDestructive = false,
  });

  /// Exibe o mini modal padronizado de confirmação e retorna 	rue (Sim) ou alse (Não/Cancelado).
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'SIM',
    String cancelLabel = 'NÃO',
    IconData? icon,
    Color? iconColor,
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (dialogContext) => AppConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        icon: icon,
        iconColor: iconColor,
        isDestructive: isDestructive,
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final effectiveColor = iconColor ?? (isDestructive ? AppColors.feedbackError : colorScheme.primary);
    final effectiveIcon = icon ?? (isDestructive ? Icons.warning_amber_rounded : Icons.help_outline_rounded);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.8),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Ícone Superior Temático com Glow
                Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: effectiveColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: effectiveColor.withValues(alpha: 0.4),
                        width: 1.2,
                      ),
                    ),
                    child: Icon(
                      effectiveIcon,
                      size: 28,
                      color: effectiveColor,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // 2. Título Centralizado
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),

                // 3. Mensagem Explicativa
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.75),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),

                // 4. Botões de Ação Padronizados e Simétricos (NÃO / SIM)
                Row(
                  children: [
                    // Botão NÃO (Cancelar)
                    Expanded(
                      child: AppCancelButton(
                        label: cancelLabel,
                        height: 44,
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Botão SIM (Confirmar)
                    Expanded(
                      child: AppConfirmButton(
                        label: confirmLabel,
                        height: 44,
                        backgroundColor: isDestructive
                            ? AppColors.feedbackError
                            : colorScheme.primary,
                        foregroundColor: Colors.white,
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
