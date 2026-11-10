import 'package:flutter/material.dart';
import '../../../../core/models/system_security_settings.dart';
import '../../../../core/services/system_security_service.dart';
import '../../../../core/theme/theme.dart';
import '../../models/draft_team_dto.dart';

/// Banner contextual de HUD para a Fase de Reservas / Draft Consolidado.
class DraftReservesHudBanner extends StatelessWidget {
  final DraftTeamDto reserveTeam;
  final bool isSubstituting;
  final bool isDraftCompleted;

  const DraftReservesHudBanner({
    super.key,
    required this.reserveTeam,
    required this.isSubstituting,
    required this.isDraftCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isSubstituting
            ? AppColors.primaryNeon.withValues(alpha: 0.08)
            : AppColors.dotaGold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSubstituting
              ? AppColors.primaryNeon.withValues(alpha: 0.50)
              : AppColors.dotaGold.withValues(alpha: 0.50),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSubstituting ? Icons.swap_horiz_rounded : Icons.shield_outlined,
            size: 18,
            color:
                isSubstituting ? AppColors.primaryNeon : AppColors.dotaGoldLight,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: Colors.white),
                children: isSubstituting
                    ? [
                        const TextSpan(
                          text: 'SUBSTITUIÇÃO EM ANDAMENTO: ',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryNeon,
                            letterSpacing: 0.5,
                          ),
                        ),
                        TextSpan(
                          text:
                              'Selecione o substituto no Bucket [+] à direita, ou clique em CANCELAR na equipe.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.90),
                          ),
                        ),
                      ]
                    : [
                        const TextSpan(
                          text: 'FASE DE RESERVAS: ',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.dotaGoldLight,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const TextSpan(text: 'Equipe selecionada: '),
                        TextSpan(
                          text: reserveTeam.name.toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.dotaGold,
                          ),
                        ),
                        TextSpan(
                          text: isDraftCompleted
                              ? ' (${reserveTeam.reserves.length}/2 Reservas) — Draft consolidado. Substituições e ajustes de reservas continuam liberados.'
                              : ' (${reserveTeam.reserves.length}/2 Reservas) — Selecione no Bucket [+] para adicionar reserva, ou clique em outra equipe.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner contextual de HUD para o Turno Atual do Snake Draft (Fase de Titulares).
class DraftSnakeTurnHudBanner extends StatelessWidget {
  final DraftTeamDto turnTeam;
  final bool isPausedForSubstitution;

  const DraftSnakeTurnHudBanner({
    super.key,
    required this.turnTeam,
    this.isPausedForSubstitution = false,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SystemSecuritySettings>(
      valueListenable: SystemSecurityService.instance.settingsNotifier,
      builder: (context, security, _) {
        if (security.isDraftPicksLocked) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryNeon.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primaryNeon.withValues(alpha: 0.45),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: AppColors.primaryNeon,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 12, color: Colors.white),
                      children: [
                        TextSpan(
                          text: 'ESCOLHAS DE DRAFT TRAVADAS: ',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryNeon,
                            letterSpacing: 0.5,
                          ),
                        ),
                        TextSpan(
                          text:
                              'A seleção de jogadores está temporariamente suspensa pela administração.',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (isPausedForSubstitution) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryNeon.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primaryNeon.withValues(alpha: 0.45),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.swap_horiz_rounded,
                  size: 18,
                  color: AppColors.primaryNeon,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 12, color: Colors.white),
                      children: [
                        TextSpan(
                          text: 'SUBSTITUIÇÃO EM ANDAMENTO: ',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryNeon,
                            letterSpacing: 0.5,
                          ),
                        ),
                        TextSpan(
                          text:
                              'Selecione o substituto no Bucket [+] à direita, ou clique em CANCELAR na equipe.',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.dotaGold.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.dotaGold.withValues(alpha: 0.45),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.sports_esports_rounded,
                size: 18,
                color: AppColors.dotaGold,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                    children: [
                      const TextSpan(
                        text: 'TURNO ATUAL DE ESCOLHA: ',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.dotaGold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      TextSpan(
                        text: turnTeam.name.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      TextSpan(
                        text: ' — Selecione o titular no Bucket [+] à direita.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Aba vertical ancorada no canto direito da tela para reabrir o Bucket de Jogadores.
class DraftCornerBucketOpener extends StatelessWidget {
  final int poolCount;
  final VoidCallback onTap;

  const DraftCornerBucketOpener({
    super.key,
    required this.poolCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          hoverColor: AppColors.dotaGold.withValues(alpha: 0.15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.dotaGold.withValues(alpha: 0.6),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.dotaGold.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.chevron_left_rounded,
                  size: 22,
                  color: AppColors.dotaGold,
                ),
                const SizedBox(height: 8),
                const Icon(
                  Icons.storage_rounded,
                  size: 16,
                  color: AppColors.dotaGold,
                ),
                const SizedBox(height: 8),
                RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    'BUCKET ($poolCount)',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.dotaGold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

