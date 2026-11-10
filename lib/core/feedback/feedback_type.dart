import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Tipos semânticos de feedback visual do Design System.
/// Cada tipo encapsula sua cor temática, ícone padrão e título padrão.
enum FeedbackType {
  success,
  error,
  warning,
  info;

  /// Retorna a cor de destaque representativa de cada estado
  Color color(BuildContext context) {
    switch (this) {
      case FeedbackType.error:
        return Theme.of(context).colorScheme.error; // Vermelho neon do tema da arena
      case FeedbackType.success:
        return AppColors.feedbackSuccess; // Verde neon elétrico
      case FeedbackType.warning:
        return AppColors.feedbackWarning; // Âmbar dourado vibrante
      case FeedbackType.info:
        return AppColors.feedbackInfo; // Ciano elétrico neon
    }
  }

  /// Ícone padrão correspondente ao tipo de alerta
  IconData get defaultIcon {
    switch (this) {
      case FeedbackType.error:
        return Icons.error_outline_rounded;
      case FeedbackType.success:
        return Icons.check_circle_outline_rounded;
      case FeedbackType.warning:
        return Icons.warning_amber_rounded;
      case FeedbackType.info:
        return Icons.info_outline_rounded;
    }
  }

  /// Título padrão semântico exibido no cabeçalho da notificação
  String get defaultTitle {
    switch (this) {
      case FeedbackType.error:
        return 'ERRO';
      case FeedbackType.success:
        return 'SUCESSO';
      case FeedbackType.warning:
        return 'ATENÇÃO';
      case FeedbackType.info:
        return 'INFORMAÇÃO';
    }
  }
}
