import 'package:flutter/material.dart';
import '../../features/tournaments/models/tournament_dto.dart';
import '../theme/theme.dart';
import 'tournament_card_sections.dart';

/// Card oficial de exibição de Campeonatos na Arena Competitiva (Shared Widget - SRP & Dumb UI).
/// Remodelado em formato estendido horizontal com capa panorâmica à esquerda e informações à direita.
class AppTournamentCard extends StatefulWidget {
  final TournamentDto tournament;
  final VoidCallback? onTap;

  const AppTournamentCard({
    super.key,
    required this.tournament,
    this.onTap,
  });

  @override
  State<AppTournamentCard> createState() => _AppTournamentCardState();
}

class _AppTournamentCardState extends State<AppTournamentCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.tournament;
    final isOpen = t.isRegistrationOpen;

    final Color borderColor = isOpen
        ? AppColors.dotaGold.withValues(alpha: _isHovered ? 0.70 : 0.45)
        : (_isHovered
            ? AppColors.borderHighlight
            : AppColors.border.withValues(alpha: 0.80));

    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: _isHovered
                ? AppColors.surfaceHighlight.withValues(alpha: 0.35)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: 1.0, // Largura estritamente fixa para eliminar layout shift/tremor
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isHovered ? 0.36 : 0.20),
                blurRadius: _isHovered ? 14 : 6,
                offset: const Offset(0, 3),
              ),
              if (_isHovered && isOpen)
                BoxShadow(
                  color: AppColors.dotaGold.withValues(alpha: 0.08),
                  blurRadius: 10,
                ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(12),
              splashColor: AppColors.dotaGold.withValues(alpha: 0.06),
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Alterna para layout vertical antes que os chips técnicos sofram truncamento (< 740px)
                  final bool isMobile = constraints.maxWidth < 740;

                  // Em telas estreitas / mobile: layout vertical com altura intrínseca (zero overflow)
                  if (isMobile) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Banner no topo
                        SizedBox(
                          height: 108,
                          child: TournamentCardBanner(
                            tournament: t,
                            width: double.infinity,
                            isVertical: true,
                          ),
                        ),

                        // 2. Conteúdo mobile abaixo
                        TournamentCardMobileContent(
                          tournament: t,
                          isHovered: _isHovered,
                        ),
                      ],
                    );
                  }

                  // Em telas médias / desktop: layout horizontal estendido (168px)
                  final bool isCompact = constraints.maxWidth < 900;
                  final double bannerWidth = isCompact ? 200.0 : 270.0;

                  return SizedBox(
                    height: 168.0,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Capa / Banner Lateral Esquerdo (Panorâmico e Integrado)
                        TournamentCardBanner(
                          tournament: t,
                          width: bannerWidth,
                          isVertical: false,
                        ),

                        // 2. Conteúdo Principal à Direita (Estendido Horizontalmente)
                        Expanded(
                          child: TournamentCardContent(
                            tournament: t,
                            isHovered: _isHovered,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
