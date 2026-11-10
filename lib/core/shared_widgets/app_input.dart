import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/theme.dart';

/// Componente de entrada de texto compartilhado focado estritamente em comportamento e validação.
/// Todo o estilo visual (cores de fundo, bordas normais/foco/erro, espaçamento e tipografia)
/// é herdado diretamente de [ThemeData.inputDecorationTheme].
class AppInput extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final String? labelText;
  final bool isPassword;
  final bool readOnly;
  final bool enabled;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final TextInputAction? textInputAction;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool hasError;
  final List<TextInputFormatter>? inputFormatters;

  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? fillColor;
  final Color? prefixIconColor;
  final BoxConstraints? prefixIconConstraints;
  final BoxConstraints? suffixIconConstraints;
  final EdgeInsetsGeometry? contentPadding;
  final bool autocorrect;
  final bool enableSuggestions;

  const AppInput({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.labelText,
    this.isPassword = false,
    this.readOnly = false,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.hasError = false,
    this.inputFormatters,
    this.borderColor,
    this.focusedBorderColor,
    this.fillColor,
    this.prefixIconColor,
    this.prefixIconConstraints,
    this.suffixIconConstraints,
    this.contentPadding,
    this.autocorrect = true,
    this.enableSuggestions = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final iconColor = hasError
        ? colorScheme.error
        : (prefixIconColor ?? colorScheme.onSurface.withValues(alpha: 0.7));

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: isPassword,
      readOnly: readOnly,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autocorrect: isPassword ? false : autocorrect,
      enableSuggestions: isPassword ? false : enableSuggestions,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: fillColor ?? AppColors.surfaceHighlight,
        labelText: labelText,
        labelStyle: hasError
            ? TextStyle(
                color: colorScheme.error,
                fontWeight: FontWeight.w600,
              )
            : null,
        floatingLabelStyle: hasError
            ? TextStyle(
                color: colorScheme.error,
                fontWeight: FontWeight.w700,
              )
            : null,
        hintText: hintText,
        contentPadding: contentPadding,
        prefixIconConstraints: prefixIconConstraints ??
            const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
        suffixIconConstraints: suffixIconConstraints ??
            const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: iconColor, size: 20)
            : null,
        suffixIcon: suffixIcon,
        enabledBorder: hasError
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: colorScheme.error,
                  width: 1.8,
                ),
              )
            : (borderColor != null
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: borderColor!,
                      width: 1.0,
                    ),
                  )
                : null),
        disabledBorder: hasError
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: colorScheme.error,
                  width: 1.8,
                ),
              )
            : (borderColor != null
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: borderColor!,
                      width: 1.0,
                    ),
                  )
                : null),
        focusedBorder: hasError
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: colorScheme.error,
                  width: 1.8,
                ),
              )
            : (focusedBorderColor != null || borderColor != null
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: focusedBorderColor ?? borderColor!,
                      width: 1.4,
                    ),
                  )
                : null),
      ),
    );
  }
}
