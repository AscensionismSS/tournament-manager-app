import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/feedback/app_feedback.dart';
import '../../../../core/theme/theme.dart';
import '../../models/pro_matches_dto.dart';

/// Botão compacto para abrir um link externo de transmissão (Twitch, YouTube, Kick, etc.).
class ProStreamChip extends StatefulWidget {
  final ProStreamLinkDto stream;

  const ProStreamChip({
    super.key,
    required this.stream,
  });

  @override
  State<ProStreamChip> createState() => _ProStreamChipState();
}

class _ProStreamChipState extends State<ProStreamChip> {
  bool _isHovered = false;

  Future<void> _openStream() async {
    final rawUrl = widget.stream.url.trim();
    final uri = Uri.tryParse(rawUrl);

    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
      if (mounted) {
        AppFeedback.showWarning(
          context,
          message: 'Link de transmissão inválido ou indisponível.',
        );
      }
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        AppFeedback.showError(
          context,
          message: 'Não foi possível abrir a transmissão externa.',
        );
      }
    } catch (_) {
      if (mounted) {
        AppFeedback.showError(
          context,
          message: 'Falha ao tentar abrir o link de transmissão.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.stream;
    final accent = s.accentColor;

    return Tooltip(
      message: s.isOfficial
          ? 'Transmissão Oficial • ${s.displayLabel}'
          : 'Abrir ${s.displayLabel}',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            onTap: s.hasValidUrl ? _openStream : null,
            borderRadius: BorderRadius.circular(6),
            splashColor: accent.withValues(alpha: 0.18),
            highlightColor: Colors.transparent,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _isHovered
                    ? accent.withValues(alpha: 0.22)
                    : accent.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _isHovered
                      ? accent.withValues(alpha: 0.85)
                      : accent.withValues(alpha: 0.45),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(s.platformIcon, size: 13.5, color: accent),
                  const SizedBox(width: 6),
                  Text(
                    s.displayLabel,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onBackground,
                      letterSpacing: 0.2,
                    ),
                  ),
                  if (s.isMain) ...[
                    const SizedBox(width: 5),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent,
                      ),
                    ),
                  ],
                  const SizedBox(width: 5),
                  Icon(
                    Icons.open_in_new_rounded,
                    size: 11.5,
                    color: _isHovered ? AppColors.onBackground : AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
