import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'app_button.dart';

/// Botão padronizado de Cancelamento (AppCancelButton) para modais, dialogs e sheets.
/// Reutiliza estritamente o AppButton do Design System para garantir simetria,
/// mesma altura (46px), mesmo raio de curvatura (10px) e a tipografia oficial Oswald.
class AppCancelButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double height;
  final EdgeInsetsGeometry? padding;
  final IconData? icon;

  const AppCancelButton({
    super.key,
    this.label = 'CANCELAR',
    this.onPressed,
    this.height = 46,
    this.padding,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppButton.secondary(
      text: label,
      size: AppButtonSize.medium,
      isFullWidth: true,
      reserveLeadingSlot: false,
      icon: icon,
      onPressed: onPressed ?? () => Navigator.of(context).pop(),
    );
  }
}

/// Botão padronizado de Retorno (AppModalBackButton) para etapas de wizards e formulários.
class AppModalBackButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double height;
  final EdgeInsetsGeometry? padding;

  const AppModalBackButton({
    super.key,
    this.label = 'VOLTAR',
    required this.onPressed,
    this.height = 46,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return AppButton.outline(
      text: label,
      size: AppButtonSize.medium,
      isFullWidth: true,
      reserveLeadingSlot: false,
      icon: Icons.arrow_back_rounded,
      onPressed: onPressed,
    );
  }
}

/// Botão padronizado de Confirmação/Ação Primária (AppConfirmButton) para modais, dialogs e sheets.
/// Par oficial simétrico do [AppCancelButton], garantindo:
/// - Mesma altura padrão (46px).
/// - Mesmo raio de curvatura (10px).
/// - Mesma tipografia oficial de negócio (GoogleFonts.oswald).
/// - Suporte a estado de carregamento (isLoading), ícone opcional e cores customizáveis.
class AppConfirmButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double height;
  final EdgeInsetsGeometry? padding;
  final IconData? icon;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AppConfirmButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 46,
    this.padding,
    this.icon,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppButton.primary(
      text: label,
      size: AppButtonSize.medium,
      isFullWidth: true,
      reserveLeadingSlot: false,
      isLoading: isLoading,
      customColor: backgroundColor ?? AppColors.primaryNeon,
      icon: icon,
      onPressed: onPressed,
    );
  }
}
