import 'package:flutter/material.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/theme/theme.dart';
import '../../models/chosen_player_entry.dart';
import 'draft_player_tile.dart';

/// Lista/Grid responsivo de jogadores já escolhidos no Bucket com botão de remoção (SRP).
class DraftBucketChosenList extends StatelessWidget {
  final ScrollController scrollController;
  final List<ChosenPlayerEntry> entries;
  final String? processingPlayerId;
  final bool canManage;
  final ValueChanged<ChosenPlayerEntry>? onRemovePlayer;

  const DraftBucketChosenList({
    super.key,
    required this.scrollController,
    required this.entries,
    this.processingPlayerId,
    required this.canManage,
    this.onRemovePlayer,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum jogador escolhido ainda.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Exatamente 2 colunas no desktop (ou 1 se muito estreito), sem esticar para 3 ou 4 colunas
        final int crossAxisCount = constraints.maxWidth >= 430 ? 2 : 1;

        final bool isAnyActionInProgress = processingPlayerId != null;

        return RawScrollbar(
          controller: scrollController,
          thumbVisibility: false,
          thickness: 4.5,
          radius: const Radius.circular(4),
          thumbColor: AppColors.dotaGold.withValues(alpha: 0.4),
          padding: const EdgeInsets.only(right: 2),
          child: crossAxisCount > 1
              ? GridView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(2, 4, 12, 4),
                  itemCount: entries.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 6,
                    mainAxisExtent: 78,
                  ),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final bool isProcessing = processingPlayerId == entry.player.id;

                    return DraftPlayerTile(
                      player: entry.player,
                      isProcessing: isProcessing,
                      teamBadge: entry.teamBadgeLabel,
                      isCaptain: entry.isCaptain,
                      trailing: canManage && entry.isCaptain && onRemovePlayer != null
                          ? AppIconButton(
                              icon: Icons.remove_rounded,
                              tooltip: 'Remover Capitão',
                              variant: AppIconButtonVariant.danger,
                              size: AppIconButtonSize.compact,
                              isLoading: isProcessing,
                              onPressed: isAnyActionInProgress
                                  ? null
                                  : () => onRemovePlayer!(entry),
                            )
                          : null,
                    );
                  },
                )
              : ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(2, 4, 12, 4),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final bool isProcessing = processingPlayerId == entry.player.id;

                    return DraftPlayerTile(
                      player: entry.player,
                      isProcessing: isProcessing,
                      teamBadge: entry.teamBadgeLabel,
                      isCaptain: entry.isCaptain,
                      trailing: canManage && entry.isCaptain && onRemovePlayer != null
                          ? AppIconButton(
                              icon: Icons.remove_rounded,
                              tooltip: 'Remover Capitão',
                              variant: AppIconButtonVariant.danger,
                              size: AppIconButtonSize.compact,
                              isLoading: isProcessing,
                              onPressed: isAnyActionInProgress
                                  ? null
                                  : () => onRemovePlayer!(entry),
                            )
                          : null,
                    );
                  },
                ),
        );
      },
    );
  }
}

