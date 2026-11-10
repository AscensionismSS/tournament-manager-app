import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/dota_hero_helper.dart';
import '../utils/dota_item_helper.dart';

/// Dados agnósticos de um Tier da Jungle (Artefato Neutro + Encantamento/Buff)
class DotaNeutralTierData {
  final int tierNumber;
  final String? neutralItem;
  final String? jungleBuff;
  final bool isLatest;

  const DotaNeutralTierData({
    required this.tierNumber,
    this.neutralItem,
    this.jungleBuff,
    this.isLatest = false,
  });
}

/// Célula padronizada de Herói (54x30px) + Nome do Jogador + Nome do Herói (46px altura mínima).
/// Mantém alinhamento estrito de 215px de largura nas tabelas de estatísticas.
class DotaHeroPlayerCell extends StatelessWidget {
  final int heroId;
  final String? heroName;
  final String playerName;

  const DotaHeroPlayerCell({
    super.key,
    required this.heroId,
    required this.heroName,
    required this.playerName,
  });

  @override
  Widget build(BuildContext context) {
    final heroAsset = DotaHeroHelper.resolveHeroAsset(
      heroId: heroId,
      rawName: heroName,
      type: DotaHeroImageType.horizontal,
    );
    final heroDisplayName = DotaHeroHelper.getDisplayName(
      heroId: heroId,
      rawName: heroName,
    );
    final String heroSubLabel =
        heroId > 0 ? heroDisplayName : 'Herói Indefinido (Replay)';

    return Container(
      constraints: const BoxConstraints(minHeight: 46),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              width: 54,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.canvasSurface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.8),
                  width: 0.8,
                ),
              ),
              child: heroAsset != null
                  ? Image.asset(
                      heroAsset,
                      width: 54,
                      height: 30,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const _FallbackHeroBox(),
                    )
                  : const _FallbackHeroBox(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  playerName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  heroSubLabel,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: heroId > 0
                        ? AppColors.textSecondary
                        : AppColors.feedbackWarning,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Slot de item do Dota 2 (Inventário Principal 40x28px ou Mochila 28x24px).
class DotaItemSlot extends StatelessWidget {
  final String? itemName;
  final int? itemId;
  final bool isBackpack;

  const DotaItemSlot({
    super.key,
    this.itemName,
    this.itemId,
    this.isBackpack = false,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = DotaItemHelper.resolveItemAsset(
      itemName: itemName,
      itemId: itemId,
    );
    final displayName = DotaItemHelper.getDisplayName(
      itemName: itemName,
      itemId: itemId,
    );
    final hasItem = assetPath != null;

    final double width = isBackpack ? 28 : 40;
    final double height = isBackpack ? 24 : 28;

    return Tooltip(
      message: displayName,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isBackpack
              ? AppColors.canvasSurface.withValues(alpha: 0.5)
              : AppColors.canvasSurface,
          borderRadius: BorderRadius.circular(isBackpack ? 3.0 : 3.5),
          border: Border.all(
            color: hasItem
                ? AppColors.border.withValues(alpha: isBackpack ? 0.8 : 0.9)
                : AppColors.border.withValues(alpha: isBackpack ? 0.4 : 0.5),
            width: isBackpack ? 0.7 : 0.8,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasItem
            ? Image.asset(
                assetPath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const _ItemPlaceholder(isCircle: false),
              )
            : const _ItemPlaceholder(isCircle: false),
      ),
    );
  }
}

/// Linha horizontal exibindo os 4 slots de Tiers da Jungle (T1, T2, T3, T4).
/// Cada Tier exibe o Item Neutro circular (30x30px) com a insígnia ampliada do Buff da Jungle (19x19px) no canto inferior direito.
class DotaNeutralProgressionRow extends StatelessWidget {
  final List<DotaNeutralTierData> tiers;

  const DotaNeutralProgressionRow({
    super.key,
    required this.tiers,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < tiers.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          DotaNeutralTierBadge(
            tier: tiers[i],
            showTierPrefixInTooltip: true,
          ),
        ],
      ],
    );
  }
}

