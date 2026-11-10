import 'package:flutter/material.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/theme/theme.dart';
import '../../models/draft_player_dto.dart';

/// Slot 1 do Card de Equipe: Capitão Definido (ou estado de substituição/vazio).
class DraftCaptainSlotRow extends StatelessWidget {
  final DraftPlayerDto? captain;
  final String? substitutingPlayerId;
  final bool canManage;
  final ValueChanged<DraftPlayerDto>? onStartSubstitution;
  final VoidCallback? onCancelSubstitution;

  const DraftCaptainSlotRow({
    super.key,
    required this.captain,
    required this.substitutingPlayerId,
    required this.canManage,
    this.onStartSubstitution,
    this.onCancelSubstitution,
  });

  @override
  Widget build(BuildContext context) {
    final cap = captain;
    if (cap == null) {
      return Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.5),
            width: 0.8,
          ),
        ),
        child: const Row(
          children: [
            Icon(Icons.shield_outlined, size: 16, color: AppColors.textSecondary),
            SizedBox(width: 8),
            Text(
              'Capitão não definido',
              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (substitutingPlayerId == cap.id) {
      return DraftSubstitutionActiveSlotRow(
        isCaptain: true,
        slotBadge: 'CAPITÃO',
        playerName: cap.name,
        onCancelSubstitution: onCancelSubstitution,
      );
    }

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.dotaGold.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.dotaGold.withValues(alpha: 0.45),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.dotaGold.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: AppColors.dotaGold.withValues(alpha: 0.7),
                width: 0.6,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded, size: 11, color: AppColors.dotaGold),
                SizedBox(width: 3),
                Text(
                  'CAPITÃO',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                    color: AppColors.dotaGold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AppAvatar(
            imageUrl: cap.avatarUrl,
            name: cap.name,
            radius: 13,
          ),
          const SizedBox(width: 8),
          DotaRankMedal(
            rankTier: cap.rankTier?.toString() ?? '0',
            size: 22,
            showBadgeNumber: false,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              cap.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 6),
          DotaRolesDisplay.fromStrings(
            rawRoles: cap.roles,
            preferredRoleKey: cap.preferredRole,
            boxWidth: 18.0,
            boxHeight: 18.0,
            iconSize: 12.0,
            spacing: 3.0,
            showBoxes: true,
          ),
          if (canManage &&
              onStartSubstitution != null &&
              substitutingPlayerId == null)
            AppIconButton(
              icon: Icons.swap_horiz_rounded,
              tooltip: 'Substituir Capitão',
              variant: AppIconButtonVariant.ghost,
              size: AppIconButtonSize.compact,
              onPressed: () => onStartSubstitution!(cap),
            ),
        ],
      ),
    );
  }
}

/// Slot preenchido de Titular (#2 a #5) ou Reserva (#6 a #7).
class DraftFilledPlayerSlotRow extends StatelessWidget {
  final DraftPlayerDto player;
  final int slotIndex;
  final bool isReserve;
  final String? substitutingPlayerId;
  final bool canManage;
  final ValueChanged<DraftPlayerDto>? onStartSubstitution;
  final VoidCallback? onCancelSubstitution;
  final ValueChanged<DraftPlayerDto>? onRemoveReserve;

  const DraftFilledPlayerSlotRow({
    super.key,
    required this.player,
    required this.slotIndex,
    this.isReserve = false,
    required this.substitutingPlayerId,
    required this.canManage,
    this.onStartSubstitution,
    this.onCancelSubstitution,
    this.onRemoveReserve,
  });

