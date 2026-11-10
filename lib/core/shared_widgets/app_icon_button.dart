import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum AppIconButtonVariant {
  /// Padrão translúcido escuro com borda sutil (Ideal para tabelas, toolbars e cards)
  standard,

  /// Destaque de acento sutil (Cor primária neon)
  primary,

  /// Perigo / Ação destrutiva (Vermelho/Excluir/Kick)
  danger,

  /// Sucesso / Confirmação (Verde neon)
  success,

  /// Alerta / Dourado (Aegis / Avisos)
  warning,

  /// Fantasma / Sem fundo (apenas hover)
  ghost,
}

enum AppIconButtonSize {
  /// 28x28px com ícone de 14px (Ideal para toolbars densas, filtros e chips compactos)
  compact(28.0, 14.0, 6.0),

  /// 32x32px com ícone de 15px (Perfeito para tabelas densas e linhas compactas)
  small(32.0, 15.0, 7.0),

  /// 38x38px com ícone de 18px (Padrão para cards e toolbars de ações)
  medium(38.0, 18.0, 8.5),

  /// 44x44px com ícone de 21px (Padrão para telas mobile e touch targets confortáveis)
  large(44.0, 21.0, 10.0);

  final double dimension;
  final double iconSize;
  final double borderRadius;

  const AppIconButtonSize(this.dimension, this.iconSize, this.borderRadius);
}

/// Botão de ícone padronizado do Design System (SRP).
/// Garante área mínima de toque confortável (touch target), recipiente translúcido
/// protetor contra imagens de fundo e contraste ideal conforme as melhores práticas de UX.
class AppIconButton extends StatefulWidget {
  final IconData? icon;
  final Widget? customIcon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final AppIconButtonVariant variant;
  final AppIconButtonSize size;
  final Color? customColor;
  final bool isLoading;

  const AppIconButton({
    super.key,
    this.icon,
    this.customIcon,
    required this.onPressed,
    this.tooltip,
    this.variant = AppIconButtonVariant.standard,
    this.size = AppIconButtonSize.medium,
    this.customColor,
    this.isLoading = false,
  }) : assert(icon != null || customIcon != null, 'Deve fornecer icon ou customIcon');

  const AppIconButton.compact({
    super.key,
    this.icon,
    this.customIcon,
    required this.onPressed,
    this.tooltip,
    this.variant = AppIconButtonVariant.standard,
    this.customColor,
    this.isLoading = false,
  })  : size = AppIconButtonSize.compact,
        assert(icon != null || customIcon != null, 'Deve fornecer icon ou customIcon');

  const AppIconButton.small({
    super.key,
    this.icon,
    this.customIcon,
    required this.onPressed,
    this.tooltip,
    this.variant = AppIconButtonVariant.standard,
    this.customColor,
    this.isLoading = false,
  })  : size = AppIconButtonSize.small,
        assert(icon != null || customIcon != null, 'Deve fornecer icon ou customIcon');

  const AppIconButton.medium({
    super.key,
    this.icon,
    this.customIcon,
    required this.onPressed,
    this.tooltip,
    this.variant = AppIconButtonVariant.standard,
    this.customColor,
    this.isLoading = false,
  })  : size = AppIconButtonSize.medium,
        assert(icon != null || customIcon != null, 'Deve fornecer icon ou customIcon');

  const AppIconButton.large({
    super.key,
    this.icon,
    this.customIcon,
    required this.onPressed,
    this.tooltip,
    this.variant = AppIconButtonVariant.standard,
    this.customColor,
    this.isLoading = false,
  })  : size = AppIconButtonSize.large,
        assert(icon != null || customIcon != null, 'Deve fornecer icon ou customIcon');

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    final colors = _resolveColors();

