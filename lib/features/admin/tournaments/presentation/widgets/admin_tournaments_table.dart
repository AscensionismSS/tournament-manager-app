import 'package:flutter/material.dart';
import '../../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../tournaments/models/tournament_dto.dart';

/// Tabela de Torneios para Desktop (≥ 800px).
/// Utiliza [AppCard] oficial, [AppBadge] e [AppIconButton] padronizados.
class AdminTournamentsTable extends StatelessWidget {
  final List<TournamentDto> tournaments;
  final ValueChanged<TournamentDto>? onSelectTournament;

  const AdminTournamentsTable({
    super.key,
    required this.tournaments,
    this.onSelectTournament,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Cabeçalho da Tabela
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceHighlight.withValues(alpha: 0.5),
              border: const Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    'TORNEIO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'FORMATO & CHAVE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'EQUIPES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'STATUS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'CRIADO EM',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                SizedBox(
                  width: 50,
                  child: Text(
                    'AÇÕES',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Linhas da Tabela
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tournaments.length,
            separatorBuilder: (context, index) => const Divider(
              color: AppColors.border,
              height: 1,
            ),
            itemBuilder: (context, index) {
              final tournament = tournaments[index];
              return _buildRow(context, tournament);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, TournamentDto t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // 1. Torneio (Banner Thumbnail + Nome)
          Expanded(
            flex: 4,
            child: Row(
              children: [
                _buildTournamentBanner(t),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        t.name,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (t.hasChampion)
                        Row(
                          children: [
                            const Icon(
                              Icons.military_tech_rounded,
                              size: 13,
                              color: AppColors.dotaGold,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Campeão: ${t.championName}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.dotaGold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Formato & Chave
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.formatLabel,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  t.playoffFormatLabel,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // 3. Equipes
          Expanded(
            flex: 2,
            child: Row(
              children: [
                const Icon(
                  Icons.groups_rounded,
                  size: 15,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  t.teamsProgressLabel,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // 4. Status
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: AppBadge(
                label: t.status.label,
                customColor: t.status.color,
                icon: t.status.icon,
              ),
            ),
          ),

          // 5. Criado Em
          Expanded(
            flex: 2,
            child: Text(
              t.formattedCreatedAt,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          // 6. Ações
          SizedBox(
            width: 50,
            child: Center(
              child: AppIconButton(
                icon: Icons.chevron_right_rounded,
                tooltip: 'Visualizar Torneio',
                size: AppIconButtonSize.compact,
                variant: AppIconButtonVariant.ghost,
                onPressed: () => onSelectTournament?.call(t),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentBanner(TournamentDto t) {
    final hasBanner = t.hasBanner;
    const double width = 56.0;
    const double height = 34.0;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: t.status.color.withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasBanner
          ? Image.network(
              t.resolvedBannerUrl!,
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildFallbackThumbnail(t),
            )
          : _buildFallbackThumbnail(t),
    );
  }

  Widget _buildFallbackThumbnail(TournamentDto t) {
    return Container(
      color: AppColors.surfaceHighlight,
      alignment: Alignment.center,
      child: Icon(
        t.hasChampion ? Icons.workspace_premium_rounded : Icons.emoji_events_rounded,
        size: 18,
        color: t.hasChampion ? AppColors.dotaGold : AppColors.primaryNeon,
      ),
    );
  }
}
