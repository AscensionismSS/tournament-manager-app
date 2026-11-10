import 'package:flutter/material.dart';
import '../../features/tournaments/models/tournament_dto.dart';
import '../theme/theme.dart';
import 'app_badge.dart';

/// Cabeçalho visual do [AppTournamentCard] com Banner 16:9 e Badges de Status da Inscrição e Fase.
class TournamentCardBannerHeader extends StatelessWidget {
  final TournamentDto tournament;

  const TournamentCardBannerHeader({
    super.key,
    required this.tournament,
  });

  @override
  Widget build(BuildContext context) {
    final isOpen = tournament.isRegistrationOpen;

    return SizedBox(
      height: 108,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (tournament.hasBanner)
            Image.network(
              tournament.resolvedBannerUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildFallbackBanner(isOpen),
            )
          else
            _buildFallbackBanner(isOpen),

          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.background.withValues(alpha: 0.72),
                  AppColors.background.withValues(alpha: 0.35),
                  AppColors.surface.withValues(alpha: 0.96),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: AppBadge(
                    label: tournament.registrationStatusLabel,
                    customColor: isOpen ? AppColors.dotaGold : AppColors.textSecondary,
                    icon: tournament.registrationStatusIcon,
                  ),
                ),
                if (!isOpen) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.background.withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: AppBadge(
                        label: tournament.status.label,
                        customColor: tournament.status.color,
                        icon: tournament.status.icon,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackBanner(bool isOpen) {
    return Container(
      color: AppColors.surfaceHighlight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/company_logo.jpg',
            opacity: const AlwaysStoppedAnimation(0.12),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
          ),
          Center(
            child: Icon(
              tournament.hasChampion
                  ? Icons.workspace_premium_rounded
                  : Icons.emoji_events_rounded,
              size: 40,
              color: (isOpen ? AppColors.dotaGold : AppColors.primaryNeon)
                  .withValues(alpha: 0.28),
            ),
          ),
        ],
      ),
    );
  }
}

/// Linha de especificações técnicas do campeonato (Formato, Chaveamento e Modalidade).
class TournamentCardSpecsRow extends StatelessWidget {
  final TournamentDto tournament;

  const TournamentCardSpecsRow({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildSpecBox(
            icon: Icons.alt_route_rounded,
            iconColor: AppColors.primaryNeon,
            label: 'FORMATO',
            value: tournament.formatLabel,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSpecBox(
            icon: Icons.account_tree_rounded,
            iconColor: AppColors.dotaGold,
            label: 'CHAVEAMENTO',
            value: tournament.playoffFormatLabel,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSpecBox(
            icon: tournament.entryModeIcon,
            iconColor: tournament.entryModeColor,
            label: 'MODALIDADE',
            value: tournament.entryModeLabel,
          ),
        ),
      ],
    );
  }

  Widget _buildSpecBox({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.75),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: iconColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Rodapé clicável do [AppTournamentCard] com indicador de inscrição e botão de navegação.
class TournamentCardFooter extends StatelessWidget {
  final TournamentDto tournament;
  final bool isHovered;

  const TournamentCardFooter({
    super.key,
    required this.tournament,
    required this.isHovered,
  });

  @override
  Widget build(BuildContext context) {
    final isOpen = tournament.isRegistrationOpen;
    final ctaColor = isOpen ? AppColors.dotaGold : AppColors.primaryNeon;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.surfaceHighlight.withValues(alpha: 0.35),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOpen ? AppColors.dotaGold : AppColors.textSecondary,
                  boxShadow: isOpen
                      ? [
                          BoxShadow(
                            color: AppColors.dotaGold.withValues(alpha: 0.65),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                isOpen ? 'Inscrições Abertas' : 'Inscrições Encerradas',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isOpen ? AppColors.dotaGoldLight : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isHovered
                  ? ctaColor.withValues(alpha: 0.22)
                  : ctaColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: ctaColor.withValues(alpha: isHovered ? 0.85 : 0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tournament.actionCtaLabel,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: isOpen ? AppColors.dotaGoldLight : Colors.white,
                  ),
                ),
                const SizedBox(width: 5),
                Icon(Icons.arrow_forward_rounded, size: 13, color: ctaColor),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

