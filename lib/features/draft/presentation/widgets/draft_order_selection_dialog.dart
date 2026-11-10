import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/theme/theme.dart';
import '../../models/draft_state_snapshot_dto.dart';
import '../../models/draft_team_dto.dart';

enum DraftOrderMode {
  /// Segue a ordem em que os capitães foram selecionados / montados no draft
  draftPick,

  /// Realiza um sorteio aleatório para definir a ordem das equipes
  randomized,
}

/// Modal oficial ampliado para definir a Ordem de Escolha do Snake Draft (Fase 2).
/// Permite ao administrador escolher entre a ordem de pick dos capitães ou sorteio aleatório,
/// exibindo a visualização da ordem detalhada das equipes com capitão, medalha e funções.
class DraftOrderSelectionDialog extends StatefulWidget {
  final DraftStateSnapshotDto snapshot;
  final Future<String?> Function({
    required int orderType,
    List<String>? manualOrderIds,
  }) onConfirm;

  const DraftOrderSelectionDialog({
    super.key,
    required this.snapshot,
    required this.onConfirm,
  });

  static Future<bool?> show(
    BuildContext context, {
    required DraftStateSnapshotDto snapshot,
    required Future<String?> Function({
      required int orderType,
      List<String>? manualOrderIds,
    }) onConfirm,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AppDialog(
        title: 'DEFINIR ORDEM DO SNAKE DRAFT',
        icon: Icons.format_list_numbered_rounded,
        iconColor: AppColors.dotaGold,
        maxWidth: 640,
        content: DraftOrderSelectionDialog(
          snapshot: snapshot,
          onConfirm: onConfirm,
        ),
      ),
    );
  }

  @override
  State<DraftOrderSelectionDialog> createState() =>
      _DraftOrderSelectionDialogState();
}

