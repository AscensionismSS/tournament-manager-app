import 'package:flutter/material.dart';
import '../../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../tournaments/models/tournament_dto.dart';

/// Card responsivo e ergonômico para exibição de torneio no painel administrativo.
/// Cantos unificados em 12px e micro-hover suave.
class AdminTournamentMobileCard extends StatefulWidget {
  final TournamentDto tournament;
  final ValueChanged<TournamentDto>? onTap;

  const AdminTournamentMobileCard({
    super.key,
    required this.tournament,
    this.onTap,
  });

  @override
  State<AdminTournamentMobileCard> createState() =>
      _AdminTournamentMobileCardState();
}

class _AdminTournamentMobileCardState extends State<AdminTournamentMobileCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.tournament;
    final accentColor =
        t.isRegistrationOpen ? AppColors.dotaGold : AppColors.primaryNeon;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: widget.onTap != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: _isHovered
                ? AppColors.surfaceHighlight.withValues(alpha: 0.45)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                  ? accentColor.withValues(alpha: 0.75)
                  : AppColors.border.withValues(alpha: 0.80),
              width: _isHovered ? 1.15 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isHovered ? 0.28 : 0.16),
                blurRadius: _isHovered ? 10 : 5,
                offset: Offset(0, _isHovered ? 3 : 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: widget.onTap != null ? () => widget.onTap!(t) : null,
              borderRadius: BorderRadius.circular(12),
              splashColor: accentColor.withValues(alpha: 0.08),
              highlightColor: accentColor.withValues(alpha: 0.04),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Linha 1: Nome do Torneio + Badge de Status no Topo Direito
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: t.hasBanner ? 44 : 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceHighlight,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: t.status.color
                                        .withValues(alpha: 0.4),
                                    width: 1,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: t.hasBanner
                                    ? Image.network(
                                        t.resolvedBannerUrl!,
                                        cacheWidth: 96,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error,
                                                stackTrace) =>
                                            Icon(
                                          t.hasChampion
                                              ? Icons.workspace_premium_rounded
                                              : Icons.emoji_events_rounded,
                                          size: 16,
                                          color: t.hasChampion
                                              ? AppColors.dotaGold
                                              : AppColors.primaryNeon,
                                        ),
                                      )
                                    : Icon(
                                        t.hasChampion
                                            ? Icons.workspace_premium_rounded
                                            : Icons.emoji_events_rounded,
                                        size: 16,
                                        color: t.hasChampion
                                            ? AppColors.dotaGold
                                            : AppColors.primaryNeon,
                                      ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  t.name,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.25,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              AppBadge(
                                label: t.status.label,
                                customColor: t.status.color,
                                icon: t.status.icon,
                                fontSize: 9.8,
                                height: 21,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: AppColors.border, height: 1),
                          const SizedBox(height: 10),

                          // Linha 2: Formato e Chaveamento
                          Row(
                            children: [
                              const Icon(
                                Icons.alt_route_rounded,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  t.fullFormatSummary,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Linha 3: Progresso de Equipes + Data de Criação
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.groups_rounded,
                                    size: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    t.teamsProgressLabel,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                t.formattedCreatedAt,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),

                          if (t.hasChampion) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.military_tech_rounded,
                                  size: 14,
                                  color: AppColors.dotaGold,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Campeão: ${t.championName}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.dotaGold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: _isHovered
                          ? AppColors.dotaGoldLight
                          : AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
