import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/theme.dart';

/// Modal dialog padronizado para a plataforma (SRP).
/// Unifica borda com curvatura de 16px, cabeçalho com ícone temático e botão de fechar sutil,
/// e rodapé de ações padronizado com botões simétricos de mesma proporção e harmonia visual.
class AppDialog extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final String title;
  final Widget content;
  final List<Widget>? actions;
  final double maxWidth;
  final EdgeInsetsGeometry contentPadding;
  final EdgeInsetsGeometry actionsPadding;
  final Widget? centerHeader;
  final Widget? trailingHeader;
  final VoidCallback? onClose;

  const AppDialog({
    super.key,
    this.icon,
    this.iconColor,
    required this.title,
    required this.content,
    this.actions,
    this.maxWidth = 440,
    this.contentPadding = const EdgeInsets.fromLTRB(20, 18, 20, 18),
    this.actionsPadding = const EdgeInsets.fromLTRB(20, 0, 20, 20),
    this.centerHeader,
    this.trailingHeader,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = iconColor ?? AppColors.primaryNeon;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.8),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.60),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Cabeçalho Padronizado da Plataforma (com ícone em badge e botão X neutro)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.canvasSurface,
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.7),
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (icon != null) ...[
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: effectiveColor.withValues(alpha: 0.15),
                            border: Border.all(
                              color: effectiveColor.withValues(alpha: 0.5),
                              width: 1.0,
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: effectiveColor,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      if (centerHeader != null) ...[
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              title.toUpperCase(),
                              style: GoogleFonts.oswald(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: centerHeader!,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: trailingHeader != null
                                ? trailingHeader!
                                : (onClose != null
                                    ? _buildCloseButton(onClose!)
                                    : const SizedBox.shrink()),
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: Text(
                            title.toUpperCase(),
                            style: GoogleFonts.oswald(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (trailingHeader != null)
                          trailingHeader!
                        else if (onClose != null)
                          _buildCloseButton(onClose!),
                      ],
                    ],
                  ),
                ),

                // 2. Conteúdo Interno com Escape Seguro de Scroll
                Flexible(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: contentPadding,
                    child: content,
                  ),
                ),

                // 3. Rodapé com Botões de Ação Simétricos e Harmônicos
                if (actions != null && actions!.isNotEmpty)
                  Padding(
                    padding: actionsPadding,
                    child: actions!.length == 1
                        ? actions!.first
                        : Row(
                            children: [
                              for (int i = 0; i < actions!.length; i++) ...[
                                if (i > 0) const SizedBox(width: 12),
                                Expanded(child: actions![i]),
                              ],
                            ],
                          ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton(VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.8),
              width: 1.0,
            ),
          ),
          child: const Icon(
            Icons.close_rounded,
            size: 16,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