class _DraftOrderSelectionDialogState extends State<DraftOrderSelectionDialog> {
  DraftOrderMode _selectedMode = DraftOrderMode.draftPick;
  late List<DraftTeamDto> _shuffledTeams;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _generateRandomizedList();
  }

  void _generateRandomizedList() {
    final list = List<DraftTeamDto>.from(widget.snapshot.teams);
    list.shuffle(Random());
    _shuffledTeams = list;
  }

  List<DraftTeamDto> get _currentOrderTeams {
    if (_selectedMode == DraftOrderMode.draftPick) {
      return widget.snapshot.teams;
    }
    return _shuffledTeams;
  }

  Future<void> _handleConfirm() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final orderType = _selectedMode == DraftOrderMode.draftPick ? 1 : 2;
    final manualOrderIds = _selectedMode == DraftOrderMode.draftPick
        ? widget.snapshot.teams.map((t) => t.id).toList()
        : null;

    final error = await widget.onConfirm(
      orderType: orderType,
      manualOrderIds: manualOrderIds,
    );

    if (!mounted) return;

    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isSubmitting = false;
        _errorMessage = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTeams = _currentOrderTeams;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Todas as equipes possuem capitão definido. Escolha como será estabelecida a ordem de escolha dos titulares no Snake Draft:',
          style: TextStyle(
            fontSize: 12.5,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),

        // 1. Seleção entre as Duas Opções (Cards Interativos)
        Row(
          children: [
            Expanded(
              child: _buildModeOptionCard(
                mode: DraftOrderMode.draftPick,
                icon: Icons.playlist_play_rounded,
                title: 'COMO FOI NO PICK',
                subtitle: 'Mantém a ordem de seleção dos capitães',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildModeOptionCard(
                mode: DraftOrderMode.randomized,
                icon: Icons.casino_rounded,
                title: 'SORTEIO ALEATÓRIO',
                subtitle: 'Sorteia a ordem das equipes no Snake',
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // 2. Cabeçalho da Lista de Ordem com Ação de Reembaralhar (se sorteio)
        SizedBox(
          height: 32,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.format_list_numbered_rounded,
                    size: 14,
                    color: AppColors.dotaGold,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _selectedMode == DraftOrderMode.draftPick
                        ? 'ORDEM DO DRAFT (PICK DOS CAPITÃES)'
                        : 'ORDEM DO DRAFT (SORTEIO ALEATÓRIO)',
                    style: const TextStyle(
                      fontFamily: 'Oswald',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: AppColors.dotaGoldLight,
                    ),
                  ),
                ],
              ),
              if (_selectedMode == DraftOrderMode.randomized)
                InkWell(
                  onTap: () => setState(() => _generateRandomizedList()),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.dotaGold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: AppColors.dotaGold.withValues(alpha: 0.35),
                        width: 0.8,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          size: 13,
                          color: AppColors.dotaGold,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'NOVO SORTEIO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                            color: AppColors.dotaGold,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // 3. Container da Ordem das Equipes com Rolagem Suave
        Container(
          constraints: const BoxConstraints(maxHeight: 280),
          decoration: BoxDecoration(
            color: AppColors.canvasSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.6),
              width: 1.0,
            ),
          ),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            shrinkWrap: true,
            itemCount: currentTeams.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: AppColors.border.withValues(alpha: 0.3),
            ),
            itemBuilder: (context, index) {
              final team = currentTeams[index];
              return _buildTeamOrderRow(index + 1, team);
            },
          ),
        ),

        // 4. Feedback de Erro Reservado
        if (_errorMessage != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.feedbackError.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppColors.feedbackError.withValues(alpha: 0.5),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 14,
                  color: AppColors.feedbackError,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.feedbackError,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 18),

        // 5. Rodapé de Ações
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AppButton(
              text: 'VOLTAR',
              size: AppButtonSize.small,
              variant: AppButtonVariant.ghost,
              onPressed: () => Navigator.of(context).pop(false),
            ),
            const SizedBox(width: 8),
            AppButton(
              text: 'CONFIRMAR ORDEM E INICIAR DRAFT',
              icon: Icons.play_arrow_rounded,
              size: AppButtonSize.medium,
              variant: AppButtonVariant.primary,
              isLoading: _isSubmitting,
              onPressed: _handleConfirm,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModeOptionCard({
    required DraftOrderMode mode,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedMode == mode;

    return InkWell(
      onTap: () => setState(() => _selectedMode = mode),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 62,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.dotaGold.withValues(alpha: 0.12)
              : AppColors.surfaceHighlight.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.dotaGold
                : AppColors.border.withValues(alpha: 0.6),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.dotaGold.withValues(alpha: 0.20)
                    : AppColors.canvasSurface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.dotaGold
                      : AppColors.border.withValues(alpha: 0.5),
                  width: 0.8,
                ),
              ),
              child: Icon(
                icon,
                size: 16,
                color:
                    isSelected ? AppColors.dotaGoldLight : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Oswald',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected
                          ? AppColors.dotaGoldLight.withValues(alpha: 0.85)
                          : AppColors.textSecondary.withValues(alpha: 0.65),
                      height: 1.15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 16,
              color: isSelected ? AppColors.dotaGold : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamOrderRow(int position, DraftTeamDto team) {
    final captain = team.captainPlayer;

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Posição no Snake Draft (1º, 2º, 3º...)
          Container(
            width: 28,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.dotaGold.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppColors.dotaGold.withValues(alpha: 0.4),
                width: 0.8,
              ),
            ),
            child: Text(
              '$positionº',
              style: const TextStyle(
                fontFamily: 'Oswald',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.dotaGoldLight,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Nome do Time com Ícone de Escudo
          const Icon(Icons.shield_rounded, size: 12, color: AppColors.dotaGold),
          const SizedBox(width: 4),
          SizedBox(
            width: 86,
            child: Text(
              team.name,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Divisória sutil
          Container(
            width: 1,
            height: 14,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: AppColors.border.withValues(alpha: 0.5),
          ),

          // Avatar do Capitão
          ClipOval(
            child: SizedBox(
              width: 22,
              height: 22,
              child: captain?.avatarUrl != null &&
                      captain!.avatarUrl!.trim().isNotEmpty
                  ? Image.network(
                      captain.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person_rounded,
                        size: 14,
                        color: AppColors.dotaGold,
                      ),
                    )
                  : const Icon(
                      Icons.person_rounded,
                      size: 14,
                      color: AppColors.dotaGold,
                    ),
            ),
          ),
          const SizedBox(width: 6),

          // Nick do Capitão
          Expanded(
            child: Text(
              captain?.name ?? 'Capitão não definido',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Apenas Medalha Dota 2 do Capitão (sem funções / role icons)
          if (captain != null)
            DotaRankMedal(
              rankTier: captain.rankTier?.toString() ?? '',
              size: 20,
              showBadgeNumber: false,
            ),
        ],
      ),
    );
  }
}
