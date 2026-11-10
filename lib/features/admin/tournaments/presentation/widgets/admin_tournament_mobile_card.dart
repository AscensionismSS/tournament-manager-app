import 'package:flutter/material.dart';
import '../../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../tournaments/models/tournament_dto.dart';

/// Card responsivo para exibição de torneio em dispositivos móveis (< 800px).
class AdminTournamentMobileCard extends StatelessWidget {
  final TournamentDto tournament;
  final ValueChanged<TournamentDto>? onTap;

  const AdminTournamentMobileCard({
    super.key,
    required this.tournament,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap != null ? () => onTap!(tournament) : null,
        borderRadius: BorderRadius.circular(18),
        child: AppCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Linha 1: Nome do Torneio + Badge de Status
              Row(
                children: [
                  Container(
                    width: tournament.hasBanner ? 46 : 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHighlight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: tournament.status.color.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: tournament.hasBanner
                        ? Image.network(
                            tournament.resolvedBannerUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              tournament.hasChampion
                                  ? Icons.workspace_premium_rounded
                                  : Icons.emoji_events_rounded,
                              size: 16,
                              color: tournament.hasChampion ? AppColors.dotaGold : AppColors.primaryNeon,
                            ),
                          )
                        : Icon(
                            tournament.hasChampion
                                ? Icons.workspace_premium_rounded
                                : Icons.emoji_events_rounded,
                            size: 16,
                            color: tournament.hasChampion ? AppColors.dotaGold : AppColors.primaryNeon,
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tournament.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppBadge(
                    label: tournament.status.label,
                    customColor: tournament.status.color,
                    icon: tournament.status.icon,
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
                      tournament.fullFormatSummary,
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
                        tournament.teamsProgressLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    tournament.formattedCreatedAt,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              if (tournament.hasChampion) ...[
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
                      'Campeão: ${tournament.championName}',
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
      ),
    );
  }
}
