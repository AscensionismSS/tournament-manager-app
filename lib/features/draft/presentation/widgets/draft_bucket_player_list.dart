import 'package:flutter/material.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/theme/theme.dart';
import '../../models/draft_player_dto.dart';
import 'draft_player_tile.dart';

/// Lista/Grid responsivo de jogadores no Bucket com barra de rolagem dedicada (SRP).
class DraftBucketPlayerList extends StatelessWidget {
  final ScrollController scrollController;
  final List<DraftPlayerDto> players;
  final String? processingPlayerId;
  final bool canManage;
  final String emptyMessage;
  final ValueChanged<DraftPlayerDto>? onAddPlayer;

  const DraftBucketPlayerList({
    super.key,
    required this.scrollController,
    required this.players,
    this.processingPlayerId,
    required this.canManage,
    required this.emptyMessage,
    this.onAddPlayer,
  });

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11.5,
            color: AppColors.textSecondary,
          ),
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
                  itemCount: players.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 6,
                    mainAxisExtent: 78,
                  ),
                  itemBuilder: (context, index) {
                    final player = players[index];
                    final bool isProcessing = processingPlayerId == player.id;

                    return DraftPlayerTile(
                      player: player,
                      isProcessing: isProcessing,
                      trailing: canManage && onAddPlayer != null
                          ? AppIconButton(
                              icon: Icons.add_rounded,
                              tooltip: 'Atribuir à Equipe',
                              variant: AppIconButtonVariant.primary,
                              size: AppIconButtonSize.compact,
                              isLoading: isProcessing,
                              onPressed: isAnyActionInProgress
                                  ? null
                                  : () => onAddPlayer!(player),
                            )
                          : null,
                    );
                  },
                )
              : ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(2, 4, 12, 4),
                  itemCount: players.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final player = players[index];
                    final bool isProcessing = processingPlayerId == player.id;

                    return DraftPlayerTile(
                      player: player,
                      isProcessing: isProcessing,
                      trailing: canManage && onAddPlayer != null
                          ? AppIconButton(
                              icon: Icons.add_rounded,
                              tooltip: 'Atribuir à Equipe',
                              variant: AppIconButtonVariant.primary,
                              size: AppIconButtonSize.compact,
                              isLoading: isProcessing,
                              onPressed: isAnyActionInProgress
                                  ? null
                                  : () => onAddPlayer!(player),
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

