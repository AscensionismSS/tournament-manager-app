import 'draft_player_dto.dart';
import 'draft_team_dto.dart';

/// Representação de um jogador já escolhido/alocado em uma equipe (Dumb UI / SRP).
class ChosenPlayerEntry {
  final DraftPlayerDto player;
  final DraftTeamDto team;
  final bool isCaptain;

  const ChosenPlayerEntry({
    required this.player,
    required this.team,
    required this.isCaptain,
  });

  String get teamBadgeLabel =>
      '${team.name.toUpperCase()}${isCaptain ? " (CAPITÃO)" : ""}';
}