    final Widget button = MouseRegion(
      onEnter: isEnabled ? (_) => setState(() => _isHovered = true) : null,
      onExit: isEnabled ? (_) => setState(() => _isHovered = false) : null,
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: widget.size.dimension,
        height: widget.size.dimension,
        decoration: BoxDecoration(
          color: _isHovered
              ? colors.hoverBackground
              : (!isEnabled ? colors.background.withValues(alpha: 0.3) : colors.background),
          borderRadius: BorderRadius.circular(widget.size.borderRadius),
          border: Border.all(
            color: _isHovered
                ? colors.hoverBorder
                : (!isEnabled ? colors.border.withValues(alpha: 0.3) : colors.border),
            width: 0.8,
          ),
          boxShadow: _isHovered && isEnabled
              ? [
                  BoxShadow(
                    color: colors.foreground.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? widget.onPressed : null,
            borderRadius: BorderRadius.circular(widget.size.borderRadius),
            splashColor: colors.foreground.withValues(alpha: 0.15),
            highlightColor: Colors.transparent,
            child: Center(
              child: widget.isLoading
                  ? SizedBox(
                      width: widget.size.iconSize - 2,
                      height: widget.size.iconSize - 2,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.foreground,
                      ),
                    )
                  : (widget.customIcon ??
                      Icon(
                        widget.icon,
                        size: widget.size.iconSize,
                        color: isEnabled
                            ? (_isHovered ? colors.hoverForeground : colors.foreground)
                            : colors.foreground.withValues(alpha: 0.35),
                      )),
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null && widget.tooltip!.isNotEmpty) {
      return Tooltip(
        message: widget.tooltip!,
        waitDuration: const Duration(milliseconds: 400),
        child: button,
      );
    }

    return button;
  }

  _ButtonColors _resolveColors() {
    if (widget.customColor != null) {
      final c = widget.customColor!;
      return _ButtonColors(
        background: c.withValues(alpha: 0.08),
        hoverBackground: c.withValues(alpha: 0.18),
        border: c.withValues(alpha: 0.25),
        hoverBorder: c.withValues(alpha: 0.55),
        foreground: c,
        hoverForeground: Colors.white,
      );
    }

    switch (widget.variant) {
      case AppIconButtonVariant.standard:
        return _ButtonColors(
          background: Colors.white.withValues(alpha: 0.05),
          hoverBackground: Colors.white.withValues(alpha: 0.12),
          border: Colors.white.withValues(alpha: 0.10),
          hoverBorder: Colors.white.withValues(alpha: 0.30),
          foreground: AppColors.onSurface.withValues(alpha: 0.9),
          hoverForeground: Colors.white,
        );

      case AppIconButtonVariant.primary:
        return _ButtonColors(
          background: AppColors.primaryNeon.withValues(alpha: 0.10),
          hoverBackground: AppColors.primaryNeon.withValues(alpha: 0.22),
          border: AppColors.primaryNeon.withValues(alpha: 0.30),
          hoverBorder: AppColors.primaryNeon.withValues(alpha: 0.65),
          foreground: AppColors.primaryNeon,
          hoverForeground: Colors.white,
        );

      case AppIconButtonVariant.danger:
        return _ButtonColors(
          background: AppColors.feedbackError.withValues(alpha: 0.10),
          hoverBackground: AppColors.feedbackError.withValues(alpha: 0.24),
          border: AppColors.feedbackError.withValues(alpha: 0.30),
          hoverBorder: AppColors.feedbackError.withValues(alpha: 0.70),
          foreground: AppColors.feedbackError,
          hoverForeground: Colors.white,
        );

      case AppIconButtonVariant.success:
        return _ButtonColors(
          background: AppColors.feedbackSuccess.withValues(alpha: 0.10),
          hoverBackground: AppColors.feedbackSuccess.withValues(alpha: 0.22),
          border: AppColors.feedbackSuccess.withValues(alpha: 0.30),
          hoverBorder: AppColors.feedbackSuccess.withValues(alpha: 0.65),
          foreground: AppColors.feedbackSuccess,
          hoverForeground: Colors.white,
        );

      case AppIconButtonVariant.warning:
        return _ButtonColors(
          background: AppColors.feedbackWarning.withValues(alpha: 0.10),
          hoverBackground: AppColors.feedbackWarning.withValues(alpha: 0.22),
          border: AppColors.feedbackWarning.withValues(alpha: 0.30),
          hoverBorder: AppColors.feedbackWarning.withValues(alpha: 0.65),
          foreground: AppColors.feedbackWarning,
          hoverForeground: Colors.white,
        );

      case AppIconButtonVariant.ghost:
        return _ButtonColors(
          background: Colors.transparent,
          hoverBackground: Colors.white.withValues(alpha: 0.08),
          border: Colors.transparent,
          hoverBorder: Colors.white.withValues(alpha: 0.15),
          foreground: AppColors.onSurface.withValues(alpha: 0.8),
          hoverForeground: Colors.white,
        );
    }
  }
}

class _ButtonColors {
  final Color background;
  final Color hoverBackground;
  final Color border;
  final Color hoverBorder;
  final Color foreground;
  final Color hoverForeground;

  const _ButtonColors({
    required this.background,
    required this.hoverBackground,
    required this.border,
    required this.hoverBorder,
    required this.foreground,
    required this.hoverForeground,
  });
}

/// Botão de Informação / Ajuda padronizado do Design System (SRP).
/// Renderiza o ícone (i) oficial com tooltip, hover luminoso suave e cor primária neon/vermelha da marca por padrão.
class AppInfoButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String tooltip;
  final AppIconButtonSize size;
  final AppIconButtonVariant variant;

  const AppInfoButton({
    super.key,
    required this.onPressed,
    this.tooltip = 'Informações',
    this.size = AppIconButtonSize.compact,
    this.variant = AppIconButtonVariant.primary,
  });

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      icon: Icons.info_outline_rounded,
      tooltip: tooltip,
      size: size,
      variant: variant,
      onPressed: onPressed,
    );
  }
}
