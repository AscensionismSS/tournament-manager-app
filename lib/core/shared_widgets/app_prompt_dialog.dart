import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'app_dialog_action_button.dart';

/// Diálogo padronizado de solicitação de justificativa / texto (Prompt).
/// Elimina a duplicação de modais ad-hoc com caixas de texto e previne vazamento de memória (memleak)
/// descartando seus controllers no [dispose].
class AppPromptDialog extends StatefulWidget {
  final String title;
  final String message;
  final String? hintText;
  final String confirmLabel;
  final String cancelLabel;
  final IconData? icon;
  final Color? iconColor;
  final bool isDestructive;
  final bool isRequired;
  final int maxLines;
  final int? maxLength;
  final String? initialValue;

  const AppPromptDialog({
    super.key,
    required this.title,
    required this.message,
    this.hintText,
    this.confirmLabel = 'CONFIRMAR',
    this.cancelLabel = 'CANCELAR',
    this.icon,
    this.iconColor,
    this.isDestructive = false,
    this.isRequired = false,
    this.maxLines = 3,
    this.maxLength = 300,
    this.initialValue,
  });

  /// Exibe o modal e retorna o texto preenchido (ou null se cancelado/fechado).
  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String message,
    String? hintText,
    String confirmLabel = 'CONFIRMAR',
    String cancelLabel = 'CANCELAR',
    IconData? icon,
    Color? iconColor,
    bool isDestructive = false,
    bool isRequired = false,
    int maxLines = 3,
    int? maxLength = 300,
    String? initialValue,
  }) async {
    return showDialog<String?>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => AppPromptDialog(
        title: title,
        message: message,
        hintText: hintText,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        icon: icon,
        iconColor: iconColor,
        isDestructive: isDestructive,
        isRequired: isRequired,
        maxLines: maxLines,
        maxLength: maxLength,
        initialValue: initialValue,
      ),
    );
  }

  @override
  State<AppPromptDialog> createState() => _AppPromptDialogState();
}

class _AppPromptDialogState extends State<AppPromptDialog> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (widget.isRequired && text.isEmpty) {
      setState(() {
        _errorMessage = 'Este campo é obrigatório.';
      });
      _focusNode.requestFocus();
      return;
    }
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final effectiveColor = widget.iconColor ??
        (widget.isDestructive ? AppColors.feedbackError : colorScheme.primary);
    final effectiveIcon = widget.icon ??
        (widget.isDestructive
            ? Icons.warning_amber_rounded
            : Icons.edit_note_rounded);

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
                // 1. Ícone superior temático
                Center(
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: effectiveColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: effectiveColor.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      effectiveIcon,
                      color: effectiveColor,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Título do Diálogo
                Text(
                  widget.title.toUpperCase(),
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: AppColors.onBackground,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // 3. Mensagem explicativa
                Text(
                  widget.message,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),

                // 4. Campo de entrada multilinha estilizado
                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: widget.maxLines,
                  maxLength: widget.maxLength,
                  style: const TextStyle(
                    color: AppColors.onBackground,
                    fontSize: 13,
                  ),
                  onChanged: (_) {
                    if (_errorMessage != null) {
                      setState(() => _errorMessage = null);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: TextStyle(
                      color: AppColors.onSurface.withValues(alpha: 0.5),
                      fontSize: 12.5,
                    ),
                    filled: true,
                    fillColor: AppColors.navSurface,
                    contentPadding: const EdgeInsets.all(12),
                    counterStyle: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                    errorText: _errorMessage,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: effectiveColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 5. Botões de ação alinhados
                Row(
                  children: [
                    Expanded(
                      child: AppCancelButton(
                        height: 44,
                        label: widget.cancelLabel,
                        onPressed: () => Navigator.of(context).pop(null),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppConfirmButton(
                        height: 44,
                        label: widget.confirmLabel,
                        backgroundColor: widget.isDestructive
                            ? AppColors.feedbackError
                            : null,
                        onPressed: _submit,
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
