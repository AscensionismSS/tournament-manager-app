import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

enum AppButtonVariant { primary, secondary, outline, ghost, danger }

enum AppButtonSize {
  /// 28px de altura - Ideal para ações inline dentro de slots e listas compactas
  compact(28.0, 10.5, 13.0, 5.0),

  /// 36px de altura - Ideal para ações de cabeçalho, tabelas e filtros
  small(36.0, 12.0, 16.0, 8.0),

  /// 46px de altura - Padrão equilibrado para formulários e modais
  medium(46.0, 14.0, 18.0, 10.0),

  /// 54px de altura - Ações de grande impacto (CTA principal da página, banners)
  large(54.0, 15.5, 20.0, 12.0);

  final double height;
  final double fontSize;
  final double iconSize;
  final double borderRadius;

  const AppButtonSize(this.height, this.fontSize, this.iconSize, this.borderRadius);
}

/// Componente de botão compartilhado do Design System (SRP).
/// Atende às melhores práticas de UI/UX:
/// - Hierarquia visual clara (Apenas 1 CTA primário sólido por visão; ações secundárias em Outline/Ghost)
/// - Suporte a ícones de navegação/ação e indicador de carregamento
/// - Tamanhos previsíveis (small: 36px, medium: 46px, large: 54px)
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final Widget? leading;
  final Color? customColor;
  final bool reserveLeadingSlot;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.large,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
    this.leading,
    this.customColor,
    this.reserveLeadingSlot = true,
  });

  factory AppButton.primary({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool isFullWidth = false,
    AppButtonSize size = AppButtonSize.large,
    IconData? icon,
    Widget? leading,
    Color? customColor,
    bool reserveLeadingSlot = true,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      variant: AppButtonVariant.primary,
      size: size,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      icon: icon,
      leading: leading,
      customColor: customColor,
      reserveLeadingSlot: reserveLeadingSlot,
    );
  }

  factory AppButton.secondary({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool isFullWidth = false,
    AppButtonSize size = AppButtonSize.large,
    IconData? icon,
    Widget? leading,
    bool reserveLeadingSlot = true,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      variant: AppButtonVariant.secondary,
      size: size,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      icon: icon,
      leading: leading,
      reserveLeadingSlot: reserveLeadingSlot,
    );
  }

  factory AppButton.outline({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool isFullWidth = false,
    AppButtonSize size = AppButtonSize.medium,
    IconData? icon,
    Widget? leading,
    Color? customColor,
    bool reserveLeadingSlot = true,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      variant: AppButtonVariant.outline,
      size: size,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      icon: icon,
      leading: leading,
      customColor: customColor,
      reserveLeadingSlot: reserveLeadingSlot,
    );
  }

  factory AppButton.ghost({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool isFullWidth = false,
    AppButtonSize size = AppButtonSize.medium,
    IconData? icon,
    Widget? leading,
    Color? customColor,
    bool reserveLeadingSlot = true,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      variant: AppButtonVariant.ghost,
      size: size,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      icon: icon,
      leading: leading,
      customColor: customColor,
      reserveLeadingSlot: reserveLeadingSlot,
    );
  }

  factory AppButton.danger({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool isFullWidth = false,
    AppButtonSize size = AppButtonSize.medium,
    IconData? icon,
    Widget? leading,
    bool reserveLeadingSlot = true,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      variant: AppButtonVariant.danger,
      size: size,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      icon: icon,
      leading: leading,
      reserveLeadingSlot: reserveLeadingSlot,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;
    final style = _resolveStyle(context);

    final resolvedFg = style.foregroundColor?.resolve(
          isEnabled ? <WidgetState>{} : <WidgetState>{WidgetState.disabled},
        ) ??
        Colors.white;

    final Widget textWidget = Text(
      text.toUpperCase(),
      textAlign: TextAlign.center,
      style: GoogleFonts.oswald(
        fontSize: size.fontSize,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: resolvedFg,
      ),
      maxLines: 1,
    );

    final double indicatorSize = size.iconSize;
    final bool hasLeading = isLoading || leading != null || icon != null;

    final Widget content = hasLeading
        ? Row(
            mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isLoading) ...[
                SizedBox(
                  height: indicatorSize,
                  width: indicatorSize,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: resolvedFg,
                  ),
                ),
                const SizedBox(width: 8),
              ] else if (leading != null) ...[
                leading!,
                const SizedBox(width: 8),
              ] else if (icon != null) ...[
                Icon(icon, size: size.iconSize, color: resolvedFg),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: textWidget,
              ),
            ],
          )
        : Center(child: textWidget);

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: size.height,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: style,
        child: content,
      ),
    );
  }

  ButtonStyle _resolveStyle(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final radius = BorderRadius.circular(size.borderRadius);

    final horizontalPadding = size == AppButtonSize.compact
        ? 8.0
        : (size == AppButtonSize.small
            ? 12.0
            : (size == AppButtonSize.medium ? 14.0 : 20.0));

    switch (variant) {
      case AppButtonVariant.primary:
        final bg = customColor ?? colorScheme.primary;
        final fg = bg.computeLuminance() > 0.45 ? AppColors.buttonDarkText : colorScheme.onPrimary;
        return ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: bg.withValues(alpha: 0.45),
          disabledForegroundColor: fg.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: radius),
          elevation: 0,
          minimumSize: Size(0, size.height),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        );

      case AppButtonVariant.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          disabledBackgroundColor: colorScheme.surface.withValues(alpha: 0.45),
          disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: const BorderSide(color: AppColors.border, width: 1.0),
          ),
          elevation: 0,
          minimumSize: Size(0, size.height),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        );

      case AppButtonVariant.outline:
        final color = customColor ?? AppColors.secondary;
        return ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          foregroundColor: color,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: color.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: color.withValues(alpha: 0.55), width: 1.1),
          ),
          elevation: 0,
          minimumSize: Size(0, size.height),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        );

      case AppButtonVariant.ghost:
        final color = customColor ?? AppColors.onSurface;
        return ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: color,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: color.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(borderRadius: radius),
          elevation: 0,
          minimumSize: Size(0, size.height),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: EdgeInsets.symmetric(horizontal: size == AppButtonSize.compact ? 8 : (size == AppButtonSize.small ? 12 : 16)),
        );

      case AppButtonVariant.danger:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.feedbackError.withValues(alpha: 0.15),
          foregroundColor: AppColors.feedbackError,
          disabledBackgroundColor: AppColors.feedbackError.withValues(alpha: 0.05),
          disabledForegroundColor: AppColors.feedbackError.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: AppColors.feedbackError.withValues(alpha: 0.5), width: 1.0),
          ),
          elevation: 0,
          minimumSize: Size(0, size.height),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        );
    }
  }
}