/// Slot combinado de um Tier da Jungle:
/// - Círculo principal: Artefato Neutro (30x30px)
/// - Sub-insígnia ampliada deslocada mais para fora à direita: Buff/Encantamento da Jungle (19x19px)
class DotaNeutralTierBadge extends StatelessWidget {
  final DotaNeutralTierData tier;
  final bool compact;
  final bool showTierPrefixInTooltip;

  const DotaNeutralTierBadge({
    super.key,
    required this.tier,
    this.compact = false,
    this.showTierPrefixInTooltip = true,
  });

  @override
  Widget build(BuildContext context) {
    final neutralAsset =
        DotaItemHelper.resolveItemAsset(itemName: tier.neutralItem);
    final neutralDisplay =
        DotaItemHelper.getDisplayName(itemName: tier.neutralItem);
    final hasNeutral = neutralAsset != null;

    final buffAsset =
        DotaItemHelper.resolveItemAsset(itemName: tier.jungleBuff);
    final buffDisplay =
        DotaItemHelper.getDisplayName(itemName: tier.jungleBuff);
    final hasBuff = buffAsset != null;

    final String neutralTooltip = hasNeutral
        ? (showTierPrefixInTooltip
            ? 'Tier ${tier.tierNumber} • $neutralDisplay'
            : neutralDisplay)
        : 'Tier ${tier.tierNumber} • Sem Item Neutro';

    final String buffTooltip = hasBuff
        ? (showTierPrefixInTooltip
            ? 'Tier ${tier.tierNumber} • Buff de Jungle: $buffDisplay'
            : 'Buff de Jungle: $buffDisplay')
        : 'Tier ${tier.tierNumber} • Sem Buff de Jungle';

    final double mainSize = compact ? 27 : 30;
    final double buffSize = compact ? 17 : 19;

    return SizedBox(
      width: mainSize + (compact ? 8 : 10),
      height: mainSize + 3,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerLeft,
        children: [
          // 1. Círculo Principal: Item Neutro (30x30px)
          Tooltip(
            message: neutralTooltip,
            child: Container(
              width: mainSize,
              height: mainSize,
              decoration: BoxDecoration(
                color: hasNeutral
                    ? AppColors.canvasSurface
                    : AppColors.canvasSurface.withValues(alpha: 0.45),
                shape: BoxShape.circle,
                border: Border.all(
                  color: hasNeutral
                      ? (tier.isLatest
                          ? AppColors.dotaGoldLight
                          : AppColors.dotaGold.withValues(alpha: 0.85))
                      : AppColors.border.withValues(alpha: 0.4),
                  width: hasNeutral ? (tier.isLatest ? 1.2 : 0.95) : 0.7,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: hasNeutral
                  ? Image.asset(
                      neutralAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const _ItemPlaceholder(isCircle: true),
                    )
                  : const _ItemPlaceholder(isCircle: true),
            ),
          ),

          // 2. Insígnia no Canto Inferior Direito (deslocada mais para fora à direita para liberar a visão do item neutro)
          Positioned(
            right: -1,
            bottom: -2,
            child: Tooltip(
              message: buffTooltip,
              child: Container(
                width: buffSize,
                height: buffSize,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: hasBuff
                        ? AppColors.feedbackSuccess
                        : AppColors.border.withValues(alpha: 0.45),
                    width: hasBuff ? 1.15 : 0.7,
                  ),
                  boxShadow: hasBuff
                      ? [
                          BoxShadow(
                            color: AppColors.background.withValues(alpha: 0.9),
                            blurRadius: 2.5,
                            spreadRadius: 0.6,
                          ),
                        ]
                      : null,
                ),
                clipBehavior: Clip.antiAlias,
                child: hasBuff
                    ? Image.asset(
                        buffAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const _ItemPlaceholder(isCircle: true),
                      )
                    : Center(
                        child: Icon(
                          Icons.spa_rounded,
                          size: 9.0,
                          color: AppColors.textSecondary.withValues(alpha: 0.25),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Slot de upgrade permanente de Aghanim (Cetro / Shard - 28x28px).
class DotaAghanimSlot extends StatelessWidget {
  final String assetPath;
  final String tooltip;
  final bool isActive;
  final Color activeColor;

  const DotaAghanimSlot({
    super.key,
    required this.assetPath,
    required this.tooltip,
    required this.isActive,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.18)
              : AppColors.canvasSurface.withValues(alpha: 0.3),
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive
                ? activeColor
                : AppColors.border.withValues(alpha: 0.5),
            width: isActive ? 1.0 : 0.7,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(3.5),
          child: Opacity(
            opacity: isActive ? 1.0 : 0.25,
            child: Image.asset(
              assetPath,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Center(
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 13,
                  color: isActive ? activeColor : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Selos padronizados de Objetivos Globais do Time (Roshan Kills + Aegis Stolen com Snatch Hand).
class DotaObjectiveBadges extends StatelessWidget {
  final int roshanKills;
  final int aegisStolen;

  const DotaObjectiveBadges({
    super.key,
    required this.roshanKills,
    required this.aegisStolen,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Badge Roshan Kills
        Tooltip(
          message: 'Abates de Roshan pela equipe neste mapa',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.canvasSurface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: roshanKills > 0
                    ? AppColors.primaryNeon.withValues(alpha: 0.7)
                    : AppColors.border.withValues(alpha: 0.6),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Image.asset(
                    DotaItemHelper.roshanAsset,
                    width: 20,
                    height: 20,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.whatshot_rounded,
                      size: 15,
                      color: roshanKills > 0
                          ? AppColors.primaryNeon
                          : AppColors.textSecondary.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'ROSHAN: x$roshanKills',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: roshanKills > 0
                        ? AppColors.primaryNeon
                        : AppColors.textSecondary.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),

        // Badge Aegis Stolen (Ícone oficial do Aegis + mão de roubo/snatch sobreposta)
        Tooltip(
          message: 'Aegis da Imortalidade roubado do adversário (Snatch)',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.canvasSurface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: aegisStolen > 0
                    ? AppColors.dotaGold
                    : AppColors.border.withValues(alpha: 0.6),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: Image.asset(
                            DotaItemHelper.aegisAsset,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.shield_rounded,
                              size: 14,
                              color: aegisStolen > 0
                                  ? AppColors.dotaGoldLight
                                  : AppColors.textSecondary
                                      .withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: -3,
                        bottom: -3,
                        child: Container(
                          padding: const EdgeInsets.all(1.5),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: aegisStolen > 0
                                  ? AppColors.dotaGold
                                  : AppColors.border,
                              width: 0.6,
                            ),
                          ),
                          child: Icon(
                            Icons.front_hand_rounded,
                            size: 8.5,
                            color: aegisStolen > 0
                                ? AppColors.dotaGoldLight
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'AEGIS STOLEN: x$aegisStolen',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: aegisStolen > 0
                        ? AppColors.dotaGoldLight
                        : AppColors.textSecondary.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ItemPlaceholder extends StatelessWidget {
  final bool isCircle;

  const _ItemPlaceholder({required this.isCircle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: isCircle ? 6 : 7,
        height: isCircle ? 6 : 7,
        decoration: BoxDecoration(
          color: AppColors.surfaceHighlight.withValues(alpha: 0.35),
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircle ? null : BorderRadius.circular(1.5),
        ),
      ),
    );
  }
}

class _FallbackHeroBox extends StatelessWidget {
  const _FallbackHeroBox();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.shield_outlined,
        size: 14,
        color: AppColors.textSecondary,
      ),
    );
  }
}

