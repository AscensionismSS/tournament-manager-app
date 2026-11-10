import 'package:flutter/material.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/theme/theme.dart';
import '../../models/draft_player_dto.dart';
import '../../models/draft_team_dto.dart';

/// Card individual de uma equipe na Fase 1 do Draft (SRP & Dumb UI).
/// Segue a fidelidade visual exata do [AppPlayerCard] (marca d'água, gradiente de profundidade,
/// medalhas de patente e ícones de funções), sem os botões de redes externas (Steam/OpenDota).
/// No hover, exibe ações rápidas de [SUBSTITUIR] e [REMOVER].
/// Quando em modo de substituição, trava a equipe como alvo ativo e bloqueia os outros cards.
class DraftTeamCaptainCard extends StatefulWidget {
  final DraftTeamDto team;
  final bool isSelected;
  final bool isReplacing;
  final bool isLockedByAnother;
  final bool canManage;
  final VoidCallback onSelectTeam;
  final VoidCallback onRemoveCaptain;
  final VoidCallback onStartReplacing;
  final VoidCallback onCancelReplacing;

  const DraftTeamCaptainCard({
    super.key,
    required this.team,
    required this.isSelected,
    this.isReplacing = false,
    this.isLockedByAnother = false,
    required this.canManage,
    required this.onSelectTeam,
    required this.onRemoveCaptain,
    required this.onStartReplacing,
    required this.onCancelReplacing,
  });

  @override
  State<DraftTeamCaptainCard> createState() => _DraftTeamCaptainCardState();
}

