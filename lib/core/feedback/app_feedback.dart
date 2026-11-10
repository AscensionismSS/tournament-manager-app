import 'dart:async';
import 'package:flutter/material.dart';
import '../navigation/app_router.dart';
import '../theme/theme.dart';
import 'feedback_type.dart';

/// Serviço desacoplado de feedback visual (Toasts/SnackBars) para a aplicação.
/// Renderizado via [Overlay] na raiz da aplicação (rootOverlay: true), garantindo que
/// fique SEMPRE acima de qualquer diálogo modal, popups, telas ou barreiras escuras.
class AppFeedback {
  AppFeedback._();

  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  /// Limpa qualquer feedback atualmente em exibição
  static void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    if (_currentEntry != null) {
      try {
        _currentEntry?.remove();
      } catch (_) {}
      _currentEntry = null;
    }
  }

  /// Exibe um feedback visual estilizado flutuante na tela (sobreposto a tudo).
  static void show(
    BuildContext context, {
    required FeedbackType type,
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    dismiss();

    final overlay = Overlay.maybeOf(context, rootOverlay: true) ??
        AppRouter.rootNavigatorKey.currentState?.overlay;

    if (overlay == null) return;

    final feedbackColor = type.color(context);
    final displayTitle = title ?? type.defaultTitle;
    final displayIcon = type.defaultIcon;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _AppFeedbackToast(
        type: type,
        feedbackColor: feedbackColor,
        title: displayTitle,
        message: message,
        icon: displayIcon,
        onDismiss: () {
          if (_currentEntry == entry) {
            dismiss();
          }
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    _dismissTimer = Timer(duration, () {
      if (_currentEntry == entry) {
        dismiss();
      }
    });
  }

  /// Atalho para feedback de erro
  static void showError(
    BuildContext context, {
    required String message,
    String? title,
    Duration? duration,
  }) {
    show(
      context,
      type: FeedbackType.error,
      message: message,
      title: title,
      duration: duration ?? const Duration(seconds: 5),
    );
  }

  /// Atalho para feedback de sucesso
  static void showSuccess(
    BuildContext context, {
    required String message,
    String? title,
    Duration? duration,
  }) {
    show(
      context,
      type: FeedbackType.success,
      message: message,
      title: title,
      duration: duration ?? const Duration(seconds: 4),
    );
  }

  /// Atalho para feedback de atenção / aviso
  static void showWarning(
    BuildContext context, {
    required String message,
    String? title,
    Duration? duration,
  }) {
    show(
      context,
      type: FeedbackType.warning,
      message: message,
      title: title,
      duration: duration ?? const Duration(seconds: 4),
    );
  }

  /// Atalho para feedback informativo neutro
  static void showInfo(
    BuildContext context, {
    required String message,
    String? title,
    Duration? duration,
  }) {
    show(
      context,
      type: FeedbackType.info,
      message: message,
      title: title,
      duration: duration ?? const Duration(seconds: 4),
    );
  }
}

class _AppFeedbackToast extends StatefulWidget {
  final FeedbackType type;
  final Color feedbackColor;
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback onDismiss;

  const _AppFeedbackToast({
    required this.type,
    required this.feedbackColor,
    required this.title,
    required this.message,
    required this.icon,
    required this.onDismiss,
  });

  @override
  State<_AppFeedbackToast> createState() => _AppFeedbackToastState();
}

class _AppFeedbackToastState extends State<_AppFeedbackToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleClose() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: SlideTransition(
              position: _offsetAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Material(
                  color: Colors.transparent,
                  elevation: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.canvasSurface, // Superfície de alto contraste
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: widget.feedbackColor.withValues(alpha: 0.85),
                        width: 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.feedbackColor.withValues(alpha: 0.35),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.8),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.feedbackColor.withValues(alpha: 0.16),
                          ),
                          child: Icon(
                            widget.icon,
                            color: widget.feedbackColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: textTheme.titleSmall?.copyWith(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                widget.message,
                                style: textTheme.bodySmall?.copyWith(
                                  fontSize: 12.5,
                                  color: Colors.white.withValues(alpha: 0.88),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          color: Colors.white.withValues(alpha: 0.6),
                          splashRadius: 16,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          onPressed: _handleClose,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
