import 'package:flutter/material.dart';
import '../theme/theme.dart';
import 'app_icon_button.dart';

/// Banner de alerta global persistente (Dumb UI).
/// Exibido logo abaixo da TopBar quando o sistema se encontra em Modo de Manutenção
/// ou com comunicados urgentes da administração.
class GlobalNoticeBanner extends StatelessWidget {
  final String? message;
  final VoidCallback? onDismiss;

  const GlobalNoticeBanner({
    super.key,
    this.message,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final hasCustomMessage = message != null && message!.trim().isNotEmpty;
    final displayMessage = hasCustomMessage
        ? message!.trim()
        : 'O sistema está temporariamente operando em Modo de Manutenção. Algumas operações podem estar restritas.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.feedbackWarning.withValues(alpha: 0.12),
        border: Border(
          bottom: BorderSide(
            color: AppColors.feedbackWarning.withValues(alpha: 0.45),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.feedbackWarning.withValues(alpha: 0.20),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.feedbackWarning,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.feedbackWarning.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppColors.feedbackWarning.withValues(alpha: 0.55),
                width: 0.8,
              ),
            ),
            child: const Text(
              'MANUTENÇÃO',
              style: TextStyle(
                color: AppColors.feedbackWarning,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              displayMessage,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 8),
            AppIconButton(
              icon: Icons.close_rounded,
              size: AppIconButtonSize.compact,
              variant: AppIconButtonVariant.ghost,
              customColor: AppColors.textSecondary,
              tooltip: 'Fechar aviso',
              onPressed: onDismiss,
            ),
          ],
        ],
      ),
    );
  }
}