  @override
  Widget build(BuildContext context) {
    if (substitutingPlayerId == player.id) {
      return DraftSubstitutionActiveSlotRow(
        slotBadge: '#$slotIndex',
        playerName: player.name,
        onCancelSubstitution: onCancelSubstitution,
      );
    }

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.canvasSurface.withValues(alpha: isReserve ? 0.50 : 0.60),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.border.withValues(alpha: isReserve ? 0.55 : 0.60),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: isReserve
                  ? AppColors.dotaGold.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: isReserve
                    ? AppColors.dotaGold.withValues(alpha: 0.5)
                    : AppColors.border.withValues(alpha: 0.6),
                width: 0.6,
              ),
            ),
            child: Text(
              '#$slotIndex',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: isReserve ? AppColors.dotaGoldLight : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          AppAvatar(
            imageUrl: player.avatarUrl,
            name: player.name,
            radius: 13,
          ),
          const SizedBox(width: 8),
          DotaRankMedal(
            rankTier: player.rankTier?.toString() ?? '0',
            size: 22,
            showBadgeNumber: false,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              player.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 6),
          DotaRolesDisplay.fromStrings(
            rawRoles: player.roles,
            preferredRoleKey: player.preferredRole,
            boxWidth: 18.0,
            boxHeight: 18.0,
            iconSize: 12.0,
            spacing: 3.0,
            showBoxes: true,
          ),
          if (canManage && substitutingPlayerId == null) ...[
            if (onStartSubstitution != null) ...[
              if (isReserve) const SizedBox(width: 4),
              AppIconButton(
                icon: Icons.swap_horiz_rounded,
                tooltip: isReserve ? 'Substituir Reserva' : 'Substituir Titular',
                variant: AppIconButtonVariant.ghost,
                size: AppIconButtonSize.compact,
                onPressed: () => onStartSubstitution!(player),
              ),
            ],
            if (isReserve && onRemoveReserve != null) ...[
              const SizedBox(width: 2),
              AppIconButton(
                icon: Icons.close_rounded,
                tooltip: 'Remover Reserva',
                variant: AppIconButtonVariant.danger,
                size: AppIconButtonSize.compact,
                onPressed: () => onRemoveReserve!(player),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Slot vazio (Placeholder) para vaga de Titular (#2 a #5) ou Reserva (#6 a #7).
class DraftPlaceholderSlotRow extends StatelessWidget {
  final int slotIndex;
  final int? reserveIndex;
  final bool isHighlightedNext;
  final bool isReserve;

  const DraftPlaceholderSlotRow({
    super.key,
    required this.slotIndex,
    this.reserveIndex,
    required this.isHighlightedNext,
    this.isReserve = false,
  });

  @override
  Widget build(BuildContext context) {
    const Color activeAccent = AppColors.dotaGold;
    final String labelText = isReserve
        ? (isHighlightedNext
            ? 'Próximo Reserva (Selecione no Bucket [+])'
            : 'Vaga Reserva #${reserveIndex ?? 1} — (Opcional)')
        : (isHighlightedNext
            ? 'Próximo Pick (Selecione no Bucket [+])'
            : 'Vaga Titular #$slotIndex — Aguardando Pick...');

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isHighlightedNext
            ? activeAccent.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: isReserve ? 0.12 : 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isHighlightedNext
              ? activeAccent.withValues(alpha: 0.55)
              : AppColors.border.withValues(alpha: isReserve ? 0.25 : 0.35),
          width: isHighlightedNext ? 1.1 : 0.8,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: isHighlightedNext
                  ? activeAccent.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: isHighlightedNext
                    ? activeAccent.withValues(alpha: 0.5)
                    : AppColors.border.withValues(alpha: 0.4),
                width: 0.6,
              ),
            ),
            child: Text(
              '#$slotIndex',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: isHighlightedNext ? activeAccent : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isHighlightedNext
                  ? activeAccent.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.04),
              border: Border.all(
                color: isHighlightedNext
                    ? activeAccent.withValues(alpha: 0.4)
                    : AppColors.border.withValues(alpha: isReserve ? 0.25 : 0.4),
                width: 0.8,
              ),
            ),
            child: Icon(
              isHighlightedNext
                  ? Icons.add_rounded
                  : (isReserve
                      ? Icons.shield_outlined
                      : Icons.person_outline_rounded),
              size: isReserve ? 13 : 14,
              color: isHighlightedNext
                  ? activeAccent
                  : AppColors.textSecondary
                      .withValues(alpha: isReserve ? 0.45 : 0.6),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              labelText,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight:
                    isHighlightedNext ? FontWeight.w700 : FontWeight.w500,
                color: isHighlightedNext
                    ? AppColors.dotaGoldLight
                    : AppColors.textSecondary
                        .withValues(alpha: isReserve ? 0.45 : 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Slot em modo de substituição ativa com feedback de hover.
class DraftSubstitutionActiveSlotRow extends StatefulWidget {
  final bool isCaptain;
  final String slotBadge;
  final String playerName;
  final VoidCallback? onCancelSubstitution;

  const DraftSubstitutionActiveSlotRow({
    super.key,
    this.isCaptain = false,
    required this.slotBadge,
    required this.playerName,
    this.onCancelSubstitution,
  });

  @override
  State<DraftSubstitutionActiveSlotRow> createState() =>
      _DraftSubstitutionActiveSlotRowState();
}

class _DraftSubstitutionActiveSlotRowState
    extends State<DraftSubstitutionActiveSlotRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final String displayText = _isHovered
        ? 'Substituindo: ${widget.playerName}'
        : 'Selecione no Bucket [+]';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message:
            'Substituindo ${widget.playerName} — Escolha o substituto no Bucket à direita.',
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _isHovered
                ? AppColors.primaryNeon.withValues(alpha: 0.14)
                : AppColors.primaryNeon.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _isHovered
                  ? AppColors.primaryNeon
                  : AppColors.primaryNeon.withValues(alpha: 0.65),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryNeon.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: AppColors.primaryNeon.withValues(alpha: 0.6),
                    width: 0.6,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.isCaptain) ...[
                      const Icon(
                        Icons.star_rounded,
                        size: 11,
                        color: AppColors.primaryNeon,
                      ),
                      const SizedBox(width: 3),
                    ],
                    Text(
                      widget.slotBadge,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: widget.isCaptain
                            ? FontWeight.w900
                            : FontWeight.w700,
                        letterSpacing: widget.isCaptain ? 0.4 : 0.0,
                        color: AppColors.primaryNeon,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryNeon.withValues(alpha: 0.16),
                  border: Border.all(
                    color: AppColors.primaryNeon.withValues(alpha: 0.5),
                    width: 0.8,
                  ),
                ),
                child: const Icon(
                  Icons.swap_horiz_rounded,
                  size: 15,
                  color: AppColors.primaryNeon,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  displayText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: _isHovered ? AppColors.dotaGoldLight : Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (widget.onCancelSubstitution != null)
                AppButton(
                  text: 'CANCELAR',
                  variant: AppButtonVariant.danger,
                  size: AppButtonSize.compact,
                  onPressed: widget.onCancelSubstitution,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modal dedicado para renomeação de equipe com descarte seguro do `TextEditingController`.
class DraftTeamRenameDialog extends StatefulWidget {
  final String teamId;
  final String initialName;
  final Future<String?> Function(String teamId, String newName) onRenameTeam;

  const DraftTeamRenameDialog({
    super.key,
    required this.teamId,
    required this.initialName,
    required this.onRenameTeam,
  });

  static Future<void> show(
    BuildContext context, {
    required String teamId,
    required String initialName,
    required Future<String?> Function(String teamId, String newName)
        onRenameTeam,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => DraftTeamRenameDialog(
        teamId: teamId,
        initialName: initialName,
        onRenameTeam: onRenameTeam,
      ),
    );
  }

  @override
  State<DraftTeamRenameDialog> createState() => _DraftTeamRenameDialogState();
}

class _DraftTeamRenameDialogState extends State<DraftTeamRenameDialog> {
  late final TextEditingController _controller;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final newName = _controller.text.trim();
    if (newName.isEmpty) {
      AppFeedback.showWarning(
        context,
        message: 'Informe um nome para a equipe.',
      );
      return;
    }
    if (newName == widget.initialName) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isSaving = true);
    final error = await widget.onRenameTeam(widget.teamId, newName);
    if (!mounted) return;

    if (error != null) {
      setState(() => _isSaving = false);
      AppFeedback.showError(context, message: error);
    } else {
      Navigator.of(context).pop();
      AppFeedback.showSuccess(
        context,
        message: 'Equipe renomeada para "$newName" com sucesso!',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'TEAM MANAGEMENT',
      maxWidth: 390,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Altere o nome oficial da equipe. O novo nome será sincronizado em tempo real na Sala de Draft e em todo o campeonato.',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          AppInput(
            controller: _controller,
            labelText: 'Nome da Equipe',
            hintText: 'Ex: Team Liquid, LGD Gaming...',
            readOnly: _isSaving,
          ),
        ],
      ),
      actions: [
        AppButton(
          text: 'CANCELAR',
          variant: AppButtonVariant.secondary,
          size: AppButtonSize.medium,
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
        ),
        AppButton(
          text: 'SALVAR NOME',
          variant: AppButtonVariant.primary,
          size: AppButtonSize.medium,
          isLoading: _isSaving,
          onPressed: _isSaving ? null : _handleSave,
        ),
      ],
    );
  }
}
