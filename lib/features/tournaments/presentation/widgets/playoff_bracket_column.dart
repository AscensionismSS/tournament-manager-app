import 'package:flutter/material.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/theme/theme.dart';
import '../../models/bracket_slot_dto.dart';
import '../../models/match_series_dto.dart';
import 'playoff_series_card.dart';

/// Coluna de uma Rodada do Bracket de Playoffs (SRP).
/// Agrupa os confrontos daquela rodada verticalmente com espaçamento visual harmônico.
class PlayoffBracketColumn extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<BracketSlotDto> slots;
  final Map<String, MatchSeriesDto> matchesBySlotCode;
  final void Function(BracketSlotDto slot, MatchSeriesDto? match)? onSeriesTap;

  const PlayoffBracketColumn({
    super.key,
    required this.title,
    this.subtitle,
    required this.slots,
    required this.matchesBySlotCode,
    this.onSeriesTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 286,
      margin: const EdgeInsets.only(right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cabeçalho da Rodada
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceHighlight.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border, width: 0.8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 9.5,
                            color:
                                AppColors.textSecondary.withValues(alpha: 0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                AppBadge(
                  label:
                      '${slots.length} ${slots.length == 1 ? "SÉRIE" : "SÉRIES"}',
                  variant: AppBadgeVariant.neutral,
                  height: 18,
                  fontSize: 8.5,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Lista de Séries da Rodada
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(slots.length, (index) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == slots.length - 1 ? 0 : 16,
                ),
                child: _buildSeriesItem(slots[index]),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSeriesItem(BracketSlotDto slot) {
    final match = matchesBySlotCode[slot.code];
    return PlayoffSeriesCard(
      slot: slot,
      match: match,
      onTap: onSeriesTap != null ? () => onSeriesTap!(slot, match) : null,
    );
  }
}
