import 'package:flutter/material.dart';
import '../../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../../core/theme/theme.dart';
import '../../../models/tournament_dto.dart';

/// Banner visual da página de detalhes do campeonato (Dumb UI).
/// Renderiza:
/// - Imagem de capa (com suporte a resolvedBannerUrl) e gradiente cinematográfico.
/// - Badges de Status, Formato e Trava de Resultados (se ativo).
/// - Título oficial do campeonato.
/// - Faixa de alerta de suspensão de envio de resultados (Result Submission Lock).
class TournamentHeaderBanner extends StatelessWidget {
  final TournamentDto tournament;
  final double height;

  const TournamentHeaderBanner({
    super.key,
    required this.tournament,
    this.height = 150.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Bloco do Banner
        SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Imagem ou Fallback
              if (tournament.hasBanner)
                Image.network(
                  tournament.resolvedBannerUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildFallbackBanner(),
                )
              else
                _buildFallbackBanner(),

              // Gradiente de Escurecimento Cinematográfico
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.35),
                      Colors.black.withValues(alpha: 0.70),
                      Colors.black.withValues(alpha: 0.95),
                    ],
                  ),
                ),
              ),

              // Conteúdo dentro do Banner: Status, Trava e Título
              Positioned(
                left: 20,
                right: 20,
                top: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Linha de Badges de Status
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        AppBadge(
                          label: tournament.status.label,
                          customColor: tournament.status.color,
                        ),
                        AppBadge(
                          label: tournament.formatLabel,
                          variant: AppBadgeVariant.neutral,
                        ),
                        if (tournament.isResultSubmissionLocked)
                          Tooltip(
                            message: tournament.resultLockReasonLabel,
                            child: const AppBadge(
                              label: 'RESULTADOS TRAVADOS',
                              variant: AppBadgeVariant.error,
                              icon: Icons.lock_clock_rounded,
                            ),
                          ),
                      ],
                    ),

                    // Título Limpo
                    Text(
                      tournament.name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Faixa Informativa Exclusiva quando o Torneio estiver com envio de resultados travado
        if (tournament.isResultSubmissionLocked)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.feedbackError.withValues(alpha: 0.10),
              border: Border(
                top: BorderSide(
                  color: AppColors.feedbackError.withValues(alpha: 0.35),
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lock_clock_rounded,
                  size: 16,
                  color: AppColors.feedbackError,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'ENVIO DE RESULTADOS SUSPENSO PELA ORGANIZAÇÃO: ${tournament.resultLockReasonLabel}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.feedbackError,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFallbackBanner() {
    return Container(
      color: AppColors.surfaceHighlight,
      child: Opacity(
        opacity: 0.1,
        child: Image.asset(
          'assets/images/company_logo.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
