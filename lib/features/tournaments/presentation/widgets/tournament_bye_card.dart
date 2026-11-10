import 'package:flutter/material.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/theme/theme.dart';
import '../../models/tournament_team_dto.dart';

/// Card dedicado de folga (BYE) para equipes em rodadas ímpares da Fase de Grupos.
/// Segue o mesmo padrão visual, proporções e largura oficial do [TournamentSeriesCard]:
/// - Faixa superior com 'BYE' centralizado e status 'FOLGA' na direita
/// - Equipe em descanso centralizada no mesmo formato visual e espaçamento do card de partidas
/// - Altura dinâmica harmonizada com o formato da rodada (MD1 = 1 slot, MD2 = 2 slots, MD3 = 3 slots),
///   eliminando discrepâncias e mantendo alinhamento visual perfeito com as séries vizinhas.
class TournamentByeCard extends StatelessWidget {
  final TournamentTeamDto team;
  final int round;
  final bool isMobile;
  final double? customCardWidth;
  final int formatMaxGames;

  const TournamentByeCard({
    super.key,
    required this.team,
    required this.round,
    required this.isMobile,
    this.customCardWidth,
    this.formatMaxGames = 1,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = customCardWidth ??
        (isMobile ? (screenWidth - 24).clamp(340.0, 560.0) : 540.0);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: cardWidth,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.dotaGold.withValues(alpha: 0.35),
            width: 0.85,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Faixa Superior (Top Strip): Formato 'BYE' no centro e Status 'FOLGA' na direita
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
              decoration: BoxDecoration(
                color: AppColors.canvasSurface.withValues(alpha: 0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.45),
                    width: 0.8,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Spacer(),

                  // Centro: BYE
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.canvasSurface.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: AppColors.dotaGold.withValues(alpha: 0.6),
                          width: 0.8,
                        ),
                      ),
                      child: const Text(
                        'BYE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                          color: AppColors.dotaGoldLight,
                        ),
                      ),
                    ),
                  ),

                  // Direita: Status de Folga alinhado com o status das séries normais
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.canvasSurface.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppColors.dotaGold.withValues(alpha: 0.45),
                            width: 0.7,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.pause_circle_outline_rounded,
                              size: 11,
                              color: AppColors.dotaGoldLight,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'FOLGA',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                                color: AppColors.dotaGoldLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Linha da Equipe em Folga (Mesmo padding vertical 11px do card de séries)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppAvatar(
                    name: team.name,
                    radius: 17,
                    backgroundColor: AppColors.canvasSurface,
                    borderColor: AppColors.dotaGold.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      team.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.dotaGoldLight,
                        letterSpacing: 0.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Linha divisória sutil idêntica à do TournamentSeriesCard
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: AppDivider.subtle(),
            ),

            // 3. Área informativa harmonizada: slots com a mesma altura (36px) dos jogos da rodada
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _buildHarmonizedInfoSlots(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildHarmonizedInfoSlots() {
    final slots = <Widget>[];

    // Slot 1: Folga principal
    slots.add(
      Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.canvasSurface.withValues(alpha: 0.50),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.4),
            width: 0.7,
          ),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.pause_circle_outline_rounded,
              size: 14,
              color: AppColors.dotaGoldLight,
            ),
            SizedBox(width: 8),
            Text(
              'FOLGA NA RODADA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: AppColors.dotaGoldLight,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '— Descanso programado da chave de grupos',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // Slot 2 (Se rodada for MD2 ou superior)
    if (formatMaxGames >= 2) {
      slots.add(const SizedBox(height: 5));
      slots.add(
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.canvasSurface.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.3),
              width: 0.7,
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.shield_outlined,
                size: 13,
                color: AppColors.feedbackInfo,
              ),
              SizedBox(width: 8),
              Text(
                'PONTUAÇÃO MANTIDA',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: AppColors.feedbackInfo,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '— Sem alteração na tabela de classificação',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Slot 3 (Se rodada for MD3 ou superior)
    if (formatMaxGames >= 3) {
      slots.add(const SizedBox(height: 5));
      slots.add(
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.canvasSurface.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.25),
              width: 0.7,
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 13,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: 8),
              Text(
                'PRÓXIMA RODADA',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '— Equipe retorna aos confrontos no turno seguinte',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return slots;
  }
}
