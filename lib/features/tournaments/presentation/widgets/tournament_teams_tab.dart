import 'package:flutter/material.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/theme/theme.dart';
import '../../../draft/models/draft_player_dto.dart';
import '../../../draft/models/draft_state_snapshot_dto.dart';
import '../../../draft/models/draft_team_dto.dart';
import '../../models/tournament_dto.dart';

/// Aba 2: Equipes & Vagas do Campeonato (SRP & Dumb UI).
/// Projeta os cards de cada equipe com estrutura oficial fixa de 7 vagas
/// (5 Titulares + 2 Reservas) em modo estritamente de visualização (Read-Only).
class TournamentTeamsTab extends StatelessWidget {
  final TournamentDto tournament;
  final DraftStateSnapshotDto? draftSnapshot;
  final bool canManage;

  const TournamentTeamsTab({
    super.key,
    required this.tournament,
    this.draftSnapshot,
    this.canManage = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final crossAxisCount =
        screenWidth < 720 ? 1 : (screenWidth < 1350 ? 2 : 4);
    final totalSlots = tournament.teamCount;
    final registered = tournament.teams;

    // Estrutura oficial fixa: 7 slots por equipe (5 titulares + 2 reservas)
    const double cardExtent = 390.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: 'EQUIPES PARTICIPANTES & VAGAS',
          countLabel: tournament.teamsProgressLabel,
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisExtent: cardExtent,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: totalSlots,
          itemBuilder: (context, index) {
            final hasTeam = index < registered.length;
            final teamDto = hasTeam ? registered[index] : null;

            // Busca os dados do elenco real sincronizados da sessão de draft
            DraftTeamDto? draftTeam;
            if (teamDto != null && draftSnapshot != null) {
              draftTeam = draftSnapshot!.teams.firstWhere(
                (t) =>
                    t.id == teamDto.id ||
                    t.name.toLowerCase() == teamDto.name.toLowerCase(),
                orElse: () => index < draftSnapshot!.teams.length
                    ? draftSnapshot!.teams[index]
                    : draftSnapshot!.teams.first,
              );
              if (draftTeam.id != teamDto.id &&
                  draftTeam.name.toLowerCase() != teamDto.name.toLowerCase()) {
                draftTeam = null;
              }
            }

            final teamName = teamDto?.name ?? 'Vaga #${index + 1} Disponível';

            return _buildTeamCard(
              context: context,
              slotNumber: index + 1,
              teamName: teamName,
              hasTeam: hasTeam,
              draftTeam: draftTeam,
            );
          },
        ),
      ],
    );
  }

  Widget _buildTeamCard({
    required BuildContext context,
    required int slotNumber,
    required String teamName,
    required bool hasTeam,
    required DraftTeamDto? draftTeam,
  }) {
    final starters = draftTeam?.starters ?? const [];
    final reserves = draftTeam?.reserves ?? const [];
    final captainId = draftTeam?.captainId;

    DraftPlayerDto? captain;
    final List<DraftPlayerDto> otherStarters = [];

    if (starters.isNotEmpty) {
      final foundCaptain = starters.firstWhere(
        (p) => p.id == captainId,
        orElse: () => starters.first,
      );
      captain = foundCaptain;
      for (final player in starters) {
        if (player.id != captain.id) {
          otherStarters.add(player);
        }
      }
    }

    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Cabeçalho Limpo da Equipe (Exibição Pura)
          Row(
            children: [
              // Avatar ou Ícone do Time
              if (hasTeam)
                AppAvatar(
                  name: teamName,
                  radius: 12,
                  backgroundColor: AppColors.canvasSurface,
                  borderColor: AppColors.dotaGold.withValues(alpha: 0.7),
                )
              else
                const Icon(
                  Icons.hourglass_empty_rounded,
                  size: 15,
                  color: AppColors.textSecondary,
                ),
              const SizedBox(width: 8),

              // Nome da Equipe Limitado e com Reticências
              Expanded(
                child: Text(
                  teamName.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12.8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 2. Slot 1: Capitão (com borda e divisão)
          _buildCaptainSlot(captain, hasTeam),

          const SizedBox(height: 5),

          // 3. Slots 2 a 5: Titulares
          for (int i = 0; i < 4; i++) ...[
            if (i > 0) const SizedBox(height: 5),
            if (i < otherStarters.length)
              _buildStarterFilledSlot(otherStarters[i], i + 2)
            else
              _buildStarterPlaceholderSlot(
                slotIndex: i + 2,
                hasTeam: hasTeam,
              ),
          ],

          // 4. Divisória e Slots 6 e 7: Reservas (Estrutura totalizando 7 vagas oficiais por time)
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                const Expanded(child: AppDivider.subtle()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'RESERVAS',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.feedbackInfo.withValues(alpha: 0.75),
                    ),
                  ),
                ),
                const Expanded(child: AppDivider.subtle()),
              ],
            ),
          ),
          for (int r = 0; r < 2; r++) ...[
            if (r > 0) const SizedBox(height: 5),
            if (r < reserves.length)
              _buildReserveFilledSlot(
                reserves[r],
                slotIndex: 6 + r,
              )
            else
              _buildReserveEmptySlot(
                slotIndex: 6 + r,
                hasTeam: hasTeam,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildCaptainSlot(DraftPlayerDto? captain, bool hasTeam) {
    if (captain == null) {
      return Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.5),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.shield_outlined,
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              hasTeam ? 'Capitão não definido' : 'Vaga Livre',
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 8),
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
          // Badge Oficial de Capitão
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
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
                Icon(Icons.star_rounded, size: 10, color: AppColors.dotaGold),
                SizedBox(width: 2.5),
                Text(
                  'CAPITÃO',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                    color: AppColors.dotaGold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),

          // Avatar do Capitão
          AppAvatar(
            imageUrl: captain.avatarUrl,
            name: captain.name,
            radius: 11,
          ),
          const SizedBox(width: 6),

          // Medalha de Rank
          if (captain.rankTier != null && captain.rankTier! > 0) ...[
            DotaRankMedal(
              rankTier: captain.rankTier.toString(),
              size: 19,
              showBadgeNumber: false,
            ),
            const SizedBox(width: 6),
          ],

          // Nome do Capitão
          Expanded(
            child: Text(
              captain.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.8,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Ícones de Roles Completos
          DotaRolesDisplay.fromStrings(
            rawRoles: captain.roles,
            preferredRoleKey: captain.preferredRole,
            boxWidth: 17.0,
            boxHeight: 17.0,
            iconSize: 11.5,
            spacing: 3.0,
            showBoxes: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStarterFilledSlot(DraftPlayerDto player, int slotIndex) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.canvasSurface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.6),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          // Indicador de Vaga
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.6),
                width: 0.6,
              ),
            ),
            child: Text(
              '#$slotIndex',
              style: const TextStyle(
                fontSize: 9.0,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 7),

          // Avatar
          AppAvatar(
            imageUrl: player.avatarUrl,
            name: player.name,
            radius: 11,
          ),
          const SizedBox(width: 6),

          // Medalha de Rank
          if (player.rankTier != null && player.rankTier! > 0) ...[
            DotaRankMedal(
              rankTier: player.rankTier.toString(),
              size: 19,
              showBadgeNumber: false,
            ),
            const SizedBox(width: 6),
          ],

          // Nome do Titular
          Expanded(
            child: Text(
              player.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.8,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Ícones de Roles Completos
          DotaRolesDisplay.fromStrings(
            rawRoles: player.roles,
            preferredRoleKey: player.preferredRole,
            boxWidth: 17.0,
            boxHeight: 17.0,
            iconSize: 11.5,
            spacing: 3.0,
            showBoxes: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStarterPlaceholderSlot({
    required int slotIndex,
    required bool hasTeam,
  }) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.35),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.4),
                width: 0.6,
              ),
            ),
            child: Text(
              '#$slotIndex',
              style: const TextStyle(
                fontSize: 9.0,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.person_outline_rounded,
            size: 14,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              hasTeam ? 'Vaga Titular #$slotIndex — Aguardando Draft...' : 'Vaga Livre',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary.withValues(
                  alpha: hasTeam ? 0.70 : 0.45,
                ),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReserveFilledSlot(DraftPlayerDto player, {required int slotIndex}) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.canvasSurface.withValues(alpha: 0.50),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.55),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          // Indicador de Vaga Reserva (#6 ou #7 em azul para identificação pura)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
            decoration: BoxDecoration(
              color: AppColors.feedbackInfo.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: AppColors.feedbackInfo.withValues(alpha: 0.5),
                width: 0.6,
              ),
            ),
            child: Text(
              '#$slotIndex',
              style: const TextStyle(
                fontSize: 9.0,
                fontWeight: FontWeight.w700,
                color: AppColors.feedbackInfo,
              ),
            ),
          ),
          const SizedBox(width: 7),

          // Avatar
          AppAvatar(
            imageUrl: player.avatarUrl,
            name: player.name,
            radius: 11,
          ),
          const SizedBox(width: 6),

          // Medalha de Rank
          if (player.rankTier != null && player.rankTier! > 0) ...[
            DotaRankMedal(
              rankTier: player.rankTier.toString(),
              size: 19,
              showBadgeNumber: false,
            ),
            const SizedBox(width: 6),
          ],

          // Nome do Reserva
          Expanded(
            child: Text(
              player.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.8,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Ícones de Roles Completos
          DotaRolesDisplay.fromStrings(
            rawRoles: player.roles,
            preferredRoleKey: player.preferredRole,
            boxWidth: 17.0,
            boxHeight: 17.0,
            iconSize: 11.5,
            spacing: 3.0,
            showBoxes: true,
          ),
        ],
      ),
    );
  }

  /// Slot de Reserva Vazio/Placeholder para totalizar 7 vagas fixas por time
  Widget _buildReserveEmptySlot({
    required int slotIndex,
    required bool hasTeam,
  }) {
    final reserveNumber = slotIndex - 5; // 1 para #6, 2 para #7
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.28),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.4),
                width: 0.6,
              ),
            ),
            child: Text(
              '#$slotIndex',
              style: TextStyle(
                fontSize: 9.0,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.shield_outlined,
            size: 14,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              hasTeam
                  ? 'Vaga Reserva #$reserveNumber — Sem reserva'
                  : 'Vaga Reserva #$reserveNumber Livre',
              style: TextStyle(
                fontSize: 10.8,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary.withValues(alpha: 0.60),
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