class _DraftTeamCaptainCardState extends State<DraftTeamCaptainCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final DraftPlayerDto? captain = widget.team.captainPlayer;
    final bool hasCaptain = captain != null;
    final bool canInteract = widget.canManage && !widget.isLockedByAnother;

    // Definição das bordas e iluminação conforme o estado do card
    final Color borderColor;
    final double borderWidth;
    List<BoxShadow>? shadows;

    if (widget.isReplacing) {
      borderColor = AppColors.dotaGoldLight;
      borderWidth = 1.8;
      shadows = [
        BoxShadow(
          color: AppColors.dotaGold.withValues(alpha: 0.35),
          blurRadius: 14,
          spreadRadius: 1,
        ),
      ];
    } else if (widget.isSelected && !hasCaptain) {
      borderColor = AppColors.dotaGold;
      borderWidth = 1.6;
      shadows = [
        BoxShadow(
          color: AppColors.dotaGold.withValues(alpha: 0.25),
          blurRadius: 10,
        ),
      ];
    } else if (hasCaptain) {
      borderColor = AppColors.dotaGold.withValues(alpha: 0.45);
      borderWidth = 0.9;
    } else {
      borderColor = AppColors.border;
      borderWidth = 0.85;
    }

    final cardContent = AnimatedOpacity(
      duration: const Duration(milliseconds: 140),
      opacity: widget.isLockedByAnother ? 0.35 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: widget.isReplacing
              ? AppColors.dotaGold.withValues(alpha: 0.10)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: shadows ??
              [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // 1. Marca d'água translúcida oficial (fidelidade com AppPlayerCard)
            Positioned.fill(
              child: Opacity(
                opacity: 0.07,
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),

            // 2. Gradiente suave de profundidade
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppColors.surface.withValues(alpha: 0.94),
                      AppColors.surface.withValues(alpha: 0.88),
                      AppColors.surface.withValues(alpha: 0.95),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Estrutura do Card: Faixa Superior de Cabeçalho + Perfil do Capitão
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Faixa Superior (estilo _PlayerCardHeaderStrip)
                _buildHeaderStrip(captain),

                // Seção Principal (estilo _PlayerCardProfileSection)
                Expanded(
                  child: hasCaptain
                      ? _buildCaptainProfileSection(captain)
                      : _buildEmptySlotSection(),
                ),

                // Rodapé de Ação quando em Modo de Substituição Ativo
                if (widget.isReplacing) _buildReplacingBanner(),
              ],
            ),

            // 4. Overlay de Hover com Ações Rápidas: [SUBSTITUIR] e [REMOVER]
            if (_isHovered &&
                hasCaptain &&
                canInteract &&
                !widget.isReplacing)
              Positioned.fill(
                child: _buildHoverActionsOverlay(),
              ),
          ],
        ),
      ),
    );

    if (!canInteract || widget.isReplacing) {
      return cardContent;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: hasCaptain ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: hasCaptain ? null : widget.onSelectTeam,
        behavior: HitTestBehavior.opaque,
        child: cardContent,
      ),
    );
  }

  /// Bloco 1: Faixa Superior idêntica ao Membros (_PlayerCardHeaderStrip)
  Widget _buildHeaderStrip(DraftPlayerDto? captain) {
    final bool isUnranked =
        captain?.rankTier == null || captain!.rankTier! <= 0;
    final List<String> effectiveRoles = captain != null
        ? (captain.roles.isNotEmpty
            ? captain.roles
            : (captain.preferredRole != null
                ? [captain.preferredRole!]
                : const []))
        : const [];

    return Container(
      height: 38,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.dotaGold.withValues(alpha: isUnranked ? 0.06 : 0.12),
        border: Border(
          bottom: BorderSide(
            color: isUnranked
                ? AppColors.border
                : AppColors.dotaGold.withValues(alpha: 0.38),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Lado Esquerdo: Medalha de Rank + Nome do Rank + Divisória + Símbolos das Funções (Idêntico ao Membros / AppPlayerCard)
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                DotaRankMedal(
                  rankTier: captain?.rankTier?.toString() ?? '',
                  size: 22,
                  showBadgeNumber: false,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    captain != null
                        ? captain.rankDetail.toUpperCase()
                        : 'SEM CAPITÃO',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: (captain == null || isUnranked)
                          ? AppColors.textSecondary
                          : AppColors.dotaGoldLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (effectiveRoles.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Container(
                    width: 1.0,
                    height: 16,
                    color: AppColors.dotaGold.withValues(alpha: 0.35),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: DotaRolesDisplay.fromStrings(
                        rawRoles: effectiveRoles,
                        preferredRoleKey: captain?.preferredRole,
                        boxWidth: 22.0,
                        boxHeight: 22.0,
                        iconSize: 14.0,
                        spacing: 5.0,
                        showBoxes: true,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Lado Direito: Escudo + Nome da Equipe
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.shield_rounded,
                size: 15,
                color: AppColors.dotaGold,
              ),
              const SizedBox(width: 6),
              Text(
                widget.team.name.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Bloco 2: Seção do Capitão idêntica ao Membros (_PlayerCardProfileSection)
  Widget _buildCaptainProfileSection(DraftPlayerDto captain) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar elegante (48px) com contorno dourado
          AppAvatar(
            radius: 24,
            name: captain.name,
            imageUrl: captain.avatarUrl,
            borderWidth: 1.5,
            borderColor: AppColors.dotaGold,
          ),
          const SizedBox(width: 12),

          // Informações do Jogador
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Nickname
                Text(
                  captain.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: AppColors.dotaGold,
                  ),
                ),
                const SizedBox(height: 4),

                // Badge Oficial de Capitão com Estrela
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.dotaGold.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AppColors.dotaGold,
                      width: 0.8,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.stars_rounded,
                        color: AppColors.dotaGold,
                        size: 11,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'CAPITÃO',
                        style: TextStyle(
                          color: AppColors.dotaGold,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
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

  /// Slot vazio para equipes que ainda aguardam definição de capitão
  Widget _buildEmptySlotSection() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.isSelected
                  ? Icons.touch_app_rounded
                  : Icons.person_add_alt_1_rounded,
              size: 22,
              color: widget.isSelected
                  ? AppColors.dotaGoldLight
                  : AppColors.textSecondary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 4),
            Text(
              widget.isSelected
                  ? 'Clique no [+] do bucket para atribuir'
                  : 'Aguardando seleção de capitão',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    widget.isSelected ? FontWeight.w900 : FontWeight.w600,
                color: widget.isSelected
                    ? AppColors.dotaGoldLight
                    : AppColors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Banner luminoso exibido quando o card está travado no modo de substituição
  Widget _buildReplacingBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.dotaGold.withValues(alpha: 0.18),
        border: const Border(
          top: BorderSide(color: AppColors.dotaGold, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.swap_horiz_rounded,
            size: 14,
            color: AppColors.dotaGoldLight,
          ),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'SELECIONE O NOVO NO BUCKET [+]...',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
                color: AppColors.dotaGoldLight,
              ),
            ),
          ),
          InkWell(
            onTap: widget.onCancelReplacing,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
              decoration: BoxDecoration(
                color: AppColors.feedbackError.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppColors.feedbackError.withValues(alpha: 0.5),
                  width: 0.8,
                ),
              ),
              child: const Text(
                'CANCELAR',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                  color: AppColors.feedbackError,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Overlay que surge no hover permitindo Substituir ou Remover o capitão (Layout meio a meio canônico)
  Widget _buildHoverActionsOverlay() {
    return AppDualActionOverlay(
      borderRadius: BorderRadius.circular(10),
      leftLabel: 'SUBSTITUIR',
      leftIcon: Icons.swap_horiz_rounded,
      leftColor: AppColors.dotaGoldLight,
      onLeftTap: () {
        setState(() => _isHovered = false);
        widget.onStartReplacing();
      },
      rightLabel: 'REMOVER',
      rightIcon: Icons.close_rounded,
      rightColor: AppColors.feedbackError,
      onRightTap: () {
        setState(() => _isHovered = false);
        widget.onRemoveCaptain();
      },
    );
  }
}
