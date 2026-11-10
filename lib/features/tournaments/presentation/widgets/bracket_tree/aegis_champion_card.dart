import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../../core/theme/theme.dart';
import 'bracket_tree_models.dart';

/// Card do Troféu / Campeão do Torneio (Aegis Tsurus).
/// Exibido em tamanho generoso à direita da Grande Final com opção de clique para zoom em HD.
class AegisChampionCard extends StatelessWidget {
  final BracketChampionNode node;

  const AegisChampionCard({
    super.key,
    required this.node,
  });

  void _showTrophyDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.dotaGold.withValues(alpha: 0.8),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.dotaGold.withValues(alpha: 0.3),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // A) Topo do Modal
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.dotaGold.withValues(alpha: 0.12),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(13)),
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.dotaGold.withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.emoji_events_rounded,
                            size: 18,
                            color: AppColors.dotaGold,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'AEGIS DOS CAMPEÕES • TSURUS PLUS+ 2026',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: AppColors.dotaGoldLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          AppIconButton(
                            icon: Icons.close_rounded,
                            tooltip: 'Fechar visualização',
                            onPressed: () => Navigator.of(ctx).pop(),
                            size: AppIconButtonSize.compact,
                            variant: AppIconButtonVariant.ghost,
                          ),
                        ],
                      ),
                    ),

                    // B) Área de Imagem Interativa com Zoom (Pinch / Drag)
                    Expanded(
                      child: ClipRRect(
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: InteractiveViewer(
                                minScale: 1.0,
                                maxScale: 4.0,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Center(
                                    child: Image.asset(
                                      'assets/images/aegis_tsurus.png',
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.emoji_events_rounded,
                                          size: 120,
                                          color: AppColors.dotaGold,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // C) Rodapé com Inscrição e Detalhes
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHighlight,
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(13)),
                        border: Border(
                          top: BorderSide(
                            color: AppColors.border.withValues(alpha: 0.8),
                            width: 0.8,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            node.isDecided
                                ? Icons.workspace_premium_rounded
                                : Icons.military_tech_rounded,
                            size: 20,
                            color: AppColors.dotaGoldLight,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  node.isDecided &&
                                          node.championTeamName != null &&
                                          node.championTeamName!.isNotEmpty
                                      ? 'CAMPEÃO CONSAGRADO: ${node.championTeamName!.toUpperCase()}'
                                      : 'TROFÉU OFICIAL EM DISPUTA',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                    color: AppColors.dotaGoldLight,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Tsurus Plus+ 2026 • Edição 3',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppButton(
                            text: 'FECHAR',
                            onPressed: () => Navigator.of(ctx).pop(),
                            size: AppButtonSize.small,
                            variant: AppButtonVariant.ghost,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDecided = node.isDecided;
    final championName = node.championTeamName;

    return Container(
      width: node.width,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDecided
              ? AppColors.dotaGold
              : AppColors.dotaGold.withValues(alpha: 0.4),
          width: isDecided ? 1.5 : 1.0,
        ),
        boxShadow: [
          if (isDecided) ...[
            BoxShadow(
              color: AppColors.dotaGold.withValues(alpha: 0.32),
              blurRadius: 22,
              spreadRadius: 2,
            ),
          ] else ...[
            BoxShadow(
              color: AppColors.dotaGold.withValues(alpha: 0.1),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ],
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Cabeçalho de Glória
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color:
                  AppColors.dotaGold.withValues(alpha: isDecided ? 0.18 : 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(11)),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.dotaGold
                      .withValues(alpha: isDecided ? 0.45 : 0.22),
                  width: 0.8,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  size: 15,
                  color: AppColors.dotaGold,
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'AEGIS DOS CAMPEÕES',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: AppColors.dotaGoldLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AppBadge(
                  label: isDecided ? 'CAMPEÃO' : 'EM DISPUTA',
                  customColor:
                      isDecided ? AppColors.dotaGold : AppColors.textSecondary,
                  height: 18,
                  fontSize: 8.5,
                ),
              ],
            ),
          ),

          // 2. Imagem Oficial em Destaque Maior (Clicável para Ampliar)
          Tooltip(
            message: 'Clique para ampliar o Troféu em Alta Resolução',
            child: InkWell(
              onTap: () => _showTrophyDialog(context),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Opacity(
                        opacity: isDecided ? 1.0 : 0.85,
                        child: Image.asset(
                          'assets/images/aegis_tsurus.png',
                          height: 175,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 175,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.emoji_events_rounded,
                                size: 80,
                                color: AppColors.dotaGold,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Ícone discreto de lupa para indicar interatividade
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.dotaGold.withValues(alpha: 0.4),
                            width: 0.6,
                          ),
                        ),
                        child: const Icon(
                          Icons.zoom_in_rounded,
                          size: 13,
                          color: AppColors.dotaGoldLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Faixa de Nome do Time Vencedor (Abaixo do Escudo)
          Container(
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: isDecided
                  ? AppColors.dotaGold.withValues(alpha: 0.18)
                  : AppColors.surfaceHighlight.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: isDecided
                    ? AppColors.dotaGold.withValues(alpha: 0.75)
                    : AppColors.border,
                width: 0.9,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isDecided
                      ? Icons.workspace_premium_rounded
                      : Icons.lock_clock_rounded,
                  size: 16,
                  color: isDecided
                      ? AppColors.dotaGoldLight
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isDecided ? 'VENCEDOR DO TÍTULO' : 'CAMPEÃO',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: isDecided
                              ? AppColors.dotaGold
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        isDecided &&
                                championName != null &&
                                championName.isNotEmpty
                            ? championName.toUpperCase()
                            : 'A DEFINIR',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: isDecided
                              ? AppColors.dotaGoldLight
                              : AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
