import 'package:flutter/material.dart';
import '../../features/tournaments/models/tournament_dto.dart';
import '../theme/theme.dart';
import 'app_badge.dart';

/// Banner da lateral esquerda do [AppTournamentCard] em proporção widescreen (ou topo no mobile).
class TournamentCardBanner extends StatelessWidget {
  final TournamentDto tournament;
  final double width;
  final bool isVertical;

  const TournamentCardBanner({
    super.key,
    required this.tournament,
    this.width = 300,
    this.isVertical = false,
  });

  @override
  Widget build(BuildContext context) {
    final isOpen = tournament.isRegistrationOpen;

    return Container(
      width: width,
      height: double.infinity,
      decoration: BoxDecoration(
        border: isVertical
            ? Border(
                bottom: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.70),
                  width: 1.0,
                ),
              )
            : Border(
                right: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.70),
                  width: 1.0,
                ),
              ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Imagem de capa do torneio ou fallback oficial da arena
          if (tournament.hasBanner) ...[
            Image.network(
              tournament.resolvedBannerUrl!,
              cacheWidth: 640,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildFallbackBanner(isOpen),
            ),
            // Vinheta escura sutil nas bordas para realce visual
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.20),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.40),
                  ],
                  stops: const [0.0, 0.50, 1.0],
                ),
              ),
            ),
          ] else
            _buildFallbackBanner(isOpen),
        ],
      ),
    );
  }

  Widget _buildFallbackBanner(bool isOpen) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          color: Colors.white,
          child: Image.asset(
            'assets/images/company_logo.jpg',
            fit: isVertical ? BoxFit.contain : BoxFit.cover,
            cacheWidth: 640,
            errorBuilder: (context, error, stackTrace) => Container(
              color: AppColors.canvasSurface,
            ),
          ),
        ),
        // Vinheta cinematográfica escura nas bordas para contraste e profundidade
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.15),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.35),
              ],
              stops: const [0.0, 0.50, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

/// Conteúdo estendido da lateral direita do [AppTournamentCard].
class TournamentCardContent extends StatelessWidget {
  final TournamentDto tournament;
  final bool isHovered;

  const TournamentCardContent({
    super.key,
    required this.tournament,
    required this.isHovered,
  });

  @override
  Widget build(BuildContext context) {
    final t = tournament;
    final isOpen = t.isRegistrationOpen;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. CONTEXTO DE IDENTIDADE & STATUS: Título + Calendário à esquerda | Sinalizador único no canto superior direito
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          t.name,
                          style: AppText.h3.copyWith(
                            fontSize: 18.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 11.5,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                t.periodSummaryLabel,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (t.hasChampion) ...[
                              const SizedBox(width: 8),
                              const Text(
                                '•',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.workspace_premium_rounded,
                                size: 13,
                                color: AppColors.dotaGold,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Campeão: ${t.championName}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.dotaGoldLight,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Sinalizador Único Oficial alinhado estritamente ao canto superior direito
                  AppBadge.dot(
                    label: t.bannerPrimaryStatusLabel,
                    customColor: t.bannerPrimaryStatusColor,
                    height: 24,
                    fontSize: 10.5,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 2. CONTEXTO TÉCNICO: Modalidade, Formato e Chaveamento agrupados com identidade visual coesa
              Padding(
                padding: const EdgeInsets.only(right: 36),
                child: Row(
                  children: [
                    Flexible(
                      child: _buildSpecChip(
                        icon: t.entryModeIcon,
                        iconColor: t.entryModeColor,
                        label: t.entryModeLabel,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: _buildSpecChip(
                        icon: Icons.alt_route_rounded,
                        iconColor: AppColors.primaryNeon,
                        label: t.formatLabel,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: _buildSpecChip(
                        icon: Icons.account_tree_rounded,
                        iconColor: AppColors.dotaGold,
                        label: t.playoffFormatLabel,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // 3. CONTEXTO DE OCUPAÇÃO: Barra de vagas à esquerda
              Padding(
                padding: const EdgeInsets.only(right: 36),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: _buildSlotsProgress(t, isOpen),
                ),
              ),
            ],
          ),

          // Seta padrão de navegação centralizada na vertical no extremo direito (sem deslocar nenhum elemento)
          Align(
            alignment: Alignment.centerRight,
            child: buildCtaButtonStatic(t, isHovered: isHovered),
          ),
        ],
      ),
    );
  }

  static Widget buildCtaButtonStatic(
    TournamentDto t, {
    required bool isHovered,
    double size = 24.0,
  }) {
    final bool isOpen = t.isRegistrationOpen;
    final Color hoverColor = isOpen ? AppColors.dotaGoldLight : AppColors.primaryNeon;

    return Tooltip(
      message: t.actionCtaLabel,
      child: Icon(
        Icons.chevron_right_rounded,
        size: size,
        color: isHovered
            ? hoverColor
            : AppColors.textSecondary.withValues(alpha: 0.70),
      ),
    );
  }

  Widget _buildSpecChip({
    required IconData icon,
    required Color iconColor,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.canvasSurface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.65),
          width: 0.85,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11.5, color: iconColor),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11.0,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotsProgress(TournamentDto t, bool isOpen) {
    final progressColor = isOpen ? AppColors.dotaGold : AppColors.primaryNeon;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.groups_rounded,
                  size: 13,
                  color: isOpen ? AppColors.dotaGold : AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  t.teamsProgressLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Spacer(),
            Flexible(
              child: Text(
                t.slotsSummaryLabel,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: t.isFull
                      ? AppColors.textSecondary
                      : (isOpen ? AppColors.dotaGoldLight : AppColors.textSecondary),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: t.occupancyProgress,
            minHeight: 3.5,
            backgroundColor: AppColors.surfaceHighlight,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),
      ],
    );
  }

}

/// Conteúdo adaptado para telas mobile e estreitas (< 620px), eliminando todo e qualquer overflow.
class TournamentCardMobileContent extends StatelessWidget {
  final TournamentDto tournament;
  final bool isHovered;

  const TournamentCardMobileContent({
    super.key,
    required this.tournament,
    required this.isHovered,
  });

  @override
  Widget build(BuildContext context) {
    final t = tournament;
    final isOpen = t.isRegistrationOpen;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Linha 1: Título à esquerda | Sinalizador Único no Canto Superior Direito
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  t.name,
                  style: AppText.h3.copyWith(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              AppBadge.dot(
                label: t.bannerPrimaryStatusLabel,
                customColor: t.bannerPrimaryStatusColor,
                height: 22,
                fontSize: 9.5,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Linha 2: Contexto Técnico (Modalidade + Formato + Chaveamento com quebra livre sem engolir texto)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildChip(
                icon: t.entryModeIcon,
                color: t.entryModeColor,
                label: t.entryModeLabel,
              ),
              _buildChip(
                icon: Icons.alt_route_rounded,
                color: AppColors.primaryNeon,
                label: t.formatLabel,
              ),
              _buildChip(
                icon: Icons.account_tree_rounded,
                color: AppColors.dotaGold,
                label: t.playoffFormatLabel,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Linha 3: Vagas + Seta padrão de navegação
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.groups_rounded,
                          size: 12,
                          color: isOpen ? AppColors.dotaGold : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            t.teamsProgressLabel,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.slotsSummaryLabel,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: isOpen ? AppColors.dotaGoldLight : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              TournamentCardContent.buildCtaButtonStatic(
                t,
                isHovered: isHovered,
                size: 20.0,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
      decoration: BoxDecoration(
        color: AppColors.canvasSurface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.65),
          width: 0.85,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10.5, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10.0,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
